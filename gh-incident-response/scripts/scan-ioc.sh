#!/usr/bin/env bash
# Two-stage IOC scan across repo branches — size-aware, NAME-AGNOSTIC.
# Usage: scan-ioc.sh [targets-file]
#   targets-file: lines of "owner/repo branch" (covers orgs, non-default branches)
#   Without a file: builds targets from the authenticated user's own repos.
# Stage 1 (one tree API call per ref, zero extra requests): flag .vscode
#   task/settings files, fonts-dir READMEs, and ANY font file smaller than
#   FONT_SUSPECT_MAX — blob sizes come free in the tree listing, so this
#   catches renamed/unknown payload names without fetching every font.
# Stage 2 (only for candidates): content marker checks, plus payload assets
#   parsed out of a malicious tasks.json. Verdict per target + summary.
set -uo pipefail
. "$(dirname "$0")/lib-ioc.sh"

targets="${1:-}"
if [ -z "$targets" ]; then
  targets="$(mktemp)"
  gh api --paginate "user/repos?type=owner&per_page=100" --jq '.[] | "\(.full_name) \(.default_branch)"' > "$targets"
fi

clean=0; bad=0; err=0
while read -r repo br; do
  [ -z "$repo" ] && continue
  tree=$(gh api "repos/$repo/git/trees/$br?recursive=1" --jq '.tree[] | select(.type=="blob") | "\(.path) \(.size)"' 2>/dev/null)
  if [ -z "$tree" ]; then echo "ERR  $repo @$br (tree fetch failed)"; err=$((err+1)); continue; fi
  hits=$(printf '%s\n' "$tree" | ioc_stage1_candidates | sort -u)
  if [ -z "$hits" ]; then echo "OK   $repo @$br"; clean=$((clean+1)); continue; fi
  verdict=""
  for p in $hits; do
    content=$(gh api "repos/$repo/contents/$p?ref=$br" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null) || content=""
    if printf '%s' "$content" | ioc_path_is_malicious "$p"; then verdict="$verdict MALICIOUS:$p"; fi
    # ALWAYS follow files referenced by a tasks.json command — even when the
    # task looks benign — and content-check each referenced asset
    if [ "${p##*/}" = "tasks.json" ] && [ -n "$content" ]; then
      for asset in $(printf '%s' "$content" | ioc_assets_from_tasks); do
        printf '%s\n' "$tree" | awk -v a="$asset" '$1 == a' | grep -q . || continue
        acontent=$(gh api "repos/$repo/contents/$asset?ref=$br" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null) || acontent=""
        if printf '%s' "$acontent" | ioc_font_malicious 2>/dev/null; then verdict="$verdict PAYLOAD:$asset"; fi
      done
    fi
  done
  if [ -n "$verdict" ]; then echo "BAD  $repo @$br ->$verdict"; bad=$((bad+1)); else echo "OK   $repo @$br"; clean=$((clean+1)); fi
done < "$targets"

echo
echo "VERDICT: clean=$clean malicious=$bad error=$err"
[ "$bad" -eq 0 ] && [ "$err" -eq 0 ]
