#!/usr/bin/env bash
# Fallback cleanup: marker-checked deletion of injected files via the contents API.
# Use for refs with no known pre-attack SHA. Creates one cleanup commit per file.
# Usage: clean-markers.sh <targets-file>   (lines: "owner/repo branch")
# Candidates are selected the same way scan-ioc.sh does — size-aware and
# NAME-AGNOSTIC (any small font file, any .vscode task/settings file, fonts
# READMEs) — and every deletion is gated on CONTENT markers, so a user's own
# legit tasks.json/settings.json/tiny custom font survives.
# Also strips injected .gitignore entries when present.
# Only run AFTER Gate 1 (credential revocation).
set -uo pipefail
. "$(dirname "$0")/lib-ioc.sh"

targets="${1:?usage: clean-markers.sh <targets-file>}"

get_content() {  # prints content; rc!=0 when fetch fails (rate limit etc)
  local raw; raw=$(gh api "repos/$1/contents/$2?ref=$3" --jq '.content // empty' 2>/dev/null)
  [ -n "$raw" ] || return 1
  printf '%s' "$raw" | base64 -d 2>/dev/null
}
tree_has()    { printf '%s\n' "$1" | awk -v p="$2" '$1 == p { found=1 } END { exit !found }'; }

while read -r repo br; do
  [ -z "$repo" ] && continue
  act=""
  tree=$(gh api "repos/$repo/git/trees/$br?recursive=1" --jq '.tree[] | select(.type=="blob") | "\(.path) \(.size)"' 2>/dev/null)
  # gh api prints error bodies to STDOUT — validate against captured JSON too
  if [ -z "$tree" ] || printf '%s' "$tree" | grep -q '^{"message"'; then
    echo "SKIP $repo @$br (tree fetch failed — deleted repo? rate limit?) — TIDAK dinilai bersih"; continue
  fi
  # candidates: stage-1 selection + payload assets referenced by tasks.json.
  # .gitignore is deliberately EXCLUDED from deletion — it is EDITED (bat lines
  # stripped) by the block below; deleting the whole file is collateral damage.
  cands=$(printf '%s\n' "$tree" | ioc_stage1_candidates | grep -vx '.gitignore')
  if tree_has "$tree" ".vscode/tasks.json"; then
    cands="$cands
$(get_content "$repo" ".vscode/tasks.json" "$br" | ioc_assets_from_tasks)"
  fi
  for p in $(printf '%s\n' "$cands" | sort -u | sed '/^$/d'); do
    tree_has "$tree" "$p" || continue   # path must exist in tree
    if ! content=$(get_content "$repo" "$p" "$br"); then
      echo "SKIP $repo @$br (content fetch gagal: $p) — TIDAK dinilai bersih"; continue
    fi
    printf '%s' "$content" | ioc_path_is_malicious "$p" || continue
    blob=$(gh api "repos/$repo/contents/$p?ref=$br" --jq '.sha' 2>/dev/null)
    [ -n "$blob" ] || continue
    gh api -X DELETE "repos/$repo/contents/$p" \
      -f message="chore: remove injected malware files (security cleanup)" \
      -f sha="$blob" -f branch="$br" >/dev/null 2>&1 && act="$act del:$p"
  done
  # strip injected .gitignore line(s) — stage-2 ignore entries (campaign
  # fingerprint: config.bat / *.bat so the dropped file never shows in git status)
  if tree_has "$tree" ".gitignore"; then
    sha=$(gh api "repos/$repo/contents/.gitignore?ref=$br" --jq '.sha' 2>/dev/null)
    cont=$(get_content "$repo" ".gitignore" "$br")
    if printf '%s' "$cont" | grep -qxE '\*\.bat|[A-Za-z0-9_.-]+\.bat'; then
      new=$(printf '%s' "$cont" | grep -vxE '\*\.bat|[A-Za-z0-9_.-]+\.bat')
      printf '%s' "$new" | gh api -X PUT "repos/$repo/contents/.gitignore" \
        -f message="chore: drop injected gitignore entry" \
        -f sha="$sha" -f branch="$br" -f content="$(base64 <<< "$new")" --jq '.commit.sha' >/dev/null 2>&1 \
        && act="$act fix:.gitignore"
    fi
  fi
  echo "$repo @$br ->${act:- no malicious markers}"
done < "$targets"
