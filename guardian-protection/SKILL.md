# Guardian Protection

> The prevention & monitoring layer: rulesets and in-repo guards against the malware-campaign class, plus operating the [guardian](https://github.com/athallarizky/guardian) watchdog (R-code map, dispatcher, keepalive). Companion to `gh-incident-response` (which scans and recovers AFTER compromise) and to the guardian repo's `AGENTS.md` (which triages its alerts).

## Trigger

The user will say things like:
- "Protect repo baru ini" / "pasang ruleset di repo X" / "onboard repo"
- "Setup guardian di mesin baru" / "guardian-map update"
- "Guardian jalan tidak?" / "cek dispatcher"
- "Lift/pause ruleset" (untuk ref surgery)

## The layers (what protects what)

| Layer | Tool | Where it lives |
|---|---|---|
| Branch ruleset `malware-guard` (signatures, no force-push, no delete) | `scripts/protect-repos.sh` | GitHub, outside repo content |
| In-repo guard workflow (private repos where rulesets need a paid plan) | `scripts/deploy-guard.sh` + `guard/malware-guard.yml` | `.github/workflows/` of the target repo |
| Hourly watchdog sweep (IOC + `.vscode` policy + SCAN-ERROR) | `guard/guardian-sweep.yml` template; live copy in the guardian repo | Outside victim repos by design |
| R-code map (resolve masked repo names in alerts) | `scripts/guardian-map.sh` + `~/.guardian-map.txt` | Local, derived — never synced |
| Ruleset lift (temporarily disable for incident ref surgery) | `scripts/ruleset-lift.sh` | — |

**New repo? One command:** `scripts/onboard-repo.sh <owner/repo>` — ruleset, private-repo fallback, map refresh, summary.

## Platform constraints (learned 2026-10-20 — verify before fighting them)

- Branch rulesets: **public repos any plan; private repos need Pro/Team**. Failures are reported, not fatal — that's what the in-repo guard covers.
- `file_path_restriction` / push rulesets: **org-owned repos on paid plans only** — personal repos can never have server-side path blocking. The compensating control is guardian detection speed (≤ ~1 h).
- Rulesets ARE enforced on forks.
- Rulesets also block the **Git Data API** ref path (delete/force-update) — incident ref surgery must lift first (`ruleset-lift.sh <repo> off` → operate → `on`).
- Commit signatures: web-UI edits and local `git commit -S` pass; **REST Contents-API commits and GITHUB_TOKEN pushes are unsigned** — any workflow that commits via API must live in a repo WITHOUT `required_signatures` (that is why guardian's own ruleset omits it).

## Guardian operations

- **Map is derived, not synced** — regenerate with `scripts/guardian-map.sh` (needs `~/.guardian-salt`). A stale map just misses NEW repos; regeneration is additive and never changes old codes.
- **The salt never passes through an agent**: password-manager → `~/.guardian-salt` (chmod 600) → script. Never accept it in conversation; never commit it anywhere.
- **Dispatcher**: `~/development/personal/guardian-dispatcher/` (Cloudflare Worker, cron */20). Any "Manually run" in the guardian Actions history = native cron missed a slot. Dispatch failures visible via `npx wrangler tail`.
- **Keepalive**: weekly commit via Contents API in the guardian repo (unsigned by design — see constraints).

## Rules for the Operator

- Read-only until the user confirms which repos to protect; batch scripts print a plan before mutating when practical
- After `purge-history.sh` (history rewrite), re-run protection — rewritten commits have no signatures until re-signed
- Report honestly what could not be protected (private-plan limits) instead of pretending coverage
- Salt/token hygiene is absolute: no secrets in chats, transcripts, or commits
- For scanning and cleanup of actual findings, switch to `gh-incident-response` — this playbook prevents and monitors, it does not clean
