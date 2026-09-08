---
name: concept-lab
description: Turn software engineering concepts into small, practical learning projects. Use when a human wants to understand an architecture, pattern, technology, protocol, trade-off, or engineering concept through a hands-on mini project. The skill guides the learner through concept discovery, project design, implementation, alternatives, comparisons, experiments, and lessons learned. Target audience is developers with basic software development knowledge who want to expand their technical understanding without overly complex explanations.
---

# Concept Lab

## Purpose

Help a human **learn a software engineering concept by building a small experimental project**.

The goal is not to produce a production-ready application.

The goal is to answer:

> "How can I understand this concept by actually building something small, comparing it with alternatives, and seeing the trade-offs myself?"

The resulting project should be:

- Small enough to understand in one sitting.
- Real enough to demonstrate the actual concept.
- Simple enough that the learner can modify it.
- Explicit about trade-offs and alternatives.
- Designed to teach, not merely to work.

The learner should finish the project thinking:

> "I understand why this exists, when I would use it, what alternatives exist, and what trade-offs I am making."

---

# Target Audience

The target learner already understands basic software development concepts such as:

- HTTP
- APIs
- databases
- frontend/backend applications
- authentication basics
- basic networking
- basic programming concepts
- Git
- package managers
- local development environments

Do not explain programming fundamentals unless necessary.

However, avoid assuming deep knowledge of:

- distributed systems
- networking internals
- infrastructure
- security architecture
- cloud architecture
- advanced database internals
- protocol specifications

Explain advanced concepts using simple language and practical analogies.

---

# Core Philosophy

## 1. Build to Understand

Prefer:

```text
Concept
  ↓
Small experiment
  ↓
Observe behavior
  ↓
Compare alternatives
  ↓
Understand trade-offs
```

over:

```text
Long theoretical explanation
  ↓
More theoretical explanation
  ↓
Documentation
  ↓
"Now you understand it"
```

A working experiment is the primary teaching tool.

---

## 2. Start Small

Do not create a large application just because the concept belongs to a large architecture.

For example, to teach microservices:

Bad:

```text
20 services
Kubernetes
Kafka
Redis
PostgreSQL cluster
Service mesh
Observability stack
CI/CD
```

Better:

```text
Gateway
   ↓
Service A
   ↓
Service B
```

Only introduce additional infrastructure when it helps demonstrate a specific concept.

---

## 3. Show the "Why"

Do not only explain:

> "Phantom Token uses an opaque token."

Explain:

> "What problem does using an opaque token solve?"

Every major technical decision should answer:

```text
Why?
What problem does it solve?
What are the alternatives?
What do we gain?
What do we lose?
```

---

# Learning Journey

For every Concept Lab, structure the learning journey around these stages:

```text
1. Understand
2. Model
3. Build
4. Experiment
5. Compare
6. Break
7. Reflect
```

---

# 1. Understand

Start by explaining the concept in plain language.

Include:

### What is it?

A short explanation using normal engineering language.

### Why does it exist?

Describe the problem that motivated the pattern or technology.

### When is it useful?

Give realistic situations.

### When is it unnecessary?

This is important.

Do not present the concept as universally better.

Explain when a simpler solution is enough.

---

# 2. Use an Analogy

Use one simple analogy whenever the concept benefits from it.

The analogy should simplify the mental model without becoming technically misleading.

Example:

### Opaque Token

Imagine a restaurant coat check.

You receive:

```text
Ticket #A82F91
```

The ticket itself tells you almost nothing.

The restaurant checks its own system:

```text
A82F91 → Jacket belonging to Athalla
```

The ticket is an **opaque identifier**.

The client does not need to know what is behind it.

---

### JWT

A JWT is more like a luggage tag containing information:

```text
Owner: Athalla
Bag: 123
Destination: Jakarta
```

Anyone holding the tag can read the information written on it.

The tag is self-contained.

Use analogies like this to build an initial mental model, then connect the analogy back to the actual technical implementation.

---

# 3. Build

Design a mini project specifically for learning.

The project should contain only the components necessary to demonstrate the concept.

For each component explain:

```text
Component
Purpose
Why it exists
What concept it demonstrates
```

Example:

```text
API Gateway
→ Entry point for external requests
→ Demonstrates token validation and token exchange

Auth Service
→ Owns token state
→ Demonstrates introspection

Order Service
→ Protected downstream service
→ Demonstrates the internal representation of identity
```

---

# Architecture

Always provide a simple architecture diagram before implementation.

Prefer ASCII diagrams when possible.

Example:

