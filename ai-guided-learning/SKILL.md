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
