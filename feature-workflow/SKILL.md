# Feature Workflow

> A universal, stack-agnostic playbook for planning, building, verifying, and shipping new features in any codebase. Designed for frictionless onboarding of junior developers and autonomous AI agents.

---

## Trigger

Activate this playbook when the user says things like:
* "How do I build this new feature?"
* "Guide me through adding [feature] to this repo"
* "I'm new to this project, where do I start building [feature]?"
* "What is the workflow/order of files to create for this feature?"
* "Let's build a new feature end-to-end"

---

## Core Philosophy

Every software application—regardless of language, framework, or whether it is frontend, backend, or mobile—is fundamentally a **data-processing pipeline**:

```text
[ Trigger / User Action ] ──▶ [ Boundary Validation ] ──▶ [ Business Logic ] ──▶ [ State / Persistence ] ──▶ [ Response / View ]
```

When building a new feature, follow three golden engineering rules:
1. **Vertical Slicing:** Build a thin, working, testable slice from end to end (database/state ➔ business logic ➔ transport/UI) rather than building all database tables upfront or writing mock UI without data.
2. **Conventions Over Invention:** Before writing a single line of code, find an existing "sibling" feature in the codebase and mirror its patterns, folder organization, naming style, and testing setup.
3. **Fail Fast at the Boundary:** Validate all inputs and permissions at the outer gates (HTTP requests, form inputs, route parameters) so core domain logic can assume sanitized, valid data.

---

## The 7-Phase Universal Feature Lifecycle

Follow these phases in strict sequential order:

```text
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Phase 0:    │ ──▶│  Phase 1:    │ ──▶│  Phase 2:    │ ──▶│  Phase 3:    │
│  Orientation │    │  Contract    │    │  Data Model  │    │  Validation  │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
                                                                    │
┌──────────────┐    ┌──────────────┐    ┌──────────────┐            │
│  Phase 7:    │ ◀──│  Phase 6:    │ ◀──│  Phase 5:    │ ◀──────────┘
│  Pre-Flight  │    │  Verify & QA │    │  Transport/UI│    ┌──────────────┐
└──────────────┘    └──────────────┘    └──────────────┘    │  Phase 4:    │
                                                          ──│  Domain Logic│
                                                            └──────────────┘
```

---

### Phase 0: Orientation & Repo Reconnaissance

**Goal:** Understand the repository's anatomy before creating files.

1. **Locate the "Sibling" Feature:**
   * Search for an existing feature that has a similar scope (e.g., if you are adding `Categories`, find how `Tags` or `Departments` were built).
   * Note how files are named, where they live, and how they interact.
2. **Map the Architecture Style:**
   * **Monolith (MVC):** Routes ➔ Controllers ➔ Models ➔ Views.
   * **Decoupled Backend (REST/GraphQL/gRPC):** Routes ➔ Controllers ➔ FormRequests ➔ Services ➔ Resources/DTOs ➔ DB.
   * **Single Page Application (React/Next.js/Vue):** Pages/Routes ➔ Components ➔ Hooks/State ➔ API Client ➔ Types.
   * **Clean / Hexagonal:** Handlers ➔ Use Cases / Interactors ➔ Domain Entities ➔ Repositories.
3. **Verify Local Environment:**
   * Confirm the dev server, Docker containers, and test suites run cleanly on the base branch before you make any changes.

---

### Phase 1: Contract & Scope Definition

**Goal:** Establish clear inputs, outputs, and success criteria.

1. **Define the User Story:**
   * *Who* is performing the action? (Role / permissions required).
   * *What* data are they sending?
   * *What* outcome or state change is expected?
2. **Lock the Contract:**
   * **For API / Backend:**
     * HTTP Method and Route: `POST /api/v1/tags`
     * Request payload schema (required vs optional fields, data types).
     * Response payload envelope (`201 Created` with resource body, `422` validation format, `403` forbidden).
   * **For UI / Frontend:**
     * Component hierarchy and wireframe states (Empty, Loading, Success, Error).
     * Data requirements (props, local state, global state).
     * Mutations and optimistic UI behaviors.

---

### Phase 2: Data Modeling & Persistence

**Goal:** Define how the feature's state is stored and retrieved.

* **Backend / Relational DB:**
  1. Create a schema migration (table name, column types, foreign keys, indexes, nullability).
  2. Run the migration against your local/Docker database.
  3. Create or update the entity/model (ORM mapping, table relationships, type casting).
  4. (Optional) Add seed data or model factories for local development and tests.
* **Frontend / Client-Side State:**
  1. Define TypeScript interfaces / types representing the entity.
  2. Define the state store (Pinia, Redux, Zustand, React Context, or TanStack Query cache keys).

---

### Phase 3: Boundary Validation & Access Control

**Goal:** Protect the core system from malicious, malformed, or unauthorized input.

1. **Input Validation (Syntax & Schema):**
   * Put validation rules in a dedicated boundary layer (e.g., FormRequest in Laravel, Zod schema in TypeScript/Next.js, Pydantic in Python, Validator in Go).
   * Check mandatory fields, string length, regex patterns, email formats, and uniqueness.
   * Ensure invalid inputs return standard validation error structures (e.g., HTTP `422 Unprocessable Entity`).
2. **Authorization & Access Control (Security):**
   * Verify identity (Authentication): Is there a valid session or Bearer token?
   * Verify permissions (Authorization / RBAC): Does this user have the required role or ownership? (e.g., Policy in Laravel, CASL / Next-Auth middleware in Node.js, Casbin in Go).
   * Unauthorized actors must receive immediate rejection (`401 Unauthorized` or `403 Forbidden`).

---

### Phase 4: Domain & Business Logic

**Goal:** Implement the core problem-solving code.

