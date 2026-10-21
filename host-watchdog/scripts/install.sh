#!/usr/bin/env bash
# Install the host watchdog as a recurring launchd job (macOS, default 6h).
# Usage: install.sh [interval-seconds]   (default 21600 = 6 hours)
# StartInterval (not a calendar time) so a missed slot while asleep fires on
# wake — a laptop that slept through the interval still gets scanned.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
interval="${1:-21600}"

[ -f "$HOME/.host-watchdog.conf" ] || {
  cp "$here/host-watchdog.example.conf" "$HOME/.host-watchdog.conf"
  chmod 600 "$HOME/.host-watchdog.conf"
  echo "created ~/.host-watchdog.conf — EDIT IT (TG creds + allowlist) before relying on alerts"
}

plist="$HOME/Library/LaunchAgents/com.athalla.host-watchdog.plist"
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.athalla.host-watchdog</string>
  <key>ProgramArguments</key><array>
    <string>/bin/bash</string><string>$here/scan-host.sh</string>
  </array>
  <key>StartInterval</key><integer>$interval</integer>
  <key>StandardOutPath</key><string>$HOME/Library/Logs/host-watchdog.log</string>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/host-watchdog.log</string>
</dict></plist>
EOF
launchctl unload "$plist" >/dev/null 2>&1 || true
launchctl load "$plist"
echo "installed: scan every $((interval/3600))h (StartInterval $interval) — log: ~/Library/Logs/host-watchdog.log"
echo "test now:  bash $here/scan-host.sh"
