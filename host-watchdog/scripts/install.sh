#!/usr/bin/env bash
# Install the host watchdog as a fixed-schedule launchd job (macOS):
# 00:07, 06:07, 12:07, 18:07 — night / start of work / lunch / end of work.
# Off-round minute by house convention. Missed slots while asleep fire on
# wake (launchd coalesces them) — a sleeping laptop still gets scanned.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

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
  <key>StartCalendarInterval</key><array>
    <dict><key>Hour</key><integer>0</integer><key>Minute</key><integer>7</integer></dict>
    <dict><key>Hour</key><integer>6</integer><key>Minute</key><integer>7</integer></dict>
    <dict><key>Hour</key><integer>12</integer><key>Minute</key><integer>7</integer></dict>
    <dict><key>Hour</key><integer>18</integer><key>Minute</key><integer>7</integer></dict>
  </array>
  <key>StandardOutPath</key><string>$HOME/Library/Logs/host-watchdog.log</string>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/host-watchdog.log</string>
</dict></plist>
EOF
launchctl unload "$plist" >/dev/null 2>&1 || true
launchctl load "$plist"
echo "installed: daily scans at 00:07, 06:07, 12:07, 18:07 — log: ~/Library/Logs/host-watchdog.log"
echo "test now:  bash $here/scan-host.sh"
