# GitHub Incident Response

> Investigate, contain, and recover from a GitHub account or repository compromise — mass forced pushes, history rewrites, injected malware, and stolen tokens. Companion to `repo-triage` (which scans one cloned repo): this playbook runs the full response when YOUR GitHub is the victim.

## Trigger

The user will say things like:
- "GitHub saya ada anomali" / weird mass pushes, repos showing updates they never made
- Commits or branches missing / rolled back / replaced overnight
- Security alert emails, unknown OAuth apps, unfamiliar sign-in notifications
- Someone reports malicious files (e.g., fake `.vscode/tasks.json`, payload fonts) appearing in their repos
- "Audit my GitHub" after noticing anything off

## Phase 0 — Ground Rules (read before touching anything)

1. **NEVER run repo code. No exceptions.** No `npm install`, no scripts, no make, no executing "font"/asset files — not even "to see what it does". Malware here is designed to auto-run (IDE tasks on folder open); do not become the trigger.
2. **Reading ≠ executing.** Safe operations: `gh api` reads, `git clone`/`fetch`/`ls-tree`/`show` (metadata + text viewing). Unsafe: opening a repo folder in any IDE, running any file from it, sourcing anything.
3. Clone only into a temp dir if needed; delete it when done. Never open temp clones in an IDE.
4. Everything is **read-only until Gate 1** (Phase 4). Cleanup before containment gets re-poisoned and warns the attacker.
5. **Preserve evidence before mutating anything** — push events expire (~90 days) and the feed caps out; capture SHAs early (Phase 2).
6. Report findings with evidence (SHAs, timestamps, file paths), never vibes — and never print secret values.

## Phase 1 — Detect & Scope (read-only)

Work through these with `gh api` (authenticated as the account owner):

1. **Events forensics** — pull the user's public push events and look for anomalies:
   ```bash
   gh api --paginate users/<login>/events/public --jq '.[] | select(.type=="PushEvent") | "\(.created_at) \(.repo.name) \(.payload.ref) before=\(.payload.before[0:8]) head=\(.payload.head[0:8])"'
   ```
   Red flags: bursts across many repos within minutes (scripted sweep), alphabetical repo order (tool iterating a repo list), pushes at odd hours, pushes to repos the user hasn't touched in years.
2. **History-rewrite signature** — a PushEvent with **0 new commits but `before` ≠ `head`** means a ref was force-moved without new objects: a rewind, or a swap to a *lookalike commit*. Lookalike = same commit message + same author date + **different SHA**. That is tampering, not syncing.
3. **Actor identity** — check `.actor.login` on the events. User's own login → a user credential (OAuth app token, PAT, CLI token, SSH key) was used. A bot/app login → a GitHub App token; those never appear in the *user's* security log, only org/repo audit logs.
4. **Repo-level cross-check** — `pushed_at` fresh but default-branch tip old ⇒ non-default branches or tags were touched. List branches; compare tips against pre-incident expectations.
5. **Marker scan, ALL branches, DEEP paths** — payloads hide in nested directories (`docs/`, fixtures, test snapshots, deep source trees), never only at the repo root. Scan recursively:
   ```bash
   gh api "repos/<owner>/<repo>/git/trees/<branch>?recursive=1" --jq '.tree[].path' | grep -E '<ioc-path-regex>'
   ```
   Use `scripts/scan-ioc.sh` to sweep every repo/branch systematically (two-stage: tree-path filter, then content-marker check).
6. **Scope the blast radius**: own repos, forks, org repos, collaborator repos — anything the stolen credential could write to. Check `permissions.push` per repo for what the current token can reach (and therefore what the attacker could).

### IOC Reference (known campaign; extend as new ones are seen)

- `.vscode/tasks.json` — a task disguised as a linter (e.g. `eslint-check`), shell command invoking an interpreter (`node`, `python`) on a **font/asset path**, `"runOn": "folderOpen"`, `"hide": true`, `presentation.reveal: "never"`, `close: true`
- `.vscode/settings.json` — `"task.allowAutomaticTasks": true` plus stealth terminal settings (`hideOnStartup`, `inheritEnv: false`)
- **Fake font** — a text file (often one line of obfuscated JS: string-array rotation, XOR-hex blobs, `Function()` constructor) named like a real font with a typo/plural variant, e.g. `fa-brand-400.woff` next to legitimate `fa-brands-400.*` binaries. Real fonts are binary — `file` reporting *text* on a `.woff` = payload
- `fonts/README.md` camouflage copy referencing an unrelated app
- `.gitignore` gaining odd entries (e.g. `config.bat` — a stage-2 name)
- Commit messages/dates copied verbatim from the originals they replaced (lookalike rewrite)

## Phase 2 — Evidence Preservation (still read-only)

