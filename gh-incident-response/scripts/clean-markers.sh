#!/usr/bin/env bash
# Fallback cleanup: marker-checked deletion of injected files via the contents API.
# Use for refs with no known pre-attack SHA. Creates one cleanup commit per file.
# Usage: clean-markers.sh <targets-file>   (lines: "owner/repo branch")
# SAFETY: deletes only files whose CONTENT matches malicious markers — a user's
# own legit tasks.json/settings.json survive. Also strips injected .gitignore
# entries (any line that looks like a stage-2 name, e.g. *.bat added by the
# attacker) only when an exact suspicious line is present.
# Only run AFTER Gate 1 (credential revocation).
set -uo pipefail
. "$(dirname "$0")/lib-ioc.sh"

targets="${1:?usage: clean-markers.sh <targets-file>}"

get_content() { gh api "repos/$1/contents/$2?ref=$3" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null; }

while read -r repo br; do
  [ -z "$repo" ] && continue
  act=""
  tree=$(gh api "repos/$repo/git/trees/$br?recursive=1" --jq '.tree[].path' 2>/dev/null)
  [ -z "$tree" ] && { echo "SKIP $repo @$br (tree fetch failed)"; continue; }
  # candidate paths: stage-1 regex hits + payload assets referenced by malicious tasks
  cands=$(echo "$tree" | grep -E "$IOC_PATH_REGEX" || true)
  for p in $(echo "$tree" | grep -E '^\.vscode/tasks\.json$' || true); do
    cands="$cands
$(get_content "$repo" "$p" "$br" | ioc_assets_from_tasks)"
  done
  for p in $(echo "$cands" | sort -u | sed '/^$/d'); do
    echo "$tree" | grep -qx "$p" || continue   # path must exist in tree
    content=$(get_content "$repo" "$p" "$br")
    printf '%s' "$content" | ioc_path_is_malicious "$p" || continue
    blob=$(gh api "repos/$repo/contents/$p?ref=$br" --jq '.sha' 2>/dev/null)
    [ -n "$blob" ] || continue
    gh api -X DELETE "repos/$repo/contents/$p" \
      -f message="chore: remove injected malware files (security cleanup)" \
      -f sha="$blob" -f branch="$br" >/dev/null 2>&1 && act="$act del:$p"
  done
  # strip injected .gitignore line(s) — known stage-2 names
  if echo "$tree" | grep -qx '.gitignore'; then
    sha=$(gh api "repos/$repo/contents/.gitignore?ref=$br" --jq '.sha' 2>/dev/null)
    cont=$(get_content "$repo" ".gitignore" "$br")
    if echo "$cont" | grep -qx 'config.bat'; then
      new=$(echo "$cont" | grep -vx 'config.bat')
      printf '%s' "$new" | gh api -X PUT "repos/$repo/contents/.gitignore" \
        -f message="chore: drop injected gitignore entry" \
        -f sha="$sha" -f branch="$br" -f content="$(base64 <<< "$new")" --jq '.commit.sha' >/dev/null 2>&1 \
        && act="$act fix:.gitignore"
    fi
  fi
  echo "$repo @$br ->${act:- no malicious markers}"
done < "$targets"
