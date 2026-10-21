#!/usr/bin/env bash
# Local host watchdog — daily read-only scan for the incident's threat class:
# unknown outbound connections (beacon candidates), interpreter processes
# touching font/asset payloads, unexpected listeners, fresh persistence.
# macOS-first (lsof); runs as the user, no sudo needed.
# Usage: scan-host.sh [--test]   (--test = send a Telegram test message and exit)
# Config: ~/.host-watchdog.conf (chmod 600) — see host-watchdog.example.conf
# Verdict style mirrors scan-ioc.sh: silence = healthy; findings → Telegram
# (same bot/topic as the GitHub guardian). WARN = triage; CRIT = escalate to
# gh-incident-response triage-local.sh immediately.
set -uo pipefail

CONF="${HOST_WATCHDOG_CONF:-$HOME/.host-watchdog.conf}"
[ -f "$CONF" ] && . "$CONF"

INTERPRETERS_RE='^(node|deno|bun|python[0-9.]*|perl|ruby|php|osascript)$'
warn=0; crit=0; out=""

emit() { # $1=level $2=line
  out="${out}$2"$'\n'
  case "$1" in
    WARN) warn=$((warn+1)); echo "WARN $2" ;;
    CRIT) crit=$((crit+1)); echo "CRIT $2" ;;
  esac
}

is_private() { case "$1" in
  127.*|::1|fe80:*|192.168.*|10.*|172.1[6-9].*|172.2[0-9].*|172.3[01].*|169.254.*) return 0 ;;
  *) return 1 ;; esac; }

# resolve allowlist hosts once (dig +short; tolerates bare IPs)
allowed_ips="${ALLOWED_IPS:-}"
for h in ${ALLOWED_HOSTS:-}; do
  ips=$(dig +short "$h" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+' )
  allowed_ips="$allowed_ips $ips"
done
ip_allowed() { is_private "$1" && return 0; for a in $allowed_ips; do [ "$1" = "$a" ] && return 0; done; return 1; }

if [ "${1:-}" = "--test" ]; then
  . /dev/stdin <<EOF
$(declare -f notify_tg)
EOF
  notify_tg() {
    [ -z "${TG_BOT_TOKEN:-}" ] || [ -z "${TG_CHAT_ID:-}" ] && { echo "TG creds kosong di $CONF"; exit 1; }
    local args=(-s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" -d chat_id="${TG_CHAT_ID}" -d text="$1" --max-time 20)
    [ -n "${TG_THREAD_ID:-}" ] && args+=(-d message_thread_id="${TG_THREAD_ID}")
    curl "${args[@]}" >/dev/null
  }
  notify_tg "✅ host-watchdog test — kanal OK ($(hostname) $(date '+%F %T'))" && echo "test sent"
  exit 0
fi

notify_tg() {
  [ -z "${TG_BOT_TOKEN:-}" ] || [ -z "${TG_CHAT_ID:-}" ] && return 0
  local t="$1"; [ ${#t} -gt 3500 ] && t="${t:0:3500} …(truncated)"
  local args=(-s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" -d chat_id="${TG_CHAT_ID}" -d text="$t" --max-time 20)
  [ -n "${TG_THREAD_ID:-}" ] && args+=(-d message_thread_id="${TG_THREAD_ID}")
  curl "${args[@]}" >/dev/null || true
}

# ── 1. OUTBOUND established ────────────────────────────────────────────────
while read -r proc pid raddr; do
  [ -z "${raddr:-}" ] && continue
  rip=${raddr%:*}; rip=${rip#[}; rip=${rip%]}
  [ -z "$rip" ] && continue
  if ip_allowed "$rip"; then continue; fi
  if echo "$proc" | grep -Eq "$INTERPRETERS_RE"; then
    emit CRIT "beacon candidate: $proc (pid $pid) -> $rip  [interpreter + non-allowlisted remote]"
  else
    emit WARN "unknown remote: $proc (pid $pid) -> $rip"
  fi
done < <(lsof -nP -iTCP -sTCP:ESTABLISHED 2>/dev/null | awk 'NR>1{n=$9; sub(/.*->/,"",n); if(n!="") print $1, $2, n}')

# ── 2. PAYLOAD EXECUTION: any process with a font/asset path as argument ───
while read -r pid cmd; do
  if printf '%s' "$cmd" | grep -qE '(^|[ /"'"'"'])[^ ]*\.(woff2?|ttf|otf|eot)( |$|"|'"'"')'; then
    emit CRIT "payload execution: pid $pid :: ${cmd:0:160}"
  fi
done < <(ps -axo pid=,command= 2>/dev/null)

# ── 3. LISTENERS: interpreter-owned, or public-facing non-allowlisted port ─
while read -r proc pid laddr; do
  [ -z "${laddr:-}" ] && continue
  port=${laddr##*:}
  case "$laddr" in *:*) ;; *) continue;; esac
  pub=0; case "$laddr" in *:*) [ "${laddr%%:*}" != "127.0.0.1" ] && [ "${laddr%%:*}" != "[::1" ] && pub=1;; esac
  interpreter=0; echo "$proc" | grep -Eq "$INTERPRETERS_RE" && interpreter=1
  port_ok=0; for p in ${ALLOWED_LISTEN_PORTS:-}; do [ "$port" = "$p" ] && port_ok=1; done
  if [ "$interpreter" = 1 ]; then
    [ "$port_ok" = 1 ] || emit WARN "interpreter listener: $proc (pid $pid) @ $laddr"
  elif [ "$pub" = 1 ] && [ "$port_ok" = 0 ]; then
    emit WARN "public listener: $proc (pid $pid) @ $laddr"
  fi
done < <(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR>1{print $1, $2, $9}')

# ── 4. PERSISTENCE: LaunchAgents/Daemons & crontab changed < 24h ──────────
while read -r f; do emit WARN "persistence changed <24h: $f"; done < <(find \
  "$HOME/Library/LaunchAgents" /Library/LaunchAgents /Library/LaunchDaemons \
  -type f \( -name '*.plist' \) -mtime -1 2>/dev/null)
crontab -l 2>/dev/null | grep -q . && emit WARN "crontab non-empty (review manually)"

echo "---"
# ── dedup: Telegram details only NEW findings; still-active WARNs collapse to
# a count, still-active CRITs stay detailed (safety beats fatigue on CRIT) ──
state_file="${HOST_WATCHDOG_STATE:-$HOME/.host-watchdog.state}"
prev=""
[ -f "$state_file" ] && prev=$(cat "$state_file" 2>/dev/null)
new_out=""; still=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  if printf '%s\n' "$prev" | grep -qxF "$line"; then
    still=$((still+1))
    case "$line" in CRIT*) new_out="${new_out}${line}"$'\n' ;; esac
  else
    new_out="${new_out}${line}"$'\n'
  fi
done <<< "$out"
printf '%s' "$out" > "$state_file"

echo "VERDICT: warn=$warn crit=$crit still-active=$still new=$(grep -c . <<< "$new_out" || true) host=$(hostname) at $(date '+%F %T')"
if [ "$warn" -gt 0 ] || [ "$crit" -gt 0 ]; then
  summary=""
  [ "$still" -gt 0 ] && summary=" ($still masih aktif dari run sebelumnya — tidak diulang)"
  if [ -n "$(printf '%s' "$new_out" | tr -d $'\n')" ]; then
    notify_tg "⚠️ HOST-WATCHDOG ($(hostname), $(date '+%F %T')) — warn=$warn crit=$crit$summary
${new_out}Escalate CRIT with: gh-incident-response triage-local.sh"
  fi
fi
[ "$crit" -eq 0 ]
