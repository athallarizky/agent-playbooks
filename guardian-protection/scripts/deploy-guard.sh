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

ok=0; upd=0; same=0; fail=0
while read -r repo; do
  [ -z "$repo" ] && continue
  # NOTE: on HTTP errors gh api prints the error JSON to STDOUT — test the
  # exit status, never the emptiness of captured output.
  sha=""; cur=""
  if cur=$(gh api "repos/$repo/contents/.github/workflows/malware-guard.yml" --jq '.content' 2>/dev/null); then
    sha=$(gh api "repos/$repo/contents/.github/workflows/malware-guard.yml" --jq '.sha' 2>/dev/null)
    # content compare (strip newlines from base64 wrapping) — identical → skip
    if [ "$(printf '%s' "$cur" | tr -d '\n')" = "$(printf '%s' "$b64" | tr -d '\n')" ]; then
      echo "SAME     $repo (already current)"; same=$((same+1)); continue
    fi
  fi
  out=$(gh api -X PUT "repos/$repo/contents/.github/workflows/malware-guard.yml" \
    -f message="ci: update malware-guard workflow (v3: oksh loader, entry-point, whole-tree detection)" \
    -f content="$b64" ${sha:+-f sha="$sha"} --jq '.commit.sha[0:8]' 2>&1)
  if [ $? -eq 0 ]; then
    if [ -n "$sha" ]; then echo "UPDATED $repo ($out)"; upd=$((upd+1))
    else echo "DEPLOYED $repo ($out)"; ok=$((ok+1)); fi
  else echo "FAIL     $repo : $(echo "$out" | head -c 80)"; fail=$((fail+1)); fi
  sleep 0.3
done < "$repos"
echo
echo "deployed=$ok updated=$upd same=$same failed=$fail"
