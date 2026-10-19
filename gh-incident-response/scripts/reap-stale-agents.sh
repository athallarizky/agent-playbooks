#!/usr/bin/env bash
# List (default / dry-run) or terminate (--kill) STALE agent sessions.
# Stale = last activity older than N days (default 3) — activity is judged from
# the newest mtime of transcript/log files the process holds open. Process age
# alone is NOT staleness: a 10-day-old session written to minutes ago is ACTIVE.
# Unknown-activity processes are called stale only if BOTH age > N days AND 0% CPU.
# Safety: never kills the session running this script or its ancestors; MCP
# children die with their parent — only orphaned survivors get reaped.
# Usage: reap-stale-agents.sh [--kill] [max-idle-days]
set -uo pipefail

KILL=0; DAYS=3
for a in "$@"; do case "$a" in --kill) KILL=1 ;; ''|*[!0-9]*) ;; *) DAYS="$a" ;; esac; done
SECS=$(( DAYS * 86400 )); NOW=$(date +%s)

AGENT_RE='(^|/| )(claude|agy|antigravity|gemini|codex|cursor-agent|aider|copilot|opencode|windsurf)( |$)'
MCP_RE='(context7|mcp|figcraft-cli|serena|firecrawl|playwright)'

# protect self + ancestors
SELF_CHAIN=" $$"
p=$$
while [ "$p" -gt 1 ]; do p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' '); [ -z "$p" ] && break; SELF_CHAIN="$SELF_CHAIN $p"; done

etime_days() { case "$1" in *-*) echo "${1%%-*}" ;; *) echo 0 ;; esac; }
last_activity() {  # newest mtime among open .jsonl/.log files; empty = unknown
  lsof -p "$1" 2>/dev/null | awk '$NF ~ /\.(jsonl|log)$/ {print $NF}' | sort -u \
    | while read -r f; do stat -f '%m' "$f" 2>/dev/null; done | sort -rn | head -1
}

echo "== agent sessions (idle threshold: ${DAYS} days, kill=${KILL} =="
printf "%-8s %-12s %-6s %-12s %s\n" PID AGE_CPU IDLE VERDICT DETAIL
victims=""
while read -r pid ppid etime cpu cputime command; do
  [ -z "$pid" ] && continue
  case " $SELF_CHAIN " in *" $pid "*) verdict="SELF(keep)"; idle="-"; detail="this session" ;; *)
    last=$(last_activity "$pid")
    if [ -n "$last" ] && [ "$last" -gt 0 ] 2>/dev/null; then
      idle_min=$(( (NOW - last) / 60 ))
      if   [ $(( NOW - last )) -gt "$SECS" ]; then verdict="STALE"; else verdict="ACTIVE"; fi
      detail="last-write $(date -r "$last" '+%m-%d %H:%M' 2>/dev/null)"
    else
      idle_min="-"
      age=$(etime_days "$etime")
      if [ "$age" -gt "$(( DAYS > 0 ? DAYS : 0 ))" ] && [ "$cpu" = "0.0" ]; then verdict="STALE(no-signal)"; else verdict="UNKNOWN(keep)"; fi
      detail="age=${etime} cpu=${cpu}%"
    fi
    case "$verdict" in STALE*) victims="$victims $pid" ;; esac
    printf "%-8s %-12s %-6s %-12s %.70s\n" "$pid" "$etime" "$cpu%" "${idle_min}m" "$verdict | $detail | ${command:0:40}"
  ;; esac
done < <(ps axo pid,ppid,etime,%cpu,cputime,command | grep -E "$AGENT_RE" | grep -vE 'grep|crashpad|reap-stale')

if [ "$KILL" -ne 1 ]; then
  echo; echo "DRY-RUN — stale PIDs:${victims:- none}. Re-run with --kill to terminate."
  exit 0
fi

[ -z "$victims" ] && { echo "nothing stale — no action."; exit 0; }
echo; echo "TERMinating:${victims}"
kill $victims 2>/dev/null; sleep 3
kill -9 $victims 2>/dev/null

echo "-- reaping orphaned MCP survivors --"
ps axo pid,ppid,etime,%cpu,command | grep -E "$MCP_RE" | grep -vE 'grep|reap-stale' \
| while read -r pid ppid etime cpu command; do
  if ! ps -p "$ppid" >/dev/null 2>&1; then
    case " $SELF_CHAIN " in *" $pid "*) ;; *) echo "orphan MCP: $pid ($command)"; kill "$pid" 2>/dev/null ;; esac
  fi
done
echo "done."
