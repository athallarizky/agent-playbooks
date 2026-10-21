#!/usr/bin/env bash
# Generate (or grep) the local code<->repo map for guardian alerts.
# Guardian masks repo names as R-<8hex> = first 8 hex of sha256(full_name+SALT).
# The SALT lives only in the GUARD_SALT repo secret and your local salt file —
# never commit the salt or the map.
#
# Usage:
#   guardian-map.sh                  # regenerate ~/.guardian-map.txt
#   guardian-map.sh -g R-a3f19c2b    # resolve one code (grep)
# Env: SALT_FILE (default ~/.guardian-salt), ORGS (default "The-Aetheris")
set -uo pipefail
SALT_FILE="${SALT_FILE:-$HOME/.guardian-salt}"
ORGS="${ORGS:-The-Aetheris}"
MAP="${MAP:-$HOME/.guardian-map.txt}"

[ -f "$SALT_FILE" ] || { echo "salt file tidak ada: $SALT_FILE (buat: openssl rand -hex 16 > $SALT_FILE; chmod 600)" >&2; exit 1; }
salt=$(cat "$SALT_FILE")

code_of() { printf '%s%s' "$1" "$salt" | shasum -a 256 | cut -c1-8; }

if [ "${1:-}" = "-g" ]; then
  grep -i "${2:?kode?}" "$MAP" || echo "kode tidak dikenal — jalankan ulang guardian-map.sh (repo baru?)"
  exit 0
fi

{
  gh api --paginate "user/repos?type=owner&per_page=100" --jq '.[] | select(.fork == false) | .full_name' 2>/dev/null
  for org in $ORGS; do
    gh api --paginate "orgs/$org/repos?per_page=100" --jq '.[].full_name' 2>/dev/null
  done
} | sort -u | while read -r repo; do
  [ -z "$repo" ] && continue
  printf 'R-%s %s\n' "$(code_of "$repo")" "$repo"
done > "$MAP"
chmod 600 "$MAP"
echo "map diperbarui: $MAP ($(wc -l < "$MAP" | tr -d ' ') repo)"
echo "contoh 3 baris:"; head -3 "$MAP"
