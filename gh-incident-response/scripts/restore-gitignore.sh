#!/usr/bin/env bash
# Restore .gitignore files that were accidentally DELETED by an early version
# of clean-markers.sh (it removed the whole file instead of stripping the
# injected bat lines). Walks each target branch; if .gitignore is missing but
# existed before the cleanup commit, recreates it from the parent commit with
# the injected lines stripped.
# Usage: restore-gitignore.sh <targets-file>   (lines: "owner/repo branch")
set -uo pipefail

targets="${1:?usage: restore-gitignore.sh <targets-file>}"
seen=""
while read -r repo br; do
  [ -z "$repo" ] && continue
  key="$repo|$br"
  case " $seen " in *" $key "*) continue ;; esac
  seen="$seen $key"
  if gh api "repos/$repo/contents/.gitignore?ref=$br" >/dev/null 2>&1; then
    continue   # still there — nothing to restore
  fi
  # latest commit that touched .gitignore on this branch = the deleting commit
  del=$(gh api "repos/$repo/commits?path=.gitignore&ref=$br&per_page=1" --jq '.[0].sha' 2>/dev/null)
  [ -n "$del" ] || { echo "SKIP $repo@$br (no .gitignore history)"; continue; }
  parent=$(gh api "repos/$repo/commits/$del" --jq '.parents[0].sha' 2>/dev/null)
  [ -n "$parent" ] || { echo "SKIP $repo@$br (initial commit)"; continue; }
  content=$(gh api "repos/$repo/contents/.gitignore?ref=$parent" --jq '.content' 2>/dev/null)
  [ -n "$content" ] || { echo "SKIP $repo@$br (parent has no .gitignore — fully injected file, deletion OK)"; continue; }
  restored=$(printf '%s' "$content" | base64 -d 2>/dev/null | grep -vxE '\*\.bat|[A-Za-z0-9_.-]+\.bat')
  printf '%s' "$restored" | gh api -X PUT "repos/$repo/contents/.gitignore" \
    -f message="fix: restore .gitignore (cleanup collateral)" \
    -f branch="$br" -f content="$(base64 <<< "$restored")" --jq '.commit.sha[0:8]' >/dev/null 2>&1 \
    && echo "RESTORED $repo@$br (.gitignore dari parent, baris bat dibuang)" \
    || echo "FAIL    $repo@$br (ruleset? lift dulu)"
done < "$targets"
