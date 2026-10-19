#!/usr/bin/env bash
# Temporarily disable/enable the incident ruleset on a repo so that
# incident-response writes (unsigned API cleanup commits, filter-repo
# force-pushes) can pass. Fetches the CURRENT ruleset body, flips ONLY the
# enforcement field, and PUTs it back unchanged — no rules are dropped.
# ALWAYS call with "on" when done.
# Usage: ruleset-lift.sh <owner/repo> <off|on|status>
set -uo pipefail
RULESET_NAME="${RULESET_NAME:-malware-guard}"

repo="${1:?usage: ruleset-lift.sh <owner/repo> <off|on|status>}"
mode="${2:-status}"

id=$(gh api "repos/$repo/rulesets" --jq ".[] | select(.name == \"$RULESET_NAME\") | .id" 2>/dev/null | head -1)
if ! printf '%s' "$id" | grep -qE '^[0-9]+$'; then
  echo "$repo: ruleset tidak tersedia (private/free-plan/archived) — lanjut tanpa lift"
  exit 0
fi

case "$mode" in
  status)
    gh api "repos/$repo/rulesets/$id" --jq '"$repo: enforcement=\(.enforcement) id=\(.id)"' 2>/dev/null || echo "$repo: gagal baca";;
  off|on)
    want=$([ "$mode" = off ] && echo disabled || echo active)
    gh api "repos/$repo/rulesets/$id" --jq ".enforcement = \"$want\"" 2>/dev/null \
      | gh api -X PUT "repos/$repo/rulesets/$id" --input - --jq '.enforcement' 2>/dev/null \
      && echo "$repo: ruleset #$id → $want" || echo "$repo: GAGAL (cek admin rights)";;
  *) echo "mode harus off|on|status"; exit 1;;
esac
