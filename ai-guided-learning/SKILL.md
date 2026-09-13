# AI-Guided Learning

> When the user wants to learn a new technology by building something real.

## Trigger
The user will say things like:
- "I want to learn [X] by building [Y]"
- "Guide me through building [Y] using [X]"
- "Teach me [X] with a hands-on project"

## The Workflow

### Step 1: Research the Technology
- Research the current state of the technology (latest version, ecosystem, best practices)
- If multiple approaches exist, pick the best one for the user's goal and explain why
- Flag any known deprecations, breaking changes, or gotchas in the current version
- Share findings concisely before proceeding

### Step 2: Architecture Design
- Design the project architecture collaboratively with the user
- Write `docs/plan.md` containing:
  - **What we're building** — 1-2 sentence description
  - **Concepts I'll learn** — glossary-style table
  - **Architecture diagram** — ASCII art
  - **Project structure** — full file tree
  - **Data flow / state schema** — if applicable
  - **Phase roadmap** — numbered list of phases

### Step 3: Phase Breakdown
Break the build into sequential phases. Each phase gets `docs/phase-N-name.md`:

**Every phase file must include:**
- **Goal:** What we accomplish in this phase
- **Concepts:** New concepts I'm learning
- **Complete code:** Every file to create, copy-pasteable with inline comments
- **Explain:** Why we wrote it this way (1-2 sentences per block)
- **Test:** How to verify this phase works before moving on
- **Dependencies:** What from previous phases this depends on

**Rules:**
- The user writes all code themselves — do NOT implement, only guide
- Import paths must match the actual installed packages (check node_modules)
- If an API is deprecated, state the replacement
- Show exact commands to run/test, not abstract descriptions
- No gaps or guesswork — every line of code must be provided

### Step 4: Iterate
- User codes one phase at a time
- User shows errors → you diagnose and explain the fix
- Only move to the next phase when the current one compiles and works
- Each phase starts from the previous phase's working state

---

## Playbook Composability & Collaboration (Dynamic Workflows)

`ai-guided-learning` is modular and designed to dynamically collaborate with other playbooks in `agent-playbooks`. Depending on project scale, complexity, and user intent, the agent can blend complementary workflows:

### 1. Pairing with `concept-lab` (Deep-Dive Concept Experiments)
- **When to use:** When a phase introduces an abstract, tricky, or architectural concept (e.g., token exchange, distributed locking, event streaming, custom memory allocators) that is difficult to grasp directly inside the larger application.
- **Integration workflow:**
  1. Pause the main learning build temporarily.
  2. Launch a mini `concept-lab` experiment: *Understand → Analogy → Mini-build → Experiment → Compare alternatives → Break it → Reflect*.
  3. Solidify the mental model in an isolated scratch/lab environment.
  4. Return to `ai-guided-learning` and guide the user to implement the production pattern in the main project.

### 2. Pairing with `sprint-driven-development` (Scaled Learning Projects)
- **When to use:** When the learning project grows beyond a single weekend prototype into a multi-milestone system requiring task tracking, phase reports, architectural records, or delegation across multiple AI agents / sessions.
- **Integration workflow:**
  - Elevate the phase structure into `docs/sprint-N/` (`plan.md`, `tasks.md`, `reports/phase-N-report.md`, `resources/architecture.md`).
  - Utilize `sprint-driven-development` for discovery (Phase 0), tracking, and post-phase retros.
  - Maintain the core pedagogical rule: the user drives code implementation while the agent acts as architect, technical mentor, and sprint coordinator.

### 3. Pairing with Quality & Hygiene Playbooks
- **`git-workflow`:** Enforce at every phase checkpoint — write conventional commits, review diffs, and never auto-commit or auto-push.
- **`security-audit`:** Run security checks before committing code (verifying `.env.example`, absence of leaked API keys, tokens, or PII).
- **`handbook-workflow`:** Co-locate sprint docs and export final lessons learned, architecture patterns, or cheat sheets to `engineering-handbook`.

### 4. Dynamic Protocol for Future / Custom Playbooks
- **Contextual Detection:** When the user mentions or requests another playbook (e.g., testing strategies, benchmarking/profiling, deployment pipelines), inspect its `SKILL.md` and dynamically insert its stages as sub-routines within the current learning phase.
- **Non-Destructive Inlining:** Combining playbooks must never override the user's primary goal (learning hands-on). Keep guidance clear, incremental, and code fully copy-pasteable with thorough explanations.

