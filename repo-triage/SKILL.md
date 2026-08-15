# Repo Triage

> Quickly scan a freshly cloned repository for malware, malicious scripts, supply-chain risks, and suspicious code before reading, running, or integrating it.

## Trigger
The user will say things like:
- "Audit this repo for malware"
- "Is this safe to clone/run?"
- "Scan this repository before I touch it"
- "Triage this newly cloned repo"
- "Does this code call any malicious API?"

## Goal

Produce a fast, evidence-based verdict: **safe**, **suspicious**, or **dangerous** — plus a prioritized list of what to inspect or avoid running. This is a triage scan, not a full security review; optimize for catching what would hurt the user immediately.

## Scan Order

Work from highest risk to lowest, but cover all sections. Do not run any repo code, scripts, or install steps during triage — static inspection only.

### 1. Repo Metadata & Provenance
- Check `git remote -v`, `git log`, and the default branch — does it match what the user expected?
- Note fork/author/branding mismatches (e.g., a repo claiming to be `requests` but owned by a random account).
- Check the commit count and recency — a legitimate library with 1 commit is a red flag.
- Check for unexpected tags, branches, or force-pushed history.

### 2. Hidden Files & Vectors That Auto-Run
These files execute without the user explicitly running source code. Treat every one as a possible attack surface:
- `.vscode/tasks.json`, `.vscode/launch.json`, `.vscode/settings.json`, `.vscode/extensions.json`
- `.devcontainer/devcontainer.json`, `.devcontainer/`
- `.github/workflows/*`, `.gitlab-ci.yml`, `.circleci/config.yml`, other CI configs
- `pre-commit`, `.pre-commit-config.yaml`, `lefthook.yml`, `husky/` hooks
- `.git/hooks/*` (local, not tracked, but worth noting)
- `Makefile`, `justfile`, `Taskfile.yml`, `Rakefile`, `Gemfile`, `Dockerfile`, `docker-compose*.yml`, `docker-compose.yaml`
- Shell profiles/rc files committed to the repo (`.bashrc`, `.zshrc`, `profile`)
- `postinstall`, `preinstall`, `prepare`, `install` scripts in `package.json`

**What to look for in each:**
- Commands that `curl`/`wget` a URL and pipe to `sh`, `bash`, `zsh`, `python`, `ruby`, `node`, or `powershell`
- `base64 -d`, `eval`, `exec`, `spawn`, `child_process`, `os.system`, `subprocess`, `Runtime.getRuntime().exec`
- Downloading and executing a second-stage payload
- Task/command that runs a binary in the repo or fetches from a raw/unknown host

### 3. Obfuscation & Encoded Payloads
Obfuscation in application code is a strong signal. Flag any of:
- Long base64, hex, or URL-encoded blobs (`base64`, `xxd`, `fromCharCode`, `Buffer.from(..., 'base64')`, `atob`, `btoa`, `decode`, `unescape`)
- `eval`, `new Function`, `Function()`, `exec`, `system`, `spawn`, `child_process`, `os.system`, `subprocess.Popen`, `Runtime.getRuntime().exec`
- `Marshal.load`, `pickle.loads`, `yaml.load` (unsafe loaders), `unserialize`, `eval(` in config/deserialization paths
- String splitting/concatenation used to hide URLs, commands, or keywords
- Character-code arrays (`String.fromCharCode(...)`) that reconstruct a script
- Reversed strings, XOR loops, or custom "decrypt then run" helpers
- Minified/beautified code that doesn't match the repo's normal style (especially a single suspicious file)
- Payloads hidden inside non-code files — most commonly font files (`.ttf`, `.otf`, `.woff`, `.woff2`, `.eot`), but also `.svg`, `.pdf`, `.docx`, `.xlsx`, and images. Treat these as potential polyglots: inspect for embedded scripts, trailing bytes after the file's declared end, or `@font-face`/`script` content in SVG.

