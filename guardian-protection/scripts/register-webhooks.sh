#!/usr/bin/env bash
# Register the guardian-webhook push webhook on repos (idempotent — skips repos
# already pointing at the worker). Reads the HMAC secret from the file wrangler
# also uses, so the local copy and the Worker never drift.
# Usage: register-webhooks.sh [repos-file]   (lines: owner/repo; default: all
#        own non-fork non-archived repos — private AND public)
set -uo pipefail
URL="${GUARDIAN_WEBHOOK_URL:-https://guardian-webhook.athallarizk-a8c.workers.dev}"
SECRET_FILE="${SECRET_FILE:-$HOME/.guardian-webhook-secret}"
[ -f "$SECRET_FILE" ] || { echo "secret file hilang: $SECRET_FILE" >&2; exit 1; }
secret=$(cat "$SECRET_FILE")

repos="${1:-}"
if [ -z "$repos" ]; then
  repos="$(mktemp)"
  gh api --paginate "user/repos?type=owner&per_page=100" \
    --jq '.[] | select(.fork == false and .archived == false) | .full_name' > "$repos" 2>/dev/null
fi

ok=0; skip=0; fail=0
while read -r repo; do
  [ -z "$repo" ] && continue
  # already registered?
  if gh api "repos/$repo/hooks" --jq '.[].config.url' 2>/dev/null | grep -qF "$URL"; then
    skip=$((skip+1)); continue
  fi
  out=$(gh api -X POST "repos/$repo/hooks" \
    -f 'config[url]'="$URL" -f 'config[content_type]'=json -f 'config[secret]'="$secret" \
    -f 'config[insecure_ssl]'=0 -F active=true \
    -f 'events[]=push' --jq '.id' 2>&1)
  if printf '%s' "$out" | grep -qE '^[0-9]+$'; then ok=$((ok+1));
  else echo "FAIL $repo: $(printf '%s' "$out" | head -c 90)"; fail=$((fail+1)); fi
  sleep 0.3
done < "$repos"
echo "registered=$ok sudah-ada=$skip gagal=$fail (URL: $URL)"
