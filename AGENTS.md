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
  linkedin-writing/
    SKILL.md        ← playbook: LinkedIn post writing style + voice
    samples/        ← seed material for AI calibration
  sprint-driven-development/
    SKILL.md        ← playbook: structured sprint workflow with delegation
  repo-triage/
    SKILL.md        ← playbook: fast malware/supply-chain scan of cloned repos
```

## Rules

- When a playbook is activated, follow its workflow completely
- Do NOT skip steps or improvise unless the user asks
- **Commit rules:** Never add `Co-authored-by` or agent attribution trailers. Commits are the user's work.
- **Never auto-commit or auto-push.** Stage, show diff, wait for user instruction.

### Saving Playbook Rules Globally

When the user says something like:
- "Read the git-workflow and security-audit playbooks, then save on your core memory"
- "Apply these playbook rules globally"

It means the user wants those playbook rules to apply to **every session, not just this one**. Extract the rules from the playbook(s) and save them to the agent's global/core configuration file so they persist across all future sessions.

**Per-agent config file locations:**

| Agent | Global Config File |
|-------|-------------------|
| Claude Code | `~/.claude/CLAUDE.md` |
| Gemini CLI | `~/.gemini/GEMINI.md` |
| Codex CLI | `AGENTS.md` (project-level, no true global) |
| Cursor | `.cursorrules` or `.cursor/rules/` (project-level, no true global) |
| Windsurf | `.windsurfrules` or `.windsurf/rules/` (project-level, no true global) |
| GitHub Copilot | `.github/copilot-instructions.md` (project-level, no true global) |

**What to do:**
1. Read the playbook(s) the user mentioned
2. Extract the persistent rules (e.g., commit conventions, pre-push audit, secrets check) — not the step-by-step workflows, but the standing rules that should always apply
3. Write them into the appropriate global config file in a clearly labeled section like `<!-- Agent Playbooks — Global Rules -->`
4. If the file already exists, append or merge — don't overwrite existing content
5. Confirm to the user which rules were saved and to which file

**Fallback:** If the agent doesn't have a defined global config file name, assume it reads `AGENTS.md` from its own root directory (e.g., `~/.augment/AGENTS.md`, `~/.opencode/AGENTS.md`).

**Skill-based agents:** If the agent uses a skills directory for global rules (e.g., `~/.commandcode/skills/`), copy the entire playbook content into a file named after the playbook (e.g., `~/.commandcode/skills/security-audit/SKILL.md`, `~/.commandcode/skills/git-workflow/SKILL.md`). This preserves the playbook as a reusable skill rather than flattening rules into a single config file.
