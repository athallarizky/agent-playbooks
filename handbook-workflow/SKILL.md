---
name: handbook-workflow
description: Centralized documentation management workflow for linking, writing, curating, and archiving project documentation and architectural findings into the central engineering-handbook repository.
---

# Handbook Workflow

## Purpose

Maintain a single, centralized knowledge base (**`engineering-handbook`**) for all project documentation, sprint plans, architecture decision records (ADR), and technical findings across all personal and work repositories.

The goal is to answer:

> "How can I document my architectural discoveries and sprint progress inside my project workspace without cluttering the project's production repository, while keeping all findings organized and version-controlled in one central handbook?"

---

## Core Principles

### 1. 1-to-1 Co-location
Documentation for every project lives inside:
```text
engineering-handbook/projects/<project-name>/
```
Never scatter documentation into arbitrary global directories. Findings stay co-located with the project context where they were discovered.

### 2. Zero Leakage Rule
The project repository's `.gitignore` **MUST ALWAYS** contain:
```gitignore
# Planning & learning docs — private, not part of the submission/production repo
/docs/
```
Documentation, sprint notes, and internal architecture findings must **never** be committed or pushed to the product's primary code repository.

### 3. Transparent Symlink Architecture
On your local machine, the project's `docs/` directory is a symbolic link pointing to the central handbook:
```text
~/development/personal/<project-name>/docs ──▶ ~/development/personal/engineering-handbook/projects/<project-name>
```
This gives the developer the best of both worlds:
- You read and edit documentation directly inside your project's IDE workspace.
- The project repository's git ignores `docs/` completely.
- The central `engineering-handbook` repository tracks, versions, and backs up all changes to GitHub.

### 4. Curated Master Indexing
The root `README.md` of `engineering-handbook` serves as the **Curated Thematic Index**:
- Physical storage is grouped by project (`projects/docsy/`, `projects/phantom-token-lab/`).
- Logical discovery is organized by topic (*Database & Indexing*, *Auth & Security*, *Caching*, *Architecture*).

---

## Workflow: Connecting a New Project to Handbook

Whenever you or an AI agent creates or attaches a new project to the handbook, follow this 4-step workflow:

### Step 1: Ensure Directory in Handbook
Create the target project directory inside `engineering-handbook`:
```bash
mkdir -p ~/development/personal/engineering-handbook/projects/<project-name>
```

### Step 2: Ensure `.gitignore` in Target Project
Ensure the project's `.gitignore` contains `/docs/`:
```bash
if ! grep -q "^/docs/" ~/development/personal/<project-name>/.gitignore 2>/dev/null; then
    echo -e "\n# Planning & learning docs — private, not part of the submission repo\n/docs/" >> ~/development/personal/<project-name>/.gitignore
fi
```

### Step 3: Establish Symlink
- If the project already has an existing `docs/` folder (with files), move its contents to the handbook first:
  ```bash
  mv ~/development/personal/<project-name>/docs/* ~/development/personal/engineering-handbook/projects/<project-name>/ 2>/dev/null
  rm -rf ~/development/personal/<project-name>/docs
  ```
- Create the symlink:
  ```bash
  ln -s ~/development/personal/engineering-handbook/projects/<project-name> ~/development/personal/<project-name>/docs
  ```

### Step 4: Register in Central README
Add the new project to `engineering-handbook/README.md` under the Projects table, and index any major findings under the Master Topic Index.

---

## Automated Helper Script

The handbook includes an automated helper script at `scripts/link-project.sh`:

```bash
# Inside engineering-handbook:
./scripts/link-project.sh <project-name>
```
This script executes Steps 1 through 4 in under one second.

---

## Daily Documentation Workflow

### Writing & Editing Docs
- Open your project repository in your IDE as usual.
- Write, edit, and create files inside `docs/` (e.g. `docs/sprint-1/findings/auth.md`).
- Because of the symlink, your changes are immediately reflected in `engineering-handbook/projects/<project-name>/`.

### Committing Documentation
- Project repo git remains clean: `git status` inside the project will never show `docs/` changes.
- To commit docs, navigate to `engineering-handbook`:
  ```bash
  cd ~/development/personal/engineering-handbook
  git status
  git add projects/<project-name>/
  git commit -m "docs(<project-name>): add sprint findings and architecture notes"
  git push origin main
  ```

---

## Handbook Repository Structure

```text
engineering-handbook/
├── README.md                          # Master Directory & Thematic Topic Index
├── .gitignore                         # OS artifacts & agent directory hygiene
├── scripts/
│   └── link-project.sh                # 1-second auto-linking script
└── projects/
    ├── docsy/                         # Document Management System docs
    │   ├── sprint-1/
    │   ├── sprint-2/
    │   └── sprint-3/
    ├── phantom-token-lab/             # Concept Lab docs
    ├── postgres-indexing-lab/         # Concept Lab docs
    └── redis-lab/                     # Concept Lab docs
```

---

## Rules for AI Agents

When instructed to *"attach this project to handbook"* or *"use handbook-workflow"*:
1. **Never commit docs to the project repository.** Always verify `/docs/` is ignored before staging project files.
2. **Always link via `engineering-handbook/projects/<project-name>`.**
3. **Follow Git Workflow Rules** when committing to `engineering-handbook`:
   - Never auto-commit or auto-push without explicit user instruction.
   - Use conventional commits (`docs(<project>): ...`).
   - No `Co-authored-by` or agent attribution trailers.
