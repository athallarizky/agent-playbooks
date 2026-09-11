# Agent Playbooks

> A personal collection of reusable AI agent workflows. Each playbook is a SKILL.md document — a briefing for AI agents that encodes a repeatable task pattern.

## What's Inside

```
agent-playbooks/
  ai-guided-learning/SKILL.md          ← Research-first, phased learning workflow
  feature-workflow/SKILL.md            ← Universal, stack-agnostic feature development lifecycle
  security-audit/SKILL.md              ← Secrets, PII, and security checks before commit/publish
  git-workflow/SKILL.md                ← Conventional commits, pre-push audit, no auto-commit
  linkedin-writing/SKILL.md            ← LinkedIn post writing in Athalla's voice + style
  sprint-driven-development/SKILL.md   ← Structured sprint workflow for AI-agent-driven projects
  repo-triage/SKILL.md                 ← Fast malware/supply-chain scan for newly cloned repos
  concept-lab/SKILL.md                 ← Learn engineering concepts via small hands-on experiments
```

## How It Works

Every directory here contains a `SKILL.md` — a workflow recipe that any AI agent (Claude Code, Cursor, Copilot) can follow. Just activate the playbook and the agent knows exactly what to do.

## Why SKILL.md?

SKILL.md files act as **briefing documents** for agents. The agent reads the SKILL.md first, then applies the workflow to whatever context you provide. No need to re-explain patterns every session.

## Available Playbooks

| Playbook | What It Does |
|----------|-------------|
| `ai-guided-learning` | Learn a new tech by building a real project — research → architecture → phased build |
| `feature-workflow` | Universal 7-phase feature development lifecycle for onboarding and building features in any codebase |
| `security-audit` | Scan repos for secrets, PII, and security issues before committing or open-sourcing |
| `git-workflow` | Enforce conventional commits, pre-push audit checklist, and no auto-commit/push |
| `linkedin-writing` | Write LinkedIn posts in Athalla's conversational Indo-English tech storytelling style |
| `sprint-driven-development` | Structured sprint workflow: discovery → planning → phased execution → retro, with full traceability and LLM delegation support |
| `repo-triage` | Fast static scan of a newly cloned repo for malware, obfuscation, malicious scripts, network exfiltration, and supply-chain risks |
| `concept-lab` | Turn engineering concepts into small learning projects — understand → analogy → build → experiment → compare alternatives → break it → reflect |
| `handbook-workflow` | Centralized documentation management — co-locate sprint docs/findings in projects, zero-leakage symlink, and version control in engineering-handbook |

More coming soon.

