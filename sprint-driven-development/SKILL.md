# Sprint-Driven Development

> Run a software project with an AI agent — structured sprint workflow from discovery to production, with full traceability and handoff support.

## Trigger
The user will say things like:
- "Let's start a new project with sprint-driven development"
- "Set up a sprint for [feature/project]"
- "Plan the next phase"
- "Write the AGENTS.md for delegation"
- "Start Phase-N"

## The Workflow

### Phase 0 — Discovery & Exploration

**Goal:** Understand the problem, existing codebase, and what needs building.

1. Read the PRD or project brief
2. Explore existing code — check what's already built, what's missing
3. Run existing tools — clone repos, build binaries, test with real data
4. Ask clarifying questions — identify gaps, ambiguities, and decisions to make
5. Study real output — run scrapers/APIs to understand actual data shapes

**Questions to ask during Phase 0:**
- Are there existing repos that need to be cloned? Where?
- What tech stack? Is it decided or needs discussion?
- What's the project structure (monorepo, separate repos)?
- What's the deployment target?
- What data does the system produce/consume?
- What's the MVP scope vs future enhancements?

**Deliverable:** `docs/sprint-N/reports/phase-0-report.md` containing manual run instructions, test results with real data, data structure analysis, key findings, and decisions made.

### Sprint Planning — Document Structure

Every sprint lives in `docs/sprint-N/` and **must** include these core files:

```
docs/sprint-N/
  plan.md              — Sprint goal, scope, decisions, phasing
  tasks.md             — Task breakdown + difficulty + dependencies + status
  final-report.md      — Final sprint summary + handoff
  AGENTS.md            — Delegation guide (for handing off to another LLM)
  reports/
    phase-0-report.md  — Discovery findings
    phase-1-report.md  — Per-phase reports
    ...
  resources/
    architecture.md    — Tech stack decisions with pros/cons
    data-design.md     — Data models, schemas, API contracts
    ux-flow.md         — Screen designs, user journey (if UI)
    api-contract.md    — REST/API endpoints, request/response shapes
  rca/                 — Root-cause analyses for gnarly bugs
```

### Phase Execution (Phase 1 → Phase N)

Each phase follows this loop:

1. **Build** the code
2. **Test** it — run, verify output
3. **Write a phase report** (`reports/phase-N-report.md`)
4. **Update `tasks.md`** — mark completed + add findings
5. **Ask for commit confirmation**
6. **Commit + push**

When a non-trivial bug burns more than ~2 debug cycles, write an RCA at `docs/sprint-N/rca/YYYY-MM-DD-<slug>.md`.

### After Sprint — Retro

Create `docs/ideas/future-enhancements.md` for backlog items and post-MVP ideas.

---

## Document Templates

### `plan.md`

```markdown
# Sprint-N Plan — <Project Name>

> Status: 🟡 Planning | Created: YYYY-MM-DD

## Context
<What already exists, what the previous sprint delivered, what this sprint builds on.>

## 1. Sprint goal
<One sentence describing what this sprint delivers.>

## 2. Scope
**In scope:**
- ...
**Out of scope:**
- ...

## 3. Key decisions
| Decision | Rationale |
|----------|-----------|

## 4. Phasing
- **Phase 0 — Discovery:** ...
- **Phase 1 — ...:** ...
```

### `tasks.md`

```markdown
# Task Breakdown — <Project Name>

> Status legend: ⬜ pending | 🔵 in_progress | ✅ completed | ❌ blocked

## Phase 1 — <Phase Name>

| ID   | Task                | Difficulty | Dependencies | Status |
|------|---------------------|------------|-------------|--------|
| 1.1  | <Task description>  | Easy       | —           | ⬜     |
| 1.2  | <Task description>  | Medium     | 1.1         | ⬜     |

### Service Summary
- **Runtime:** <Python/Node/Go>
- **Files:** `src/a.py`, `src/b.py`
- **Key output:** <what was produced>

> 📄 Full report: [`reports/phase-1-report.md`](./reports/phase-1-report.md)
```

**Rules for tasks.md:**
- Every task has an ID, difficulty (Easy/Medium/Hard), dependencies, and status
- Only ONE task `in_progress` at a time
- Mark completed only when tested AND working
- Include a dependency graph showing task ordering
- After each phase completes, add a "Service Summary" with key facts

**Difficulty levels:**

| Level  | Meaning                                    | Example                                  |
|--------|--------------------------------------------|------------------------------------------|
| Easy   | ≤30 min, no unknowns, mostly wiring        | "Add endpoint", "Create file structure"  |
| Medium | 1-2h, some design decisions, integration   | "Build wrapper", "Normalize data"        |
| Hard   | 3h+, complex logic, multiple edge cases    | "Feature extraction", "SSE streaming"    |

### `architecture.md`

```markdown
# Architecture — <Project Name>

## 1. Project Structure
<directory tree>

## 2. Tech Stack Decisions
| Service    | Language | Key Libraries | Why |
|-----------|----------|--------------|-----|

## 3. Why NOT Alternatives
| Rejected       | Reason |
|---------------|--------|

## 4. Service Boundaries
### Service-A
- **Input:** <what it receives>
- **Output:** <what it produces>
- **Does NOT:** <responsibilities it avoids>
```

**Rules:** Always explain WHY, include rejected alternatives, document service boundaries. Keep it concise — this is agent context, not a novel.

### `data-design.md`

```markdown
# Data Design — <Project Name>

## 1. Input Data Format
| Field   | Type | Notes |
|---------|------|-------|

## 2. Data Pipeline
Raw Data → [Stage 1] → [Stage 2] → Output

## 3. Output Schema
```json
{ "field": "value" }
```

## 4. Storage Schema
| Field | Type | Indexed | Notes |
|-------|------|---------|-------|
```

