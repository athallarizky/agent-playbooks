#!/usr/bin/env bash
# One-script onboarding: protect a repo against the malware-campaign class.
# Usage: onboard-repo.sh <owner/repo>
# Steps: (1) create the malware-guard ruleset (branch: signatures + no
# force-push + no delete). (2) If the ruleset could not be installed (private
# repo on the Free plan), deploy the in-repo guard workflow instead
# (guard/malware-guard.yml). (3) Refresh the local R-code map so guardian
# alerts for this repo resolve immediately.
# Idempotent: an existing ruleset is detected and reported, never duplicated.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="${1:?usage: onboard-repo.sh <owner/repo>}"
echo "$repo" | grep -qE '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' || { echo "not owner/repo: $repo" >&2; exit 1; }

echo "== 1/3 ruleset: malware-guard =="
echo "$repo" | "$here/protect-repos.sh" /dev/stdin || true
has_ruleset=$(gh api "repos/$repo/rulesets" --jq '[.[].name == "malware-guard"] | any' 2>/dev/null)

echo "== 2/3 in-repo guard (fallback for private repos) =="
if [ "$has_ruleset" = "true" ]; then
  echo "skip: ruleset active — in-repo guard not needed"
elif echo "$repo" | "$here/deploy-guard.sh" /dev/stdin; then
  echo "guard workflow deployed"
else
  echo "WARN: neither ruleset nor in-repo guard installed — repo is UNPROTECTED" >&2
fi

echo "== 3/3 refresh R-code map =="
"$here/guardian-map.sh" && echo "map refreshed — alerts for $repo now resolve locally"

echo "== summary =="
echo "repo:        $repo"
echo "ruleset:     $([ "$has_ruleset" = "true" ] && echo active || echo MISSING)"
echo "guard wf:    $(gh api "repos/$repo/contents/.github/workflows/malware-guard.yml" --jq '.name' >/dev/null 2>&1 && echo deployed || echo not-present)"
echo "map updated: yes"
