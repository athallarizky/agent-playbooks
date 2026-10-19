#!/usr/bin/env bash
# Capture PushEvent evidence for an incident window and build a restore map.
# Usage:   capture-events.sh <since-ISO8601> [outdir]
# Example: capture-events.sh 2026-01-01T00:00:00Z /tmp/gh-ir
# Outputs (in outdir):
#   push_events.raw   created repo branch before-sha head-sha  (newest first)
#   restore_map.txt   repo|branch|original-before-sha          (EARLIEST event per ref
#                     — later events' "before" are attacker states in multi-pass attacks)
set -uo pipefail
. "$(dirname "$0")/lib-ioc.sh"

since="${1:?usage: capture-events.sh <since-ISO8601> [outdir]}"
outdir="${2:-$(mktemp -d)}"
mkdir -p "$outdir"

owner=$(gh api user --jq .login) || { echo "gh not authenticated" >&2; exit 1; }

gh api --paginate "users/$owner/events/public?per_page=100" \
  --jq '.[] | select(.type == "PushEvent") | "\(.created_at) \(.repo.name) \(.payload.ref | sub("refs/heads/"; "")) \(.payload.before) \(.payload.head)"' \
  | awk -v s="$since" '$1 >= s' > "$outdir/push_events.raw"

# Events arrive newest-first, so the LAST occurrence seen per repo|branch in a
# forward pass is the EARLIEST event — its "before" is the pre-attack state.
awk '{ k=$2"|"$3; m[k]=$4 } END { for (k in m) print k"|"m[k] }' \
  "$outdir/push_events.raw" > "$outdir/restore_map.txt"

echo "events captured : $(wc -l < "$outdir/push_events.raw" | tr -d ' ')"
echo "restore map refs: $(wc -l < "$outdir/restore_map.txt" | tr -d ' ')"
echo "artifacts in    : $outdir"