### 4. Suspicious Network Calls & Data Exfiltration
Map every outbound connection. The goal is to answer: *where does this repo send data?*
- Search for `http://`, `https://`, `wss://`, `ftp://`, raw IPs, and `socket`/`net`/`requests`/`fetch`/`axios` usage
- Separate legitimate dependencies (Google APIs, package registries, CDNs) from unknown or hardcoded endpoints
- Flag endpoints that receive environment variables, files, clipboard, credentials, tokens, browser history, or large blobs
- Flag POST/PUT to IP addresses or domains with no clear purpose
- Check for DNS exfiltration (`nslookup`, `dig`, `gethostbyname` on data-derived strings) and `sendBeacon`
- Check for hidden network use inside generated/hidden files, not just source

### 5. Secrets, Credentials & PII
- API keys (`sk-...`, `AKIA...`, `ghp_...`, `xoxb-...`, `AIza...`), private keys (`BEGIN RSA/OPENSSH/PRIVATE`), passwords, tokens
- `.env`, `.env.local`, `config/application.yml`, `secrets.yml`, `credentials` with real values
- Database connection strings with embedded passwords
- Email addresses, absolute filesystem paths, phone numbers, non-localhost IPs, internal hostnames
- Scan tracked files, untracked files, AND git history (`git log -p --all`) — secrets are often committed then removed

### 6. Dependency & Supply-Chain Anomalies
- Review `package.json`, `requirements.txt`, `Gemfile`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `pom.xml`, `build.gradle`
- Flag typosquatted or lookalike package names (`requets`, `react0`, `djangoo`)
- Flag packages installed from URLs, git refs, local paths, or non-standard registries
- Flag `postinstall`, `prepare`, `preinstall` in dependency manifests (they run on install)
- Flag unpinned or wildly versioned deps when the rest of the repo is pinned
- Check lockfiles for resolved URLs pointing away from the expected registry

### 7. Binaries, Artifacts & Unexpected File Types
- Find large binary files and files with unexpected extensions
- Flag committed `node_modules/`, `dist/`, `build/`, `.next/`, `__pycache__/`, `*.pyc`
- Flag executables, `.dll`, `.so`, `.exe`, `.wasm`, `.jar`, `.class`, or files with no extension that claim to be source
- Inspect images/documents that don't match their extension (`file <name>`)
- Scrutinize font files (`.ttf`, `.otf`, `.woff`, `.woff2`, `.eot`) and SVGs — they can carry injected scripts or polyglot payloads
- Treat any pre-built binary as opaque until proven otherwise — do not run it

### 8. Git Hygiene & History
- `.gitignore` covers deps, env files, build output, OS/IDE files, agent dirs (`.commandcode/`, `.claude/`, `.cursor/`, `.vscode/`, etc.)
- No secrets in history, no large accidental binaries
- No suspicious deleted-then-restored files in history

## Report Format

```
## Repo Triage Report — <repo name>

### Verdict: ✅ Safe | ⚠️ Suspicious | ❌ Dangerous

### What This Repo Does
<1-2 sentences>

### Outbound Connections
| Endpoint | Purpose | Risk |
|----------|---------|------|

### Files To Inspect Before Running
- <path> — <why>

### Obfuscation / Malicious Indicators
- <indicator> in <file:line> — <assessment>

### Secrets Found
- <location only, never the value>

### Recommended Next Steps
- <actionable, prioritized>
```

## Rules for the Auditor

- **Do not run anything** during triage — no `npm install`, no `bundle install`, no `pip install`, no `make`, no repo scripts
- **Never print a real secret** — report the file and line, not the value
- **Do not execute downloaded payloads** even to "see what they do"
- Prioritize by blast radius: auto-run vectors (`.vscode/tasks.json`, hooks, install scripts) > network calls > obfuscation > secrets
- Distinguish benign obfuscation (minified builds, compiled assets) from suspicious obfuscation (hidden command construction, encoded URLs)
- Report evidence, not vibes — every ❌ or ⚠️ must point to a file, line, or URL
- If something is genuinely ambiguous, say so and recommend manual inspection instead of guessing
