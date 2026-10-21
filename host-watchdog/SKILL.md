# Host Watchdog

> Daily read-only scan of the LOCAL machine (mbp, macmini) for the incident's threat class: outbound connections to non-allowlisted IPs (beacon candidates — e.g. an AI agent that accidentally ran something), interpreter processes touching font/asset payloads, unexpected listeners, and fresh persistence. The local counterpart of the GitHub [guardian](https://github.com/athallarizky/guardian): silence = healthy, findings → the same Telegram topic, CRIT → escalate to `gh-incident-response` `triage-local.sh`.

## Trigger

The user will say things like:
- "Cek watchdog lokal" / "scan host ini" / "ada notif host-watchdog"
- "install watchdog di mesin ini / macmini"
- "kenapa host-watchdog warn X?"

## Architecture

```
launchd (every 6h, per machine — StartInterval, fires on wake if slept through)
  └─ scripts/scan-host.sh (read-only, no sudo)
       ├─ OUTBOUND  remote IP not in allowlist → WARN
       │            …owned by an interpreter    → CRIT (beacon candidate)
       ├─ PAYLOAD   any process with a font/asset path arg → CRIT
       ├─ LISTEN    interpreter listeners / public ports    → WARN
       ├─ PERSIST   LaunchAgent/Daemon/crontab changed <24h → WARN
       └─ Telegram alerts are DEDUPED via ~/.host-watchdog.state:
            new findings → full detail; still-active WARNs → count only;
            still-active CRITs → always detailed (safety beats fatigue)
```

## Install (per machine)

```bash
bash scripts/install.sh            # 8 17 default = daily 08:17; pass hour minute to change
$EDITOR ~/.host-watchdog.conf      # TG creds (same bot as guardian) + allowlist curation
bash scripts/scan-host.sh          # immediate first run — expect WARN noise, curate until quiet
bash scripts/scan-host.sh --test   # verify the Telegram channel
```

Log: `~/Library/Logs/host-watchdog.log`. The first run always warns — that IS the calibration workflow: every WARN is either benign (add to `ALLOWED_HOSTS`/`ALLOWED_IPS`/`ALLOWED_LISTEN_PORTS`) or real.

## Triage when it fires

- **CRIT beacon candidate** (interpreter → unknown IP): run `gh-incident-response` `triage-local.sh` NOW; whois the IP; if confirmed compromise → full playbook (rotate everything reachable from this host)
- **CRIT payload execution** (font-path arg): that is the campaign's execution signature — same escalation
- **WARN unknown remote**: whois/RDAP the IP before judging; cloud + unfamiliar = investigate the owning process
- **WARN persistence <24h**: read the plist — did the user install something, or did something install itself?
- Remember the false-clean lesson: private ranges are always allowed; if the scanner itself fails (lsof unavailable), it must say so loudly, not report clean

## Rules for the Operator

- The scan is strictly read-only — it never kills processes or edits configs
- Config is per-machine and NEVER committed (contains the bot token); the example file stays generic
- macmini: deploy when it is powered on again (one command); its first runs double as re-entry detection after the incident
- New normal remote (new job, new tool)? Update the allowlist — don't ignore recurring WARNs; alarm fatigue is the failure mode this design exists to avoid