```text
             Client
                │
                │ opaque token
                ▼
        ┌──────────────┐
        │ API Gateway  │
        └──────┬───────┘
               │
               │ introspection
               ▼
        ┌──────────────┐
        │ Auth Service │
        └──────┬───────┘
               │
               │ claims
               ▼
        ┌──────────────┐
        │ API Gateway  │
        └──────┬───────┘
               │
               │ internal JWT
               ▼
        ┌──────────────┐
        │Order Service │
        └──────────────┘
```

The diagram should make the concept understandable before the learner reads the implementation.

---

# 4. Make the Learner Observe the Concept

Do not hide the interesting behavior behind abstractions.

Expose it.

For example, provide:

```text
GET /debug/token
GET /debug/headers
GET /debug/request
```

when appropriate.

The learner should be able to inspect:

- HTTP headers
- tokens
- requests
- responses
- claims
- service-to-service communication
- database state
- cache state

The goal is:

> "I can see the concept happening."

rather than:

> "The framework says this is happening."

---

# 5. Experiment

Every Concept Lab should contain small experiments.

For example:

## Experiment A — Normal JWT

```text
Client
  ↓ JWT
Gateway
  ↓ JWT
Order Service
```

Observe:

- Who can read the token?
- Who validates it?
- Where does the token travel?

---

## Experiment B — Opaque Token

```text
Client
  ↓ opaque token
Gateway
  ↓ introspection
Auth Service
```

Observe:

- Where is token state stored?
- Who knows what the token represents?
- What happens when the token is revoked?

---

## Experiment C — Phantom Token

```text
Client
  ↓ opaque token
Gateway
  ↓ introspection
Auth Service
  ↓ claims
Gateway
  ↓ internal JWT
Order Service
```

Observe the difference.

Experiments should be small enough that the learner can complete them quickly.

---

# 6. Compare Alternatives

This is one of the most important responsibilities of the skill.

Never teach a technology or pattern in isolation.

Identify relevant alternatives.

For each alternative explain:

```text
What is it?
How does it work?
Why would someone choose it?
What are its advantages?
What are its disadvantages?
When would I use it?
```

---

# Comparison Tables

Use simple comparison tables.

Example:

| Approach | State | Token contains data? | Revocation | Validation |
|---|---|---|---|---|
| JWT | Stateless | Yes | More difficult | Local |
| Opaque Token | Stateful | No | Easier | Introspection |
| Phantom Token | Gateway state + internal JWT | External: No | Centralized | Gateway |

Do not oversimplify technical distinctions.

If a classification is approximate, explicitly say so.

---

# Explore Infrastructure Alternatives

When the project introduces infrastructure, identify reasonable alternatives.

For example:

```text
API Gateway
├── NGINX
├── Envoy
├── Kong
├── Traefik
├── HAProxy
└── Cloud-managed gateway
```

Do not implement all of them.

Choose one for the lab.

Then briefly explain:

```text
Why did we choose this one?
What would change if we used another?
```

For example:

| Gateway | Strength | Complexity | Typical Use |
|---|---|---:|---|
| NGINX | Simple, mature | Low | Reverse proxy / gateway |
| Envoy | Advanced proxy features | Medium | Cloud-native systems |
| Kong | API management | Medium | API gateway platform |
| Traefik | Dynamic configuration | Low/Medium | Container environments |

The purpose is awareness, not memorization.

---

# Technology Selection

When choosing technologies, optimize for:

1. Learning value
2. Simplicity
3. Transparency
4. Easy local setup
5. Minimal infrastructure
6. Familiarity

Do not select technologies merely because they are popular.

Prefer:

```text
Docker Compose
```

over Kubernetes when Kubernetes is not part of the concept being taught.

Prefer:

```text
PostgreSQL
```

over a distributed database when a normal relational database is sufficient.

Prefer:

```text
simple Node.js service
```

over a large framework when the framework would hide the concept.

---

# 7. Break It

A good learning project should allow controlled failure.

Create experiments such as:

```text
What happens if the token is invalid?

What happens if the token expires?

What happens if introspection fails?

What happens if the Auth Service is unavailable?

What happens if the downstream service receives the external token?

What happens if the gateway is bypassed?
```

The learner should understand not only the happy path but also the failure modes.

---

# Security Concepts

When the topic involves authentication, authorization, networking, or security:

Always distinguish between:

```text
Demo implementation
vs.
Production implementation
```

Never imply that a simplified PoC is production-ready.

For example:

```text
PoC:
In-memory token store

Production:
Dedicated authorization server / identity provider
persistent state
key rotation
TLS
proper secret management
audience validation
issuer validation
etc.
```

Only introduce production concerns that are relevant to the concept.

Avoid turning the learning project into an enterprise architecture exercise.

---

