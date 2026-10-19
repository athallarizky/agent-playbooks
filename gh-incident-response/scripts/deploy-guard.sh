#!/usr/bin/env bash
# Install guard/malware-guard.yml as .github/workflows/malware-guard.yml into
# repos via the contents API (one commit per repo). Covers private repos on
# the Free plan where rulesets are unavailable.
# Usage: deploy-guard.sh <repos-file>   (lines: "owner/repo"; default: all own non-fork)
# NOTE: the guard is layered defense, not a wall — see the workflow header.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
wf="$here/guard/malware-guard.yml"
[ -f "$wf" ] || { echo "workflow not found: $wf" >&2; exit 1; }

repos="${1:-}"
if [ -z "$repos" ]; then
  repos="$(mktemp)"
  gh api --paginate "user/repos?type=owner&per_page=100" --jq '.[] | select(.fork == false) | .full_name' > "$repos"
fi
b64="$(base64 < "$wf")"

ok=0; upd=0; fail=0
while read -r repo; do
  [ -z "$repo" ] && continue
  sha=$(gh api "repos/$repo/contents/.github/workflows/malware-guard.yml" --jq '.sha' 2>/dev/null)
  if [ -n "$sha" ]; then echo "EXISTS   $repo (skip — sudah terpasang)"; upd=$((upd+1)); continue; fi
  out=$(gh api -X PUT "repos/$repo/contents/.github/workflows/malware-guard.yml" \
    -f message="ci: add malware-guard workflow (security)" -f content="$b64" ${sha:+-f sha="$sha"} --jq '.commit.sha[0:8]' 2>&1)
  if [ $? -eq 0 ]; then echo "DEPLOYED $repo ($out)"; ok=$((ok+1))
  else echo "FAIL     $repo : $(echo "$out" | head -c 80)"; fail=$((fail+1)); fi
  sleep 0.3
done < "$repos"
echo
echo "deployed=$ok exists=$upd failed=$fail"
