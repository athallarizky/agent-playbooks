---
name: cross-lang-analogy
description: Explains new programming language concepts, paradigms, and syntax by building direct 1-to-1 mental models and code analogies from the user's familiar programming language (e.g., React/TS to Go, Python to Rust, Java to Kotlin). Use whenever a developer is transitioning to or learning a new language and needs clear, intuitive explanations anchored in what they already know.
---

# Cross-Language Analogy Playbook

> Accelerate learning a new programming language by mapping its syntax, runtime behavior, and architectural paradigms to the developer's existing mental models.

---

## Purpose

When experienced software engineers learn a new programming language, traditional tutorials often slow them down by re-explaining fundamental programming concepts (variables, loops, conditionals) while glossing over the critical **paradigm shifts** (e.g., error handling philosophies, memory allocation models, concurrency primitives).

This playbook provides a systematic framework for AI agents to:
1. Identify the learner's **mental anchor** (the language/stack they know best).
2. Deconstruct unfamiliar syntax into plain, conversational language.
3. Provide **side-by-side code analogies** in the familiar language.
4. Explain the underlying **paradigm difference** ("Why does this language do it this way?").
5. Warn about insidious **gotchas and pitfalls** that trip up developers coming from that specific background.

---

## Trigger Phrases

Activate this playbook when the user:
- Asks how or why a piece of code works in a new language while mentioning their background (e.g., *"I'm a frontend dev used to TypeScript, why is Go written like this?"*).
- Asks for an analogy or comparison between two languages (e.g., *"What is the Go equivalent of TS async/await?"*, *"Explain Rust's borrow checker using a JavaScript analogy"*).
- Explicitly activates the playbook: *"Use the cross-lang-analogy playbook"*.

---

## Interaction Workflow

```
[Phase 1: Mental Anchor Discovery]
       │
       ▼
[Phase 2: The 4-Pillar Analogy Framework]
  ├── Pillar 1: Literal Syntax Reading
  ├── Pillar 2: Familiar Language Equivalent (Side-by-Side)
  ├── Pillar 3: Paradigm Shift & "Why"
  └── Pillar 4: False Friends & Gotchas
       │
       ▼
[Phase 3: Interactive Verification & Next Step]
```

### Phase 1: Mental Anchor Discovery

Before delivering explanations:
1. **Context Check:** Did the user already mention their background language and target language?
   - *Example:* "I'm a React/TS engineer learning Go" → Anchor: **TypeScript**, Target: **Go**.
2. **If NOT Known:** Ask two quick, non-intrusive questions before proceeding:
   - *"Which programming language or tech stack are you most comfortable with?"*
   - *"Which language are you currently learning or trying to understand?"*
3. **If Known:** Adopt the anchor immediately without asking again.

---

## Phase 2: The 4-Pillar Analogy Framework

Every code breakdown or concept explanation MUST follow this 4-pillar structure:

### 1. Literal Syntax Reading (Human-Readable Translation)
Break down the code snippet line-by-line into literal human speech before introducing terminology.
- Demystify unfamiliar operators and syntax constructs (e.g., `:=`, `&`, `*`, `<-`, `?`, `impl`, `match`).
- Explain the visual reading flow (e.g., Go's `if init; condition { ... }` or Rust's pattern matching).

### 2. Familiar Language Equivalent (Side-by-Side Comparison)
Demonstrate how the exact same logic or pattern is typically expressed in the learner's familiar language.
- Provide clean, idiomatic code snippets side-by-side.
- Highlight structural parallels (e.g., Go's multiple return values `(Config, error)` vs TypeScript's tuple returns `[Config, Error | null]`).

### 3. Paradigm Shift & "Why" (The Mental Model)
Explain the architectural rationale and design philosophy behind the syntax:
- Why doesn't the target language use the familiar approach?
- Key dimensions to address when relevant:
  - **Error Handling:** Exceptions (`throw/catch`) vs Error as Values (`(val, err)`) vs Tagged Unions (`Result<T, E>`).
  - **Memory & Allocation:** Automatic reference vs Explicit Pointers (`*`, `&`) vs Borrowing / Ownership.
  - **Concurrency:** Single-threaded Event Loop vs Communicating Sequential Processes (CSP/Goroutines/Channels) vs OS Threads.
  - **State Management:** Immutability by convention vs Value Copying vs Pointer Mutation.
  - **Typing & Polymorphism:** Nominal vs Structural vs Duck typing vs Interfaces/Traits.

### 4. False Friends & Gotchas (Common Traps)
Warn about habits from the origin language that lead to subtle bugs or runtime crashes:
- *From JS/TS to Go:* Nil pointer dereference (runtime panic), mutating copied struct values, goroutine leaks, zero-value vs `undefined`.
- *From Python to Go/Rust:* Lack of dynamic duck typing, strict type casting, explicit error bubbling.
- *From Java/C# to Go:* Lack of class inheritance, explicit error handling instead of deep exception hierarchies.

---

## Phase 3: Interactive Verification & Follow-up

1. Keep explanations focused and avoid overwhelming with too many novel concepts at once.
2. Verify understanding: *"Does this analogy align with how you think about it in [familiar language]?"*
3. Offer natural follow-up explorations (e.g., *"Would you like to see how this pattern handles unit testing or concurrent execution?"*).

---

## Core Paradigm Mapping Reference (Quick Cheatsheet)

| Concept Dimension | TypeScript / JavaScript | Go | Rust | Python |
| :--- | :--- | :--- | :--- | :--- |
| **Error Handling** | `try / catch / throw` | Explicit return `(T, error)` | `Result<T, E>` / `match` / `?` | `try / except / raise` |
| **Optional / Null** | `null \| undefined \| ?.` | Pointer `*T` with `nil` / zero-value | `Option<T>` (`Some`/`None`) | `None` / `Optional[T]` |
| **Data Structures** | `interface` / `type` (object) | `struct` | `struct` + `enum` (tagged union) | `dataclass` / `dict` / `class` |
| **Polymorphism** | Structural / Subtyping | Implicit Interface implementation | `trait` implementation (`impl Trait`) | Duck typing / Protocol / ABC |
| **Memory Passing** | Primitives = value, Objects = ref | All pass-by-value unless `*` pointer | Ownership, Borrowing (`&`, `&mut`) | Everything is object reference |
| **Async / Concurrency** | Event loop, `Promise`, `async/await` | Goroutines + Channels (`go f()`, `chan`) | `async`/`await` + Tokio / Threads | `asyncio`, GIL / Threads / Multiprocess |
