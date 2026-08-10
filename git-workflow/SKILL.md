# Git Workflow

> Enforce consistent git conventions: conventional commits, pre-push auditing, and no auto-commits.

## Trigger
The user will say things like:
- "Commit this"
- "Push this"
- "Is this ready to commit?"
- "Before I push..."

## Rules for AI Agents

### NEVER Auto-Commit or Auto-Push
- Stage changes with `git add` only when the user explicitly asks
- After staging, **stop and show the diff to the user** — let them review before committing
- After committing, **stop and ask** before pushing
- Never push without explicit user instruction

### Conventional Commits
All commit messages must follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <description>

<body> (optional)
```

Types:
- `feat:` — new feature
- `fix:` — bug fix
- `docs:` — documentation only
- `refactor:` — code change that neither fixes a bug nor adds a feature
- `chore:` — maintenance, dependencies, build, CI
- `style:` — formatting, semicolons, whitespace (not code logic)
- `test:` — adding or updating tests
- `perf:` — performance improvement

Examples:
```
feat: add Researcher agent with 6 analysis tools
fix: prevent grep regex errors in searchCode tool
docs: add findings on AI governance and guardrails
refactor: centralized agent config with per-agent model routing
```

**Strict rule:** Never add `Co-authored-by`, `Assisted-by`, `Signed-off-by`, or any attribution trailer. Commits are the user's work.

### Signing Commits (User preference)
User prefers signed/verified commits (GPG or SSH signing). Ask before committing if signing is configured.

### Pre-Push Audit Checklist
Before every push, verify:

1. **Diff review** — show `git diff origin/main` or `git diff --cached`, let user scan it
2. **`.gitignore` check** — verify these are covered:
   - Dependencies: `node_modules/`, `__pycache__/`, `*.pyc`
   - Build artifacts: `dist/`, `build/`, `.next/`
   - Environment: `.env` (track `.env.example` instead)
   - OS/IDE: `.DS_Store`, `thumbs.db`, `.vscode/`, `.idea/`
   - Logs: `*.log`, `*.cache`, `*.tmp`
   - Project-specific output/generated directories
3. **Secrets check** — scan `git diff` for API keys, tokens, passwords, PII
4. **Confirm** — ask user "Ready to push?" before executing
