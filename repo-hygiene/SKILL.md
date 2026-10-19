# Repo Hygiene

> Keep your public GitHub profile portfolio-grade: audit which public repos are NOT portfolio material (old college/practice/experiment repos), get user sign-off, flip them to private (or archive forks), and verify. Companion to `repo-triage` (scans other people's repos for malware) and `gh-incident-response` (responds to compromise) — this playbook curates your own repos.

## Trigger

The user will say things like:
- "Rapikan repo public saya" / "repo kuliah mana yang bisa di-private"
- "Audit repo yang bukan portfolio"
- "Hide repo lama dari GitHub"
- "Repo hygiene" (periodic, e.g. quarterly)

## Core Principle

The agent's job is **judgment on edge cases and user sign-off** — never hand-improvised API gymnastics. All heavy lifting (metadata gathering, heuristic bucketing, batch apply, verification counts) is done by the scripts. A sweep over 60+ repos must cost the agent a handful of commands, not dozens.

## Data Caveats (learned the hard way)

- **`pushed_at` is unreliable after incident force-restores** — a restore sweep stamps every repo with the same recent date. Classify by `created_at` + description markers + language + stars, never by last push.
- **Forks of public repos CANNOT be made private** (GitHub restriction). Their options are: `archive` (read-only, still visible), `delete`, or detach from the fork network first (support/duplicate), then private.
- Visibility changes are reversible (`private=false` restores access) **except stars**: every star on a repo is lost permanently the moment it goes private. Surface any candidate with stars > 0 before applying.

## Phase 1 — Audit (read-only)

```bash
scripts/audit-visibility.sh [owner] [--keep-years N]
```

Buckets every non-archived public repo into:

| Bucket | Meaning | Evidence used |
|---|---|---|
| `PRIVATE_STRONG` | Clear archive material — act on the whole bucket | Strong markers: college/practicum/final-project/lab-archive wording (e.g. "tugas besar", "tubes", "praktikum", "kuliah", "arsip", "archives", "laborator") |
| `PRIVATE_REVIEW` | Old learning/experiment repos, or old repos with no professional signal | Weak markers ("learn", "sandbox", "experiment", "starter", "template", …) or no description + zero stars + older than cutoff |
| `KEEP` | Recent or professional-signal repos | Created within `--keep-years` (default 3), or clearly product/portfolio/tooling |

Plus a `FORK` bucket listing forks with the cannot-private reminder.

Marker regexes live in variables at the top of the script — extend them when a new pattern shows up, don't fork the logic.

## Phase 2 — Review Gate (user decision)

Present the buckets as tables with year + evidence. For `PRIVATE_REVIEW`, surface the borderline cases explicitly and ask — typical judgment calls:

- **Client/freelance work** (e.g. a 2020 client app): belongs private for the *opposite* reason — code that must not be public at all
- **Teaching material still in use** ("buat ngajarin") — keep if still referenced
- **"My first X" sentimental repos** — user's call, not the heuristic's
- **Named "learn-" but fresh and documented** — recency usually wins

Get explicit confirmation per bucket (e.g. "A + B, minus these two"). Do not apply anything on silence.

## Phase 3 — Apply (only after the gate)

```bash
scripts/apply-visibility.sh <list-file> [--yes]
```

- List file: one repo per line, `name` or `name action` (action: `private` default, `public`, `archive`, `unarchive`)
- **Dry-run by default** — prints the planned API calls; `--yes` executes them
- Each change is a single PATCH; the script reports per-repo OK/FAIL and totals

## Phase 4 — Verify (always)

1. Compare the post-apply public repo count against the expected arithmetic (before − applied). **A mismatch means a repo was missed** — in the first run of this workflow the count exposed a college repo skipped during manual classification. Diff the actual public list against the KEEP bucket to find it.
2. Spot-check a few repos: `gh api repos/<owner>/<repo> --jq '.private'`.

## Rules for the Curator

- Audit is read-only; no visibility change without explicit per-bucket user confirmation
- Never guess value on borderline repos (client work, teaching material, first-projects) — ask
- Surface every repo with stars > 0 before privatizing — stars never come back
- Forks cannot be private; offer archive/delete/detach instead
- Verify by counting and listing, never by assuming — a one-off diff catches what classification missed
- Rulesets keep enforcing on private repos, and a guardian PAT scoped to "all repositories" keeps sweeping them — no security gap is opened by hiding repos
