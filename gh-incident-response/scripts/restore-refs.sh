#!/usr/bin/env bash
# Force-restore branch refs to pre-attack SHAs via the Git Data API (no clone).
# Usage: restore-refs.sh <restore-map> [failed-out]
#   restore-map: lines of "owner/repo|branch|full-sha" (as produced by capture-events.sh)
# Restored poisoned commits become unreachable -> never fetched by git clone again.
# Only run AFTER credential revocation (Gate 1) — otherwise the attacker re-poisons.
set -uo pipefail

mapfile="${1:?usage: restore-refs.sh <restore-map> [failed-out]}"
failed="${2:-restore-failed.txt}"
: > "$failed"

ok=0; fail=0
while IFS='|' read -r repo br sha; do
  [ -z "$repo" ] && continue
  out=$(gh api -X PATCH "repos/$repo/git/refs/heads/$br" -f sha="$sha" -F force=true --jq '.object.sha[0:8]' 2>&1)
  if [ $? -eq 0 ]; then
    echo "RESTORED $repo @$br -> $out"; ok=$((ok+1))
  else
    echo "FAIL     $repo @$br : $(echo "$out" | head -c 100)"
    echo "$repo|$br|$sha" >> "$failed"; fail=$((fail+1))
  fi
done < "$mapfile"

echo
echo "restored=$ok failed=$fail (failures saved to $failed — retry or use clean-markers.sh fallback)"
