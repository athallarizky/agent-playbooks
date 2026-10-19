#!/usr/bin/env bash
# Read-only audit: which public repos are NOT portfolio material?
# Usage: audit-visibility.sh [owner] [--keep-years N]
#   owner:      defaults to the authenticated user
#   keep-years: repos created within this window default to KEEP (default 3)
# Buckets (TSV): PRIVATE_STRONG / PRIVATE_REVIEW / KEEP / FORK + summary.
# Classifies by created_at + name/description markers — NEVER by pushed_at,
# which is unreliable after incident force-restores. Changes nothing.
set -uo pipefail

owner=""
keepyears=3
while [ $# -gt 0 ]; do
  case "$1" in
    --keep-years) keepyears="${2:?}"; shift 2 ;;
    -*) echo "unknown flag: $1" >&2; exit 1 ;;
    *) owner="$1"; shift ;;
  esac
done
[ -z "$owner" ] && owner="$(gh api user --jq .login)"

# Marker sets — extend these, don't fork the logic.
# Strong = clear archive/college material. Weak = learning/experiment signals.
strong_re='tugas[ _-]?besar|tubes|praktikum|kuliah|tugas[ _-]?akhir|oprec|arsip|archiv|laborator|coursework|homework|assignment'
weak_re='learn|sandbox|experiment|codesandbox|practice|exercise|tutorial|playground|starter|boilerplate|template|demo\b'

cutoff=$(( $(date +%Y) - keepyears ))

gh repo list "$owner" --visibility public --limit 300 \
  --json name,isFork,description,createdAt,primaryLanguage,stargazerCount \
  --jq '.[] | select(.isFork == false) | [.name, .createdAt[0:4], (.stargazerCount|tostring), (.primaryLanguage.name // "-"), (.description // "")] | @tsv' \
| while IFS=$'\t' read -r name year stars lang desc; do
    [ -z "$name" ] && continue
    lc=$(printf '%s | %s' "$name" "$desc" | tr '[:upper:]' '[:lower:]')
    if   echo "$lc" | grep -Eq "$strong_re"; then
      bucket=PRIVATE_STRONG; reason="strong marker"
    elif echo "$lc" | grep -Eq "$weak_re" && [ "$year" -le "$cutoff" ]; then
      bucket=PRIVATE_REVIEW; reason="learning/experiment marker, pre-$((cutoff+1))"
    elif [ "$year" -le "$cutoff" ] && [ "$stars" -eq 0 ] && [ -z "$(echo "$desc" | tr -d '[:space:]')" ]; then
      bucket=PRIVATE_REVIEW; reason="old, undescribed, zero stars"
    else
      bucket=KEEP; reason="created $year (cutoff $cutoff)"
    fi
    warn=""
    [ "$bucket" != "KEEP" ] && [ "$stars" -gt 0 ] && warn="  ⚠ ${stars} stars lost permanently"
    printf '%s\t%s\t%s\t%s\t%s\t%s%s\n' "$bucket" "$name" "$year" "$stars" "$lang" "$reason" "$warn"
  done | sort -t$'\t' -k1,1 -k3,3

forks=$(gh repo list "$owner" --visibility public --limit 300 --json name,isFork --jq '[.[] | select(.isFork)] | length')
echo "---"
echo "FORK           $forks repo — forks of public repos CANNOT be made private (archive / delete / detach instead)"
