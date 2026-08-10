# Security Audit

> Audit code, configuration, and documentation for secrets, PII, and sensitive data before committing or open-sourcing.

## Trigger
The user will say things like:
- "Audit this repo for security"
- "Check for secrets before I push"
- "Is this safe to open-source?"
- "Run a security audit"

## What to Check

### Secrets & Credentials
- API keys (`sk-...`, `AKIA...`, `ghp_...`, `xoxb-...`, etc.)
- Passwords and tokens (hardcoded, in config files, in comments)
- `.env` files or equivalent with real values
- Database connection strings with credentials

### Personal Identifiable Information (PII)
- Email addresses (`user@domain.com`)
- Absolute filesystem paths (`/Users/name/...`, `/home/name/...`)
- Real names (when not public identity)
- IP addresses (except localhost)
- Phone numbers
- Internal hostnames revealing infrastructure

### Build Artifacts
- `node_modules/`, `dist/`, `build/`, `.next/` — should be gitignored
- `*.log` files
- `.DS_Store`, `thumbs.db`
- Generated output directories

### Git Hygiene
- `.gitignore` exists and covers at minimum:
  - `node_modules/`, `dist/`, `build/`, `.next/`, `__pycache__/`, `*.pyc`
  - `.env` (never track real env files — use `.env.example` instead)
  - `*.log`, `*.cache`, `*.tmp`
  - `.DS_Store`, `thumbs.db`
  - OS-generated files and IDE directories (`.vscode/`, `.idea/`)
  - Output/generated directories specific to the project
- No secrets in git history (check `git log -p | grep` for common patterns)
- No large binary files accidentally tracked
- If the project has a `.env.example`, verify it contains placeholder values only

## Audit Report Format

After checking, produce a structured report:

```
## Security Audit Report

### ✅ Passed
- .gitignore covers node_modules, dist, .env
- No hardcoded API keys found
- No absolute paths in tracked files

### ⚠️ Warnings
- .env.example references OPENAI_API_KEY — ensure no real value leaked
- package-lock.json is tracked (normal, but verify no tokens inside)

### ❌ Issues Found
(None — ready to push/publish)
```

## Rules for the Auditor
- Check both tracked AND untracked files
- Scan git history for any secrets that were committed then removed
- If a real secret is found, DO NOT output it — say "FOUND: API key in src/config.ts line 4" not the actual key
- Public information is fine (GitHub URLs, public docs, library names)
