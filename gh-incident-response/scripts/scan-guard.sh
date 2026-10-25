#!/usr/bin/env bash
# scan-guard.sh — pre-scan safety gate for clone-based malware scanning.
#
# The campaign's execution vector is VS Code `folderOpen` tasks: they fire the
# moment an editor window opens an infected checkout. Before cloning/scaning,
# make sure no editor is (or will be) sitting on the scan area.
#
# Usage:
#   scan-guard.sh <scan-root>          # surgical: kill ONLY editor processes
#                                      # holding anything open under <scan-root>
#   scan-guard.sh <scan-root> --all    # force-quit ALL editor instances
#                                      # (VS Code, Cursor, VSCodium, Windsurf)
#   scan-guard.sh <scan-root> --dry    # report only, kill nothing
#
# Exits 0 when the scan root is clear of editors. Fails loud (exit 1) if an
# editor could not be killed — do NOT proceed with the scan in that case.
set -u

root="${1:?usage: scan-guard.sh <scan-root> [--all|--dry]}"
mode="${2:-surgical}"
root="$(cd "$root" 2>/dev/null && pwd)" || { echo "scan-root tidak ada: $1"; exit 1; }

# editor app-bundle paths — match the INSTALL LOCATION, not loose substrings:
# a naive 'Cursor' pattern matches macOS CursorUIViewService.xpc (text cursor),
# and orphaned chrome_crashpad_handler matches 'Visual Studio Code.app'.
EDITORS='Applications/Visual Studio Code\.app|Applications/VSCodium\.app|Applications/Cursor\.app|Applications/Windsurf\.app|Applications/Code - Insiders\.app'

kill_pids() {  # $@ = pids; graceful first, force after 3s
  local pids="$*"
  [ -z "$pids" ] && return 0
  kill $pids 2>/dev/null
  sleep 3
  local alive=""
  for p in $pids; do kill -0 "$p" 2>/dev/null && alive="$alive $p"; done
  [ -n "$alive" ] && kill -9 $alive 2>/dev/null
  sleep 1
  for p in $pids; do kill -0 "$p" 2>/dev/null && return 1; done
  return 0
}

if [ "$mode" = "--all" ]; then
  pids=$(pgrep -if "$EDITORS" || true)
  if [ -z "$pids" ]; then echo "guard: tidak ada editor berjalan — aman."; exit 0; fi
  echo "guard: force-quit SEMUA editor (pids:$pids)…"
  if kill_pids $pids; then echo "guard: semua editor mati. aman scan."; exit 0; fi
  echo "guard: GAGAL membunuh editor — JANGAN lanjut scan."; exit 1
fi

# surgical / dry: find editor processes with anything open under the scan root
suspects=$(lsof +D "$root" 2>/dev/null | awk 'NR>1 {print $2}' | sort -u)
hits=""
for p in $suspects; do
  if ps -p "$p" -o command= 2>/dev/null | grep -Eq "$EDITORS"; then hits="$hits $p"; fi
done

if [ -z "$hits" ]; then
  echo "guard: tidak ada editor membuka $root — aman scan."
  exit 0
fi
if [ "$mode" = "--dry" ]; then
  echo "guard[DRY]: editor di atas scan-root (pids:$hits) — akan dibunuh pada run nyata."
  exit 0
fi
echo "guard: membunuh editor yang membuka scan-root (pids:$hits)…"
if kill_pids $hits; then echo "guard: bersih. aman scan."; exit 0; fi
echo "guard: GAGAL — JANGAN lanjut scan."; exit 1
