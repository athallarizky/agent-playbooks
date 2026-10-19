#!/usr/bin/env bash
# Surgically remove build-config riders: walk the file's commit history on the
# branch (newest→oldest), find the most recent version whose content does NOT
# match the rider markers, and PUT that clean version back. Never deletes the
# whole file — the legitimate config lives in the same file.
# CAUTION: if the file was legitimately edited AFTER infection, this reverts
# those edits too — review the history count printed per file.
# Usage: restore-rider.sh <targets-file>   (lines: "owner/repo branch path")
set -uo pipefail
. "$(dirname "$0")/lib-ioc.sh"

targets="${1:?usage: restore-rider.sh <targets-file> (repo branch path)}"

while read -r repo br path; do
  [ -z "$repo" ] && continue
  # newest→oldest commits touching the file
  hist=$(gh api "repos/$repo/commits?path=$path&ref=$br&per_page=30" --jq '.[].sha' 2>/dev/null)
  [ -z "$hist" ] && { echo "SKIP $repo@$br $path (no history)"; continue; }
  n=$(printf '%s\n' "$hist" | wc -l | tr -d ' ')
  clean=""
  for sha in $hist; do
    c=$(gh api "repos/$repo/contents/$path?ref=$sha" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null)
    [ -z "$c" ] && continue
    if ! printf '%s' "$c" | ioc_path_is_malicious "$path"; then clean="$c"; cleanfrom="$sha"; break; fi
  done
  if [ -z "$clean" ]; then echo "WARN $repo@$br $path (tidak ditemukan versi bersih dalam 30 commit — strip manual)"; continue; fi
  blob=$(gh api "repos/$repo/contents/$path?ref=$br" --jq '.sha' 2>/dev/null)
  printf '%s' "$clean" | gh api -X PUT "repos/$repo/contents/$path" \
    -f message="fix: restore clean config (strip injected rider, security)" \
    -f sha="$blob" -f branch="$br" -f content="$(base64 <<< "$clean")" --jq '.commit.sha' >/dev/null 2>&1 \
    && echo "RESTORED $repo@$br $path (versi bersih dari ${cleanfrom:0:8}; $n commit riwayat)" \
    || echo "FAIL    $repo@$br $path (ruleset? lift dulu)"
done < "$targets"
