---
name: pasted-content-cleanup
description: Clean up, prettify, format, and remove noise from content pasted or fetched from web clippers/extensions (e.g., webpage-to-md, Definite, MarkDownload, browser copy-paste) without altering or losing core content.
---

# Pasted Content Cleanup

> Clean up, prettify, format, and remove web noise from content pasted or fetched via web clippers and browser extensions without altering, summarizing, or removing the core content.

---

## Purpose

When documents, articles, course lessons, or documentation pages are clipped or exported to Markdown via browser extensions (e.g., `webpage-to-md`, `MarkDownload`, `Definite`, or direct copy-paste), they almost always carry extensive UI noise:
- Course syllabus / sidebar navigation trees
- Breadcrumbs, rating bars, and voting widgets
- Reading progress meters, font-size adjustment controls (`AaAaAa`, `AAA`)
- Comment threads, user avatars, reply boxes, and relative timestamps
- Duplicate image alt text dumped below image tags
- Unformatted code blocks and flattened collapsible accordions (like Q&A "Show answer")

This playbook provides a systematic workflow for AI agents to **strip 100% of the noise** and **beautify the document structure** while **strictly preserving every sentence, explanation, code block, formula, and diagram** of the core technical content.

---

## Non-Negotiable Rules

1. **Zero Core Content Loss:**
   - **Never** summarize, rephrase, rewrite, or truncate the actual text, explanations, code snippets, formulas, or technical discussions.
   - All original images, external hyperlinks, and code examples must remain intact.
2. **Aggressive Noise Elimination:**
   - Strip all website chrome, course navigation outlines, progress indicators, comment sections, and social widgets.
3. **Markdown Enhancement (Prettification):**
   - Ensure proper heading levels (`#` title, `##` sections, `###` sub-sections).
   - Add language syntax highlighting to all fenced code blocks (e.g., ````python`, ````bash`, ````json`).
   - Format image captions cleanly under images using italics `*Caption text*` instead of raw duplicate paragraphs.
   - Convert interactive Q&A accordions or "Show answer" buttons into GitHub-flavored collapsible blocks (`<details><summary>Show Answer</summary>...</details>`).
   - Clean up lists and definitions into structured bullet points.

---

## Trigger Phrases

Activate this playbook when the user asks:
- *"Pretty this markdown"* / *"Beautify these .md files"*
- *"Clean up pasted content from webpage-to-md"*
- *"Remove noise from this scraped page without changing the content"*
- *"Format this clipped article"*

---

## The Noise Catalog: What to Strip

| Category | Typical Scraped Clutter to Strip |
| :--- | :--- |
| **Site Navigation & Syllabus** | Full course outlines, sidebar chapter lists, breadcrumbs, previous/next course links (e.g., `PreviousChapter AssessmentNext...`). |
| **UI Controls & Badges** | `Explain Add note`, `Rate`, `[Vote](...)`, `1% completed`, `Completed`, bookmark icons, copy buttons. |
| **Reading & Accessibility** | `Reading Progress`, `0%`, `AaAaAa`, `AAA`, font toggles, dark mode switches. |
| **Discussion & Comments** | `Comments`, `Sort by: Newest`, `Add a comment...`, user avatars (`lh3.googleusercontent.com/...`), user handles, relative timestamps (`· 5 months ago`), comment body, reply buttons. |
| **Clipper Artifacts** | Zero-width spaces (`\u200b`), duplicate image alt text outputted immediately after `![]()`, empty markdown rules (`---` chains), duplicate trailing "On This Page" blocks. |

---

## Step-by-Step Workflow

```text
Step 1: Identify Boundaries
  Locate real document title & body start / end
          ↓
Step 2: Strip Noise
  Remove header chrome, syllabus sidebar, and footer comments
          ↓
Step 3: Enhance & Prettify
  Heading hierarchy, syntax highlighting, captions, collapsible Q&A
          ↓
Step 4: Integrity Verification
  Verify all original explanations, links, images, and code remain intact
```

### Step 1: Identify Content Boundaries
1. Scan the raw file to find the **true document title** (usually the main `H1` or `H2` representing the article title, e.g. `# Introduction to Caching`).
2. Identify where the true body ends (usually right before navigation controls like `Completed`, `Previous/Next`, or the `Comments` section).
3. Everything outside these boundaries is candidate noise for removal.

### Step 2: Strip Noise & Artifacts
1. **Remove Pre-Content Clutter:** Delete all lines above the true title (course syllabus, header buttons, progress badges).
2. **Remove Post-Content Clutter:** Delete all trailing comment threads, reply inputs, reading progress meters, and trailing duplicate TOCs.
3. **Clean Invisible Characters:** Remove zero-width spaces (`\u200b`) and extraneous blank lines.

### Step 3: Markdown Beautification & Enhancement
1. **Title & Table of Contents:**
   - Single `# <Document Title>` at the top.
   - If the document has multiple sections, add a clean `## Table of Contents` with clickable internal anchors (`#section-anchor`).
2. **Code Blocks:**
   - Detect the language of unlabelled ```` ``` ```` code blocks and add the language tag (e.g. ````python`, ````javascript`, ````bash`, ````sql`).
3. **Image & Caption Treatment:**
   - When web clippers output `![alt text](url)` followed immediately by identical plain text `alt text`, format it cleanly as:
     ```markdown
     ![Alt text](image_url)
     *Alt text caption.*
     ```
4. **Interactive Accordions (Practice Questions / Q&A):**
   - When Q&A or "Show answer" buttons exist, wrap them in clean HTML details elements:
     ```markdown
     ### 1. Question text here?

     <details>
     <summary>Show Answer</summary>

     **Explanation/Answer text goes here.**

     </details>
     ```
5. **Formulas & Technical Terms:**
   - Enclose calculations and equations in backticks or clean markdown math (e.g., `0.9 x 1 + 0.1 x 51 = 6 ms`).
   - Format key terms clearly as bold definitions: `- **Term:** Definition text.`

### Step 4: Integrity Verification Checklist
Before completing the cleanup, perform a sanity check:
- [ ] Are all paragraphs, technical explanations, and nuances preserved word-for-word?
- [ ] Are all code snippets present without truncation?
- [ ] Are all diagrams/images preserved with their original URLs?
- [ ] Are all external hyperlinks preserved?
- [ ] Is all scraped UI noise (course syllabus, comment threads, reading meters) completely removed?