1. **Save the full SHA inventory immediately** — `scripts/capture-events.sh <since>` writes `repo|branch|before|head` for every push event, plus a deduped restore map keeping the **earliest** `before` per ref. Rationale: multi-pass attacks rewrite the same ref repeatedly; later `before` values are attacker states, only the earliest is pre-attack.
2. **Security log export** — the user exports theirs from the web UI (Settings → Security log → export). The user-level log can lag by hours and may not record git pushes made via app/bot tokens; org audit logs (owner-only) are richer. Ask the user to paste/export rather than trusting only one source.
3. **Know the API's blind spots**: the public events feed covers public repos only (private-repo activity is invisible there), paginates with caps, and 404 on a commit via REST ≠ the commit is gone. Unreferenced ("dangling") commits usually remain fetchable by full SHA (`git fetch origin <full-sha>`) and viewable via the web commit URL for a long window — that is the recovery lever.
4. Keep every intermediate artifact (event dumps, target lists, restore maps) in temp files; they are the audit trail.

## Phase 3 — Attribution (credential hunting)

Enumerate what could have written, and where the evidence points:

| Credential | Behavior that identifies it |
|---|---|
| OAuth app (third-party) | Acts AS the user (events show user as actor); server-side pacing (bursts + throttled trickle) fits a queued API script; check Authorized OAuth apps + "last used" |
| PAT (classic / fine-grained) | Acts as the user; verify claimed scopes against reality — "read-only" beliefs are often wrong |
| CLI OAuth token | Acts as the user; lives in machine keyrings — a remote attacker needs it exfiltrated first |
| SSH key | Acts as the user for git pushes; check key creation dates and titles |
| Deploy key (per-repo SSH) | Repo-scoped, invisible in the user security log; sweep `/repos/:repo/keys` across repos |
| GitHub App / bot token | Actor shows as the bot; entries land in org/repo audit logs, not the user log |
| Web session | Password auth; check the sessions page for unknown devices/IPs |

**Key discriminator — the IP.** From security/audit log entries for the incident window: an IP belonging to the user's own network ⇒ the code ran on one of the user's own devices; a foreign/cloud IP ⇒ the token was exfiltrated and used remotely.

**Automation corollary**: if personal repos were pushed as the user while org repos were pushed as an automation/bot identity, both credentials likely live together in one place — the automation host (CI runner, bot VM, home server). That host is the prime suspect for initial access and must be isolated and forensically reviewed, not just its tokens rotated.

## Phase 4 — Containment (GATE 1 — user actions in browser; agent cannot do these)

Do not start cleanup until the user confirms:

