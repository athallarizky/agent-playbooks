---
name: real-world-analogy
description: Explains technical and architectural concepts by casting the system into a vivid everyday-world story (people, objects, places) where every component has a strict 1-to-1 structural counterpart. Use when the learner understands the words but not the concept — after code samples or cross-language analogies have failed to land.
---

# Real-World Analogy

> When someone says "I still don't understand" **after** seeing the code and
> the code-level analogy — the missing piece is usually not more code. It is
> a story whose *structure* is the system.

Sibling playbook: `cross-lang-analogy` maps **language → language**
("goroutines are like async/await"). This playbook maps **system → physical
world** ("Redis is a desk of timed sticky notes").

---

## Trigger Phrases

- "jelaskan pakai analogi dunia nyata" / "pakai orang atau benda"
- "explain like I'm five" / "pakai cerita"
- "I still don't get it" — after code explanations or `cross-lang-analogy`
- User asks WHY an architecture is shaped the way it is, at a gut level
  ("kenapa gak simpan satu array besar saja?")

---

## The Core Principle

**An analogy is only as good as its mapping table.**

Every moving part of the real system must have exactly one counterpart in the
story, and every interaction in the story must correspond to a real
interaction. Parts that cannot be mapped are exactly the places the analogy
lies — and must be declared (see Phase 5).

---

## Workflow

```
[Phase 1: Diagnose the gap]
       │  what SPECIFIC question/confusion? (write it down verbatim)
       ▼
[Phase 2: Choose a setting whose physics matches]
       │  consult the Setting Library; cultural proximity to the learner wins
       ▼
[Phase 3: Build the CAST — mapping table BEFORE the story]
       │  component ↔ object, and the INVARIANT each pair preserves
       ▼
[Phase 4: Walk scenarios — the learner's exact question must be one of them]
       │
       ▼
[Phase 5: Break the analogy honestly]
       │  where does the story stop mapping?
       ▼
[Phase 6: The punchline + bridge back to technical terms]
```

### Phase 1 — Diagnose the gap

Capture the learner's question **verbatim** ("kenapa harus bikin key per jam,
bukannya satu full-day terus difilter?"). The final story MUST play out this
exact scenario — an analogy that answers a different question is a performance,
not a lesson.

### Phase 2 — Choose the setting

The setting's *physics* must match the mechanism, not just its vibe:

| If the system has… | The setting must have… |
|---|---|
| Cache + TTL | Objects that expire (timed notes, day-old bread, parking tickets) |
| Index / fast lookup | Books with tabs, catalogs, phonebook sections |
| Idempotency | Stamp on an already-processed form |
| Request coalescing | One person sent to check while the rest wait at the table |
| Rate limiting | Bouncer, queue with a marquee |
| Single source of truth vs replicas | Ledger book vs photocopies with expiry |

**Cultural proximity beats cleverness**: for an Indonesian commuter-rail
project, a station information desk beats an abstract "library".

### Phase 3 — The cast (mapping table is mandatory and comes FIRST)

Build the table before writing one sentence of story:

| Story object | System component | Invariant preserved |
|---|---|---|
| 📕 Timetable book with tabs | Postgres + B-tree index | authoritative, one copy, fast range lookup |
| 🗒️ Note with a 2-minute timer | Redis key with TTL | disposable, auto-expiring answer |
| 🧹 Janitor | TTL eviction | unattended cleanup, no manual purge |
| 🧑‍💼 Clerk | the service | does the lookup, writes the note |

If a row cannot preserve an invariant, the setting is wrong — pick another.

### Phase 4 — Walk the scenarios

Play out 3–5 concrete scenes with dialogue, in this order:
1. The happy path (cache hit) — "gratis"
2. The learner's exact question as a scene (the two competing designs,
   side by side, with the WORK counted out loud — "mencoret 52 baris SETIAP
   penumpang" vs "sekali per 2 menit")
3. The failure/healing path (note expired, book consulted again)

Count the work explicitly — analogies convince when arithmetic is visible.

### Phase 5 — Break the analogy honestly

Every analogy lies somewhere; name where:
- "Kertas itu murah, dan harganya nol dibanding tenaga petugas — di Redis,
  key memang nyaris gratis karena dibatasi TTL dan pola pertanyaan"
- "Janitor kita datang tepat waktu; Redis TTL tidak menunggu siapa-siapa"
Declare the break BEFORE the learner discovers it and loses trust.

### Phase 6 — Punchline + bridge back

End with:
1. **One sentence** worth remembering ("Redis menyimpan jawaban jadi, bukan
   bahan mentah")
2. A bridge table mapping each story character back to its technical name —
   the learner must leave holding BOTH vocabularies, not just the story.

---

## Rules

- NO code inside the story. Code may appear only in the bridge-back.
- The mapping table is mandatory; a story without one is a metaphor, not an
  analogy.
- Count the work/arithmetic out loud in the pivotal scenario.
- Always include "where this analogy breaks".
- One concept per story. A second concept gets a second story.

---

## Setting Library (starters — extend freely)

| Concept | Proven setting |
|---|---|
| Cache-aside + TTL | Station info desk: book (truth) + timed sticky notes (cache) |
| DB index (B-tree) | Tab dividers in a thick timetable/catalog book |
| Idempotent upsert | Re-stamping an already-processed form changes nothing |
| Singleflight / request coalescing | 50 passengers ask the same thing at once → one clerk walks to the archive, the rest wait and share the answer |
| Rate limiting | Club bouncer letting one person in every 5 seconds |
| Message queue | Laundry drop-off tickets — hand over, get a receipt, pick up later |
| Lazy vs eager loading | Warung that cooks on order vs pre-cooking the whole menu at dawn |
| Staleness window | Milk with a best-before date: fine today, replaced on the next delivery |
