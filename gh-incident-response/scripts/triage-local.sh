#!/usr/bin/env bash
# Read-only local machine triage for gh-incident-response.
# Usage: triage-local.sh [since]      e.g. triage-local.sh "2026-10-19 22:15"
#   [since] = date(/time) string for the incident window; limits .git/persistence
#             mtime filters. Fake-font and .vscode scans always run in full.
# Sections: 1) file footprint  2) suspicious processes  3) network exposure
#           4) persistence & credential exposure
# READ-ONLY by design: inspects and reports. Never kills, edits, or deletes.
set -uo pipefail
. "$(dirname "$0")/lib-ioc.sh"

SINCE="${1:-}"
NOT_LIB='*/Library/*|*/.Trash/*|*/node_modules/*'

echo "===== 1. FILE FOOTPRINT ====="
echo "--- .vscode/tasks.json + settings.json (marker-checked; user's own files survive)"
find "$HOME" \( -path "$HOME/Library" -o -path "$HOME/.Trash" \) -prune -o \
  -type f \( -name tasks.json -o -name settings.json \) -path '*/.vscode/*' -print 2>/dev/null \
| while read -r f; do
    case "$f" in
      *tasks.json)   printf '%s' "$(cat "$f" 2>/dev/null)" | ioc_tasks_malicious 2>/dev/null \
                       && echo "MALICIOUS tasks.json : $f" ;;
      *settings.json) printf '%s' "$(cat "$f" 2>/dev/null)" | ioc_settings_malicious 2>/dev/null \
                       && echo "MALICIOUS settings.json: $f" ;;
    esac
  done
echo "(no MALICIOUS lines above = clean)"

echo "--- fake fonts (font files whose content is TEXT = payload)"
find "$HOME" \( -path "$HOME/Library" -o -path "$HOME/.Trash" -o -path '*/node_modules' \) -prune -o \
  -type f \( -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' \) -print 2>/dev/null \
| while read -r f; do
    if file "$f" | grep -qiE 'text|ascii|script'; then
      if cat "$f" 2>/dev/null | ioc_font_malicious 2>/dev/null; then echo "PAYLOAD FONT: $f"; else echo "odd text font (review): $f"; fi
    fi
  done
echo "(no PAYLOAD FONT lines above = clean)"

if [ -n "$SINCE" ]; then
  echo "--- .git dirs touched since $SINCE (pull/clone during window?)"
  find "$HOME" -maxdepth 6 \( -path "$HOME/Library" -o -path "$HOME/.Trash" \) -prune -o \
    -name .git -type d -newermt "$SINCE" -print 2>/dev/null
  echo "(empty = nothing synced during the window)"
fi

echo
echo "===== 2. SUSPICIOUS PROCESSES ====="
ps axo pid,ppid,lstart,command 2>/dev/null > /tmp/ghir_ps.$$ || ps axo pid,ppid,args > /tmp/ghir_ps.$$
echo "--- interpreter processes whose path/args point at temp, downloads, caches, repos, or FONT files"
grep -iE '(node|python|perl|ruby|osascript|deno|bun) ' /tmp/ghir_ps.$$ \
  | grep -vE 'grep -iE' \
  | grep -E "$TMPDIR|/tmp/|/var/folders|$HOME/Downloads|$HOME/.npm|$HOME/.cache|$HOME/development|\.(woff2?|ttf|otf)" \
  || echo "(none — no interpreter running from suspicious locations)"
echo
echo "--- ANY process whose argument is a font file = CONFIRMED payload execution"
grep -iE '\.(woff2?|ttf|otf|eot)' /tmp/ghir_ps.$$ | grep -v grep || echo "(none — no font file being executed)"
echo
echo "--- all node/python processes for manual review (top 30 by start time)"
grep -iE '(/| )(node|python3?|perl|ruby|osascript)( |$)' /tmp/ghir_ps.$$ | grep -v grep | head -30
rm -f /tmp/ghir_ps.$$

echo
echo "===== 3. NETWORK EXPOSURE ====="
if command -v lsof >/dev/null 2>&1; then
  echo "--- LISTEN sockets (unexpected new listener?)"
  lsof -nP -i 2>/dev/null | awk '$NF=="(LISTEN)"' | head -25
  echo "--- ESTABLISHED outbound grouped by foreign address"
  lsof -nP -i TCP -sTCP:ESTABLISHED 2>/dev/null | awk 'NR>1 {n=$(NF-1); sub(/.*->/, "", n); print n, $1}' \
    | sort | uniq -c | sort -rn | head -30
elif command -v ss >/dev/null 2>&1; then
  ss -tunap 2>/dev/null | grep -E 'ESTAB|LISTEN' | head -40
else
  echo "(no lsof/ss available — check manually)"
fi
echo ">>> Review each foreign IP against known services (git host, registries, CDN, VPN, DNS)."
echo ">>> Unknown IP + persistent connection owned by an interpreter process = beacon candidate."

echo
echo "===== 4. PERSISTENCE & CREDENTIAL EXPOSURE ====="
for d in "$HOME/Library/LaunchAgents" "/Library/LaunchAgents" "/Library/LaunchDaemons"; do
  [ -d "$d" ] || continue
  echo "--- $d"
  if [ -n "$SINCE" ]; then find "$d" -name '*.plist' -newermt "$SINCE" -print; else ls -la "$d"; fi
done
[ -d "$HOME/.config/systemd/user" ] && { echo "--- systemd user units"; ls -la "$HOME/.config/systemd/user"; }
echo "--- crontab"; crontab -l 2>&1 | head -10
echo "--- shell rc files (mtime)"
ls -la "$HOME"/.zshenv "$HOME"/.zshrc "$HOME"/.zprofile "$HOME"/.bashrc "$HOME"/.bash_profile "$HOME"/.profile 2>/dev/null
echo "--- ~/.ssh"; ls -la "$HOME/.ssh" 2>/dev/null | head -12
[ -f "$HOME/.ssh/authorized_keys" ] && echo "!! authorized_keys EXISTS — verify every key is yours"
echo "--- git/CLI credential surfaces (mtimes)"
ls -la "$HOME/.git-credentials" "$HOME/.gitconfig" 2>/dev/null
ls -la "$HOME/.config/gh/hosts.yml" 2>/dev/null
echo "--- IDE global settings (allowAutomaticTasks?)"
for s in "$HOME/Library/Application Support/Code/User/settings.json" "$HOME/.config/Code/User/settings.json"; do
  [ -f "$s" ] && { grep -H 'allowAutomaticTasks' "$s" || echo "clean: $s"; }
done

echo
echo "===== END — triage is read-only; investigate anything flagged above before acting ====="
