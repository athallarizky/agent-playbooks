---
name: handbook-workflow
description: Centralized documentation management workflow for linking, writing, curating, and archiving project documentation and architectural findings into the central engineering-handbook repository without machine-specific hardcoded paths.
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
<handbook-root>/projects/<project-name>/
```
Never scatter documentation into arbitrary global directories. Findings stay co-located with the project context where they were discovered.

### 2. Zero Leakage Rule
The project repository's `.gitignore` **MUST ALWAYS** contain:
```gitignore
# Planning & learning docs — private, synced to engineering-handbook
/docs
/docs/
```
Both the bare `/docs` (to match symlinks) and `/docs/` (to match directories) are ignored so documentation, sprint notes, and internal architecture findings **never** get committed or pushed to the product's primary code repository.

### 3. Transparent Relative Symlink Architecture
On your local machine, the project's `docs` is a **relative symbolic link** pointing to the central handbook:
```text
<workspace-root>/<project-name>/docs ──▶ ../engineering-handbook/projects/<project-name>
```
Using **relative symlinks** ensures portability: if the parent workspace directory is moved, cloned to another machine, or mounted in a container, the symlinks remain completely valid.

### 4. Curated Master Indexing
The root `README.md` of `engineering-handbook` serves as the **Curated Thematic Index**:
- Physical storage is grouped by project (`projects/<project-a>/`, `projects/<project-b>/`).
- Logical discovery is organized by topic (*Database & Indexing*, *Auth & Security*, *Caching*, *Architecture*).
- All internal markdown links use repository-relative paths (`projects/<project>/...`), making them fully clickable on GitHub and across any operating system.

---

## Path Discovery Rules for AI Agents

When an AI agent executes this workflow, it must **never assume hardcoded filesystem paths** (such as `/Users/...` or `/home/...`). Instead, use this resolution hierarchy:

1. **Environment Variable:** Check if `$HANDBOOK_DIR` is set in the shell environment.
2. **Sibling Directory:** Check if `../engineering-handbook` exists relative to the current project root.
3. **Workspace Hierarchy:** Search for `engineering-handbook` in the parent directory tree.
4. **Fallback:** If cannot be resolved automatically, prompt the user for the handbook location.

---

## Workflow: Connecting a New Project to Handbook

Whenever you or an AI agent creates or attaches a new project to the handbook, follow this 4-step workflow:

### Step 1: Ensure Directory in Handbook
Resolve the handbook path (`$HANDBOOK_DIR`), then create the project folder:
```bash
mkdir -p "$HANDBOOK_DIR/projects/<project-name>"
```

### Step 2: Ensure `.gitignore` in Target Project
Ensure both `/docs` and `/docs/` are in the target project's `.gitignore`:
```bash
GITIGNORE="<project-root>/.gitignore"
if ! grep -Eq "^/?docs($|/)" "$GITIGNORE" 2>/dev/null; then
    echo -e "\n# Planning & learning docs — private, synced to engineering-handbook\n/docs\n/docs/" >> "$GITIGNORE"
fi
```

### Step 3: Establish Relative Symlink
- If the project already has an existing `docs/` folder (with files), copy its contents to the handbook first, then remove the folder:
  ```bash
  cp -rn "<project-root>/docs/"* "$HANDBOOK_DIR/projects/<project-name>/" 2>/dev/null || true
  rm -rf "<project-root>/docs"
  ```
- Calculate the relative path from `<project-root>` to `$HANDBOOK_DIR/projects/<project-name>`:
  ```bash
  # When both are sibling directories under the same workspace:
  ln -s "../engineering-handbook/projects/<project-name>" "<project-root>/docs"
  ```

### Step 4: Register in Central README
Add the new project to `<handbook-root>/README.md` under the Projects table, and index any major findings under the Master Topic Index using clean relative markdown links.

---

## Automated Helper Script

The handbook includes an automated helper script at `scripts/link-project.sh`:

```bash
# Inside engineering-handbook:
./scripts/link-project.sh <project-name-or-path>

# Examples (all work interchangeably):
./scripts/link-project.sh rent-house-ai
./scripts/link-project.sh ../rent-house-ai
./scripts/link-project.sh /path/to/any/project
```
This script dynamically calculates relative paths, manages `.gitignore`, and establishes the symlink.

---

## Daily Documentation Workflow

### Writing & Editing Docs
- Open your project repository in your IDE as usual.
- Write, edit, and create files inside `docs/` (e.g. `docs/sprint-1/findings/auth.md`).
- Because of the symlink, your changes are immediately reflected in `<handbook-root>/projects/<project-name>/`.

### Committing Documentation
- Project repo git remains clean: `git status` inside the project will never show `docs` changes.
- To commit docs, navigate to the handbook directory:
  ```bash
  cd "$HANDBOOK_DIR"
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
│   └── link-project.sh                # Portable auto-linking script
└── projects/
    ├── <project-a>/
    │   ├── sprint-1/
    │   ├── sprint-2/
    │   └── ...
    ├── <project-b>/
    │   ├── plan.md
    │   └── findings/
    └── <project-c>/
        └── ...
```

---

## Rules for AI Agents

When instructed to *"attach this project to handbook"* or *"use handbook-workflow"*:
1. **Never commit docs to the project repository.** Always verify `/docs` and `/docs/` are ignored before staging project files.
2. **Never hardcode machine-specific paths.** Always resolve paths dynamically using environment variables or relative workspace paths.
3. **Use portable relative links in Markdown.** Never embed absolute filesystem paths (`/Users/...`, `C:\...`) into committed documentation.
4. **Follow Git Workflow Rules** when committing to `engineering-handbook`:
   - Never auto-commit or auto-push without explicit user instruction.
   - Use conventional commits (`docs(<project>): ...`).
   - No `Co-authored-by` or agent attribution trailers.