### `ux-flow.md` (UI Projects Only)

```markdown
# UX Flow — <Project Name>

## 1. Navigation
Home (/) → Feature (/feature) → Settings (/settings)

## 2. Screen — <Screen Name>
<ASCII wireframe>

**Behavior:**
- <What happens on user action>
- <API calls made>
- <Error/empty states>
```

### `AGENTS.md` — Delegation Guide

This is the most critical document. It's a self-contained implementation guide for handing off to another LLM agent.

```markdown
# AGENTS.md — <Sprint Name> Implementation Guide

> **For:** Any LLM agent implementing <project>.
> **Context:** <what already exists, what NOT to rebuild>

## 0. What Already Exists (Do NOT Rebuild)
<directory tree + ready-to-use endpoints>

## 1. Tech Stack (EXACT — Do Not Change)
| Layer     | Technology |

## 2. File Structure to Create
<directory tree of what the agent must build>

## 3. Implementation Order
<numbered list with code snippets where critical>

## 4. API Contracts
```typescript
interface RequestType { ... }
interface ResponseType { ... }
```

## 5. Reference Files (Code You Can Copy From)
| Source        | What to Copy |

## 6. Deviations from Reference
| Reference    | This Project | Why |

## 7. Implementation Checklist
- [ ] Task 1
- [ ] Task 2

## 8. How to Run
```bash
<commands>
```

## 9. Done Criteria
- [ ] <Checklist of what "done" looks like>
```

**Rules for AGENTS.md:**
- Include EXACT code snippets for critical logic
- List reference files the agent can copy-paste from
- Include a numbered checklist — agents follow checklists better than prose
- Mention what NOT to do (deviations from reference)
- Include "Done Criteria" so the agent can self-validate

### `final-report.md`

```markdown
# Sprint N — Final Report

> Status: ✅ Delivered | YYYY-MM-DD
> Audience: sprint-(N+1) context. Read this + AGENTS.md before starting sprint-(N+1).

## 1. Sprint goal & outcome
<What we set out to build and what was delivered.>

## 2. Final structure
<directory tree of what was built>

## 3. Key deliverables
| Item | Count | Notes |

## 4. Key decisions
| Decision | Rationale |

## 5. Phase summary
| Phase | Tasks | Status |

## 6. Verification
- <check>

## 7. How to run
```bash
<commands>
```

## 8. Sprint-(N+1) handoff
<What the next sprint needs to know — integration points, unresolved items, data dependencies.>
```

### `reports/phase-N-report.md` — Per-Phase Report

```markdown
# Phase N Report — <Phase Name>

> Completed: YYYY-MM-DD

## 1. How to Run
```bash
<exact commands>
```

## 2. Test Results
| Metric | Value |

## 3. Key Decisions
| Decision | Reason |

## 4. Reference Files
| File | Purpose |
```

### `rca/YYYY-MM-DD-<slug>.md` — Root Cause Analysis

Write one whenever a non-trivial bug burns more than ~2 debug cycles or anything breaks in production. File under the current sprint.

```markdown
# RCA — <one-line description>

> **Date:** YYYY-MM-DD · **Severity:** Low/Med/High · **Component:** <where>
> **Status:** ✅ Resolved

## 1. Summary
<2-3 sentences: what happened + the ACTUAL root cause, up top.>

## 2. Impact
<who/what affected, data or prod impact, duration>

## 3. Symptoms
| Signal | Value |

## 4. Timeline
| # | Attempt | Outcome | Verdict |
|---|---------|---------|---------|
| 1 | <what we tried> | <result> | real fix / red herring / the cause |

## 5. Root cause
<The actual cause + evidence (file/line, sizes, logs).>

## 6. The fix
```diff
- <before>
+ <after>
```

## 7. Lessons & action items
- [ ] <preventive change / process tweak>
```

**Rules for RCA:**
- Lead with the root cause in the Summary — don't bury it
- Tag every Timeline row (`real fix` / `red herring` / `the cause`) — the red herrings are the most valuable part
- Capture the symptom signature so the same class of bug is recognizable next time
- Write it the same day, while the debug trail is fresh

---

## Communication Rules

### Do
- Ask before committing — "Confirm and I'll commit"
- Ask before design decisions — "Here's my recommendation, thoughts?"
- Break down tasks before building
- Test immediately after building — run the code, show the output
- Update docs after every phase — report + tasks.md update
- Document findings, not just results — what surprised you, what failed
- Write an RCA for gnarly bugs

### Don't
- Never commit without confirmation
- Never assume a library is available — check first
- Never skip the "study real output" step in Phase 0
- Never leave broken tasks marked as ✅
- Never skip writing the phase report
- **Never keep blind-guessing on a stuck bug** — after ~2 failed attempts, stop and read the actual docs/issues, then write an RCA

---

## Startup Checklist (New Project)

1. [ ] Create the project structure
2. [ ] Write/confirm the PRD
3. [ ] Run Phase 0 — clone deps, test tools, study real output
4. [ ] Create `docs/sprint-1/` with all planning docs
5. [ ] Break tasks into phases with difficulty + dependencies
6. [ ] Start Phase 1 — build → test → report → commit
7. [ ] After each phase, update `tasks.md` and write `reports/phase-N-report.md`
8. [ ] When delegating, create `AGENTS.md` with checklist + code snippets
9. [ ] After sprint, write `docs/ideas/future-enhancements.md` for backlog