1. **Keep Transport Handlers Thin:**
   * Controllers, Route Handlers, and UI Components should only coordinate traffic.
   * Put heavy computations, relational queries, tree traversals, and third-party integrations into **Services**, **Actions**, or **Domain Use-Cases**.
2. **Handle Side-Effects:**
   * Offload slow tasks (image resizing, sending emails, generating PDFs) to background asynchronous job queues (Redis, SQS, Celery, BullMQ).
3. **Handle Edge Cases Deterministically:**
   * Circular dependencies, division by zero, duplicate submissions, and network timeouts must fail gracefully with explicit exceptions.

---

### Phase 5: Transport & Interface Exposure

**Goal:** Connect the business logic to the outside world.

* **For Backend Services:**
  1. Register the route in the routing table (with appropriate middleware guards).
  2. Wire the route to the controller/handler action.
  3. Format the outgoing response using a serialization layer (API Resource, DTO, or ViewModel) to guarantee internal database columns (passwords, tokens) never leak to the client.
* **For Frontend Applications:**
  1. Wire the API client (Axios, Fetch, TRPC) with typed responses.
  2. Implement the UI components, forms, and buttons.
  3. Handle all four UI states: **Idle / Initial**, **Loading (spinners/skeletons)**, **Success (toasts/redirects)**, and **Error (inline banners)**.

---

### Phase 6: Verification, Testing & Quality Assurance

**Goal:** Prove the feature works and will not regress.

1. **Automated Testing:**
   * **Unit Tests:** Verify isolated business logic, utility functions, and edge cases.
   * **Feature / Integration Tests:** Test the full vertical slice (e.g., making an HTTP request to the endpoint, asserting DB changes, asserting status codes and response structures).
   * Cover at least:
     * Happy path (valid data ➔ success response).
     * Validation failure (invalid input ➔ standard error).
     * Access control failure (unauthorized user ➔ 403).
2. **Manual Smoke Testing:**
   * Test the live endpoint or UI in the browser / Postman / cURL.
   * Test with unexpected inputs (empty strings, huge payloads, special characters).
3. **Code Formatting & Static Analysis:**
   * Run the project's linter and formatter (e.g., Pint, Prettier, ESLint, Go fmt, Ruff).

---

### Phase 7: Pre-Flight Review & Clean Pull Request

**Goal:** Prepare a clean, professional changeset for code review.

1. **Inspect Your Diff:**
   * Run `git diff` or `git status`. Ensure no temporary logs (`console.log`, `dd()`, `print()`), scratch files, or commented-out dead code remain.
2. **Security Audit Check:**
   * Ensure no API keys, secrets, `.env` files, or personal credentials are staged.
3. **Commit Cleanly:**
   * Use Conventional Commits (`feat: add category CRUD and RBAC policies`).
   * Never add AI attribution trailers (`Co-authored-by`). Commits belong to the engineer.
4. **Draft PR Summary:**
   * Summarize: *What changed?*, *Why?*, and *How was it tested? (Include test output or screenshots)*.

---

## Universal Stack Mapping Matrix

Use this cheat sheet to translate the 7 phases into your project's technology stack:

| Concept / Layer | Laravel / PHP | Next.js / TypeScript / React | Express / Node.js | Go (Gin / Fiber) | Python (FastAPI / Django) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Data Schema** | `database/migrations/` | Prisma `schema.prisma` / Drizzle | Knex / TypeORM / Prisma | `golang-migrate` SQL files | Alembic / Django `migrations/` |
| **2. Model / Entity** | `app/Models/*.php` | `types/*.ts` & Prisma Client | `models/*.ts` or Entities | `internal/model/*.go` | SQLAlchemy / Django `models.py` |
| **3. Route Definition** | `routes/api.php` | `app/api/.../route.ts` | `routes/*.ts` | `router.POST(...)` | `api_router.include_router()` |
| **4. Input Validation** | `app/Http/Requests/*.php` | Zod / Yup schemas | Joi / Zod middleware | Go `validator.v10` struct tags| Pydantic `BaseModel` |
| **5. Authorization (RBAC)**| `app/Policies/*.php` | CASL / Next-Auth session guard | Passport / custom middleware | RBAC middleware / Casbin | FastAPI Dependencies / Permissions |
| **6. Business Logic** | `app/Services/*.php` | Server Actions / `lib/services/` | `services/*.ts` | `internal/service/*.go` | `services.py` / Use Cases |
| **7. Serialization / DTO**| `app/Http/Resources/*.php` | TypeScript DTO / Transform | DTO / Class-Transformer | Response Struct with JSON tags | Pydantic Response Model |
| **8. Controller / Handler**| `app/Http/Controllers/` | Route Handlers (`route.ts`) | Controller functions | `internal/handler/*.go` | Router view functions |
| **9. Automated Tests** | `tests/Feature/*.php` (Pest/PHPUnit)| Jest / Vitest / Playwright | Supertest / Vitest | Go `*_test.go` | Pytest / TestClient |

---

## Anti-Patterns & Pitfalls to Avoid

1. **The "Fat Controller / Fat Component" Trap:**
   * Putting SQL queries, validation, third-party API calls, and business logic inside a controller or React component makes code untestable and unmaintainable. Delegate to services and helper layers.
2. **The "Invisible Sibling" Mistake:**
   * Inventing a brand-new folder structure or coding style in an established repository. Always conform to the existing conventions of the repo you are working in.
3. **The "Happy Path Only" Delusion:**
   * Writing code that only works when everything goes right. Always handle database timeouts, missing records (404), validation rejections, and network disconnects.
4. **Untracked Secret Commits:**
   * Hardcoding connection strings or private keys during feature development. Always use environment variables (`.env`).
