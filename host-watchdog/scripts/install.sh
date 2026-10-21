#!/usr/bin/env bash
# Install the host watchdog as a daily launchd job (macOS).
# Usage: install.sh [scan-hour] [scan-minute]   (default 8 17)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
hour="${1:-8}"; minute="${2:-17}"

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
  <key>StartCalendarInterval</key><dict>
    <key>Hour</key><integer>$hour</integer>
    <key>Minute</key><integer>$minute</integer>
  </dict>
  <key>StandardOutPath</key><string>$HOME/Library/Logs/host-watchdog.log</string>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/host-watchdog.log</string>
</dict></plist>
EOF
launchctl unload "$plist" >/dev/null 2>&1 || true
launchctl load "$plist"
echo "installed: daily scan at $hour:$(printf '%02d' "$minute") — log: ~/Library/Logs/host-watchdog.log"
echo "test now:  bash $here/scan-host.sh"
