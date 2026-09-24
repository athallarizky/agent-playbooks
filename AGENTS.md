# Agent Playbooks — Agent Briefing

> This file tells AI agents what this repository is and how to use the playbooks inside.

## What This Repo Is

A personal collection of reusable SKILL.md playbooks. Each playbook encodes a repeatable task workflow that any AI agent can execute.

## How to Use a Playbook

When the user says something like:
- "Use the ai-guided-learning playbook"
- "Guide me through learning [X]"

Read the corresponding `SKILL.md` file and follow its workflow exactly.

## Combining Playbooks with External Skills

Playbooks run standalone by default. External skills (context7, superpowers, etc.) are used **only when explicitly mentioned** by the user.

Example request:

> "Buatkan materi (concept-lab), brainstorm pakai skill superpowers, context7 untuk dokumentasi terbaru"

Means:

1. Run the `concept-lab` playbook as the **primary workflow**
2. At the ideation/design step, apply superpowers' `brainstorming` skill
3. When technology selection or current documentation is needed, query context7

**Resolution order for a mentioned external skill:**

1. Native registration in the current harness (Skill tool, MCP tools) — use it directly
2. Otherwise read the skill file from disk and follow it, e.g. superpowers: `~/.claude/plugins/cache/claude-plugins-official/superpowers/*/skills/<name>/SKILL.md`
3. If it cannot be resolved, say so and continue the playbook without it

Do not auto-invoke external skills that the user did not mention.

## Structure

```
agent-playbooks/
  README.md         ← human-readable overview
  AGENTS.md         ← this file (agent briefing)
  ai-guided-learning/
    SKILL.md        ← playbook: phased learning workflow
  feature-workflow/
    SKILL.md        ← playbook: universal 7-phase feature development lifecycle
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
  concept-lab/
    SKILL.md        ← playbook: learn concepts via small hands-on experiment projects
  handbook-workflow/
    SKILL.md        ← playbook: centralized documentation management for engineering-handbook
    scripts/        ← portable auto-linking scripts
  pasted-content-cleanup/
    SKILL.md        ← playbook: clean up, format, and de-noise pasted web clipper markdown
```


## Rules

- When a playbook is activated, follow its workflow completely
- Do NOT skip steps or improvise unless the user asks
- **Composability:** Playbooks can be combined dynamically when relevant (e.g., nesting `concept-lab` deep-dives or `sprint-driven-development` tracking inside `ai-guided-learning`).
- **Commit rules:** Never add `Co-authored-by` or agent attribution trailers. Commits are the user's work.
- **Never auto-commit or auto-push.** Stage, show diff, wait for user instruction.

### Global Dispatch (use playbooks from any harness)

To make playbooks invokable from any harness **without symlinks or copies**, add this line to that harness's global config file (see locations table below):

> Personal playbooks live in `~/development/personal/agent-playbooks/<name>/SKILL.md`. When the user mentions a playbook by name (e.g. `/concept-lab` or "use the concept-lab playbook"), read that `SKILL.md` and follow it exactly.

The repo stays the single source of truth — every harness dispatches to it by reference.

Harnesses with a native skills directory (e.g. Claude Code's `~/.claude/skills/`) can optionally symlink playbook dirs there for native `/name` invocation instead.

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