1. Revoke suspicious/unused **OAuth apps** (Settings → Applications)
2. Delete **all PATs** (classic + fine-grained) — recreation is cheap; debate is expensive
3. Change **password** + "sign out of all sessions"; verify 2FA
4. Remove unrecognized **SSH keys**; sweep deploy keys
5. Rotate any **automation/bot accounts** the user owns (separate accounts are NOT covered by revoking the main account)
6. **Isolate the automation host(s)** (stop services; don't wipe yet — evidence)

### Local machine triage while waiting (still: run nothing from repos)

Run `scripts/triage-local.sh [since]` (read-only; macOS + Linux) and review its four sections:

1. **File footprint** — marker-based scan of the home directory for malicious `.vscode/tasks.json` / `.vscode/settings.json` (**marker-based, not presence-based** — the user's own legit task files must survive); fake-font hunt (`file` reporting *text* on a font = payload); `.git` directory mtimes inside the incident window (did a pull/clone bring poison to disk?). If no poison ever landed locally, nothing could have executed — the machine is clean regardless of what was opened.
2. **Suspicious processes** — interpreters (`node`, `python`, `perl`, `ruby`, `osascript`) whose script/argument path lives under temp dirs, `~/Downloads`, package caches, or repo folders; **any process whose argument is a font/asset path (`.woff`, `.ttf`, `.otf`) = confirmed payload execution**; interpreter processes with unusual parentage (spawned by an IDE/task runner) or start times inside the incident window. Review the full interpreter list manually — automated heuristics miss things.
3. **Network exposure** — established outbound connections (`lsof -nP -i` / `ss -tunp`) grouped by foreign address, plus every LISTEN socket. Flag destinations matching none of the user's known services (git host, package registries, CDNs, VPN, DNS); flag odd ports and any unexpected new listener. Verify IP ownership (whois/RDAP) before declaring — but an unknown IP holding a persistent connection owned by an interpreter process is a beacon candidate: treat as confirmed compromise.
4. **Persistence & credential exposure** — LaunchAgents/LaunchDaemons (user + system) created/modified near the window, crontab, shell rc files, `~/.ssh/authorized_keys`, git credential stores (`~/.git-credentials`, credential-helper config) and CLI token-file mtimes, and global IDE user settings (`task.allowAutomaticTasks`).

**Stale agent session hygiene — terminate anything idle > 3 days.** Running agent CLIs (`claude`, `agy`/Antigravity, `codex`, `gemini`, `cursor-agent`, `aider`, `opencode`, …) hold live tokens in memory and — under skip-permissions flags — full execution rights. Sessions left alive for days are standing attack surface, especially mid-incident. After triage, run `scripts/reap-stale-agents.sh` (dry-run by default; `--kill` to terminate):

- **Staleness = last activity older than 3 days**, judged from the newest mtime of transcript/log files the process holds open — **never from process age alone**. A 10-day-old session whose log was written minutes ago is ACTIVE; a born-yesterday session at 0% CPU with no recent writes may still be needed. When no activity signal exists, require BOTH age > 3 days AND 0% CPU before calling it stale.
- Kill parent sessions first; the MCP servers they spawned (`context7`, IDE MCP bridges, …) die with their parent — reap only survivors left orphaned (parent PID gone).
- The script never kills the session running it, and never kills unknowns silently — dry-run list goes to the user for confirmation before `--kill`.

If poison was pulled AND an IDE opened that folder — or triage finds any payload-execution or beacon signature — escalate to full host incident response: assume credential theft from that machine (keychains, browser sessions, SSH keys, stored tokens), rotate everything reachable from it, and prefer rebuild over cleanup.

## Phase 5 — Recovery (GATE 2 — only after the user confirms Gate 1)

Attack the cleanup in priority order:

1. **Force-restore original SHAs** (best outcome — history returns exactly to pre-attack):
   ```bash
   gh api -X PATCH repos/<owner>/<repo>/git/refs/heads/<branch> -f sha=<original-full-sha> -F force=true
   ```
   Server-side ref move, no clone needed. Original SHAs come from the Phase 2 restore map (earliest `before` per ref) or from **pre-incident push-event archaeology**: the latest event head per repo+branch *before* the incident window is the pre-attack tip. `scripts/restore-refs.sh <map-file>` runs the sweep.
   Effect: poisoned commits become **unreachable** → `git clone` can never fetch them again.
2. **Fallback — marker-checked delete commits** where no original SHA is known (`scripts/clean-markers.sh <targets-file>`): GET blob → verify malicious markers → DELETE via contents API (creates a cleanup commit). Tips become clean; poisoned commits stay *reachable in history* (note this for Phase 7). Also strip injected `.gitignore` lines (GET → filter → PUT).
3. **Assume earlier waves.** The first observed event is not necessarily the attack start — "original" commits can already contain payload (verified by re-scanning after restore). Always re-verify restored refs; run the fallback cleaner on anything that still trips markers.
4. **Never delete by presence alone** — a legit `tasks.json` owned by the user is not malware. Gate every destructive op on content markers.

## Phase 6 — Verification

Two-stage, cheap-first (`scripts/scan-ioc.sh` does both):

1. Tree-path stage: `git/trees/<branch>?recursive=1` filtered by IOC path regex — no hits ⇒ clean for sure
2. Content stage (only where suspicious paths exist): decode contents, match markers

Cover **every default branch AND every non-default branch that was touched**. Produce a verdict line: `clean X/Y refs`. Re-run after every fix round until `X == Y`.

## Phase 7 — Post-Incident

- **Deploy platforms**: if `public/`-style dirs were poisoned and auto-deploy was live, the production site may be serving payload files. Check deployments in the incident window; redeploy from a clean commit
- **GitHub Support ticket**: report the campaign (timeline, IOC list, SHA inventory) — request purge of remaining poisoned objects from reachable history and any actor info visible only server-side
- **History honesty note**: restored refs = poison unreachable (clean clones guaranteed); fallback-cleaned repos = clean tips, poison in old commits until purged/rewritten — prioritize critical repos for a local history rewrite if support can't help
- **Re-poisoning watch**: repeat the Phase 6 scan periodically (hours → days) until confident the credential leak is fully closed — remember automation accounts and hosts are separate re-entry points
- **Postmortem**: identify initial access (phishing "Sign in with GitHub", a malicious skill/plugin/package the user installed, compromised automation host). Fix the class of problem, not just the instance: least-scope short-lived PATs, no user-scope tokens inside automation hosts, review OAuth app grants quarterly

## Rules for the Responder

- **Do not run repo code. Do not open repos in an IDE.** The payload's whole design is auto-execution
- Read-only until Gate 1; no cleanup before credential revocation is confirmed
- Capture evidence (SHAs, events) before mutating anything
- Multi-pass attacks: restore to the **earliest** `before`, and expect restored "originals" to still be poisoned — verify everything
- Scan deep (recursive trees, all branches), judge by content markers, never by file presence
- The user's own legit configs must survive cleanup — when ambiguous, ask, don't delete
- Surface unresolved attribution honestly; "unknown actor, credentials rotated, watching" is an acceptable end state
