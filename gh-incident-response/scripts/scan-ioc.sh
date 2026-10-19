#!/usr/bin/env bash
# Two-stage IOC scan across repo branches.
# Usage: scan-ioc.sh [targets-file]
#   targets-file: lines of "owner/repo branch" (covers orgs, non-default branches)
#   Without a file: builds targets from the authenticated user's own repos (default branches).
# Stage 1: recursive tree listing filtered by IOC_PATH_REGEX (fast).
# Stage 2: content marker checks only for hits, plus payload-font paths parsed
#          out of a malicious tasks.json. Verdict per target + summary.
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
  tree=$(gh api "repos/$repo/git/trees/$br?recursive=1" --jq '.tree[].path' 2>/dev/null)
  if [ -z "$tree" ]; then echo "ERR  $repo @$br (tree fetch failed)"; err=$((err+1)); continue; fi
  hits=$(echo "$tree" | grep -E "$IOC_PATH_REGEX" || true)
  if [ -z "$hits" ]; then echo "OK   $repo @$br"; clean=$((clean+1)); continue; fi
  verdict=""
  for p in $hits; do
    content=$(gh api "repos/$repo/contents/$p?ref=$br" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null) || content=""
    if printf '%s' "$content" | ioc_path_is_malicious "$p"; then verdict="$verdict MALICIOUS:$p"; fi
    # dynamically check payload assets referenced by a malicious tasks.json
    if printf '%s' "$content" | ioc_tasks_malicious 2>/dev/null; then
      for asset in $(printf '%s' "$content" | ioc_assets_from_tasks); do
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
