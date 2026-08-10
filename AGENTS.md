# Agent Playbooks — Agent Briefing

> This file tells AI agents what this repository is and how to use the playbooks inside.

## What This Repo Is

A personal collection of reusable SKILL.md playbooks. Each playbook encodes a repeatable task workflow that any AI agent can execute.

## How to Use a Playbook

When the user says something like:
- "Use the ai-guided-learning playbook"
- "Guide me through learning [X]"

Read the corresponding `SKILL.md` file and follow its workflow exactly.

## Structure

```
agent-playbooks/
  README.md         ← human-readable overview
  AGENTS.md         ← this file (agent briefing)
  ai-guided-learning/
    SKILL.md        ← playbook: phased learning workflow
  security-audit/
    SKILL.md        ← playbook: secrets, PII, and security checks
  git-workflow/
    SKILL.md        ← playbook: conventional commits, pre-push audit
```

## Rules

- When a playbook is activated, follow its workflow completely
- Do NOT skip steps or improvise unless the user asks
- **Commit rules:** Never add `Co-authored-by` or agent attribution trailers. Commits are the user's work.
- **Never auto-commit or auto-push.** Stage, show diff, wait for user instruction.
