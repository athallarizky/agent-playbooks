#!/usr/bin/env bash
# Protect repos against unsigned force-push malware: create an ACTIVE ruleset
# "malware-guard" per repo — required_signatures + non_fast_forward — on ALL
# branches. Unsigned rewritten commits (attacker lookalikes) get REJECTED.
# Usage: protect-repos.sh [repos-file]   (lines: "owner/repo"; default: all own repos)
# Notes:
#   - Works on public repos on any plan; PRIVATE repos need Pro/Team —
#     failures are reported, not fatal.
#   - Applies to the repo owner too: web-UI edits (unsigned commits) and
#     force pushes will be rejected until bypassed in the UI.
#   - Run AFTER purge-history.sh (rewritten history has no signatures).
set -uo pipefail

repos="${1:-}"
if [ -z "$repos" ]; then
  repos="$(mktemp)"
  gh api --paginate "user/repos?type=owner&per_page=100" --jq '.[] | select(.fork == false) | .full_name' > "$repos"
fi

ok=0; fail=0
while read -r repo; do
  [ -z "$repo" ] && continue
  body=$(mktemp)
  cat > "$body" <<'JSON'
{
  "name": "malware-guard",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["**"], "exclude": [] } },
  "rules": [ { "type": "required_signatures" }, { "type": "non_fast_forward" } ]
}
JSON
  out=$(gh api -X POST "repos/$repo/rulesets" --input "$body" --jq '.id' 2>&1)
  if [ $? -eq 0 ]; then echo "PROTECTED $repo (ruleset id $out)"; ok=$((ok+1))
  else echo "FAIL      $repo : $(echo "$out" | head -c 90)"; fail=$((fail+1)); fi
  rm -f "$body"
done < "$repos"
echo
echo "protected=$ok failed=$fail (private repos on Free plan cannot have rulesets)"