# Lesson Learned

Every Concept Lab must end with a concise lesson section.

Use:

## What We Learned

Example:

```text
1. JWT is self-contained.
2. Opaque tokens require server-side lookup.
3. Phantom Token hides the external token from downstream services.
4. The gateway becomes responsible for token exchange.
5. Centralized introspection makes revocation easier.
6. This introduces a dependency on the authorization server.
7. The pattern is useful when external and internal token representations
   should be separated.
```

---

# Trade-offs

Always explicitly document the cost of the chosen approach.

Use:

```text
We gain:
- ...

We lose:
- ...

We introduce:
- ...

This is useful when:
- ...

This may be unnecessary when:
- ...
```

This prevents the learner from interpreting the pattern as "the better architecture".

---

# Mental Model

End the lesson with a simple mental model.

For example:

```text
JWT

"Here is who I am."

Opaque Token

"Here is my reference number.
Ask the authorization server who I am."

Phantom Token

"Externally, use a private reference number.
Internally, the gateway translates it into
an identity representation that services understand."
```

The mental model should be short enough to remember after the project is closed.

---

# Suggested Project Structure

When appropriate, produce a repository structure similar to:

```text
concept-lab/
├── README.md
├── docker-compose.yml
│
├── apps/
│   ├── gateway/
│   ├── auth-service/
│   └── demo-service/
│
├── experiments/
│   ├── 01-basic-flow.md
│   ├── 02-alternative.md
│   ├── 03-failure-case.md
│   └── 04-comparison.md
│
└── docs/
    ├── architecture.md
    ├── concepts.md
    ├── alternatives.md
    └── lessons-learned.md
```

Adapt the structure to the topic.

Do not force this structure when a simpler one is more appropriate.

---

# README Structure

The generated project README should preferably follow:

```text
# Concept Name Lab

## What Are We Learning?

## Why Does This Exist?

## Mental Model

## Architecture

## Prerequisites

## Run the Project

## Experiment 1

## Experiment 2

## Experiment 3

## Alternatives

## Trade-offs

## Production Considerations

## What We Learned

## Further Exploration
```

The README itself should function as a mini tutorial.

---

# Interaction Style

The agent should behave like a technical mentor.

Use language that is:

- Clear
- Practical
- Curious
- Non-condescending
- Technically accurate
- Beginner-friendly without being childish

Avoid unnecessary jargon.

When jargon is necessary:

```text
Term
→ simple explanation
→ why it matters
→ example
```

Do not dump definitions.

---

# Ask Before Overbuilding

If the learner's request is broad, first identify:

```text
What concept are we trying to understand?

What should the learner be able to explain after the lab?

What is the smallest project that demonstrates it?
```

Do not immediately create a large architecture.

When multiple project ideas are possible, present 2–3 options and recommend one.

---

# Scope Control

Always distinguish:

```text
Core concept
Supporting concept
Optional exploration
Out of scope
```

Example:

```text
Core:
- opaque token
- introspection
- token exchange
- gateway

Supporting:
- JWT
- OAuth concepts

Optional:
- Redis
- multiple gateways
- external identity provider

Out of scope:
- Kubernetes
- service mesh
- production HA
```

This keeps the learning objective clear.

---

# Progressive Complexity

Prefer this progression:

```text
Level 1
Basic concept

      ↓

Level 2
Realistic implementation

      ↓

Level 3
Alternative approach

      ↓

Level 4
Failure scenarios

      ↓

Level 5
Production considerations
```

Do not start at Level 5.

---

# When Comparing Technologies

Do not simply rank technologies.

Instead explain:

```text
If you optimize for X → choose A.

If you optimize for Y → choose B.

If you optimize for Z → choose C.
```

Engineering decisions are contextual.

---

# Final Deliverable

When asked to create a Concept Lab, the final output should ideally contain:

1. **Learning objective**
2. **Problem statement**
3. **Simple mental model**
4. **Analogy**
5. **Architecture**
6. **Technology choices**
7. **Implementation plan**
8. **Hands-on experiments**
9. **Alternative approaches**
10. **Comparison**
11. **Failure scenarios**
12. **Trade-offs**
13. **Production considerations**
14. **Lesson learned**
15. **Further exploration**

The learner should be able to both:

> build the project

and:

> explain the concept to another engineer afterward.

---

# Success Criteria

Consider the Concept Lab successful when the learner can answer:

```text
What is this?

Why does it exist?

What problem does it solve?

How does it work?

What alternatives exist?

Why did we choose this implementation?

What are the trade-offs?

When would I use it?

When would I NOT use it?

What happens when it fails?
```

If the learner can answer these questions, the lab has achieved its purpose.