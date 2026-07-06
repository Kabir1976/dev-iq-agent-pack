---
name: onboard-codebase
description: Generate a structured onboarding guide for a new developer joining the codebase — entry points, architecture overview, key data flows, local development setup, and the most important things to know before touching code. Use when asked to "onboard me to this codebase", "explain the architecture", "I'm new to this repo", "create a developer guide", "orient me to this project".
di_signal: INTENT
maturity_required: early
status: approved
---

# Onboard Codebase

## Overview

Produces a structured "new developer guide" for the current repository —
a single document that orients a developer who has never seen the codebase
before. It covers architecture, entry points, one key data flow traced end
to end, local setup, and the team's established conventions.

This is an INTENT signal skill: a developer who does not understand what
the system does or how its pieces connect will misplace changes, duplicate
logic, and miss conventions. Good onboarding is the foundation for every
other DI signal to function correctly.

This skill operates at **repository level**, not file level. For file-level
explanation, use `/explain-code`. For architecture review (finding issues),
use `/review-architecture`. This skill is orientation, not assessment.

## When to Use

- When a new developer joins the team and needs to get productive quickly
- When a developer from a different service or team is taking over ownership
- When a contractor or consultant needs context before starting work
- When documentation is missing, outdated, or scattered across wikis
- Any time the user says: "onboard me to this codebase", "explain the
  architecture", "I'm new to this repo", "create a developer guide",
  "give me an overview of this project", "orient me to this project"

## Instructions

### Step 1: Read top-level structure

List and categorise the top-level directories and key files:
- Source directories: `src/`, `lib/`, `app/`, `packages/`
- Config files: `package.json`, `pom.xml`, `.env.example`, `docker-compose.yml`
- Entry points: `main.ts`, `Program.cs`, `app.py`, `index.js`, `cmd/`
- Test directories: `tests/`, `spec/`, `__tests__/`
- Infrastructure: `infra/`, `terraform/`, `.github/workflows/`
- Documentation: `docs/`, `README.md`, `CONTRIBUTING.md`

Produce a short annotated tree — not every file, just the directories and
files a new developer needs to know about on day one.

### Step 2: Identify the system's purpose and domain

From the README, config, and code, determine:
- What does this system do? (One clear sentence — not the README marketing
  copy, but the actual function: "processes payment transactions for the
  checkout service" not "a world-class payment platform")
- Who are the primary consumers? (Other services, mobile clients, web UI,
  internal tools, batch jobs)
- What is out of scope? (What does this system explicitly NOT do that a
  new developer might expect it to do?)

If the README is missing or outdated, infer from the code and flag the gap.

### Step 3: Map the architecture

From imports, configuration, and directory structure, build a service map:
- **What are the major internal modules/layers?** (e.g., Controllers →
  Services → Repositories → Database; or API Gateway → Lambda → DynamoDB)
- **What external systems does this service call?** (Databases, caches,
  message queues, third-party APIs, other internal services)
- **What calls this service?** (Infer from API routes, event subscriptions,
  or queue bindings)
- **What is the data store?** (Type, ORM if any, migration tool)
- **What is the message/event bus?** (Kafka, RabbitMQ, SQS, Azure Service Bus)

Represent this as a simple text diagram if the structure is clear enough,
or a bullet-point service map. Do not fabricate connections that cannot be
read from the code.

### Step 4: Trace one key data flow end to end

Pick the most representative user-facing operation — typically the primary
create/submit/process action (e.g., "place an order", "submit a payment",
"create a user account"). Trace it from the entry point to persistence
and back:

```
HTTP POST /orders
  → OrdersController.createOrder()
  → OrderService.processOrder()
    → InventoryService.reserveItems()   [calls external inventory service]
    → PaymentService.charge()           [calls Stripe API]
    → OrderRepository.save()            [writes to Postgres via TypeORM]
  → returns OrderDto
```

This trace teaches a new developer:
- Where to add a new endpoint
- Where business logic lives (and where it should NOT go)
- How external calls are structured
- What the data access layer looks like

### Step 5: Local development setup

Read `README.md`, `CONTRIBUTING.md`, `Makefile`, `docker-compose.yml`, and
any CI scripts to extract the local development workflow:

1. **Prerequisites** — runtime versions (Node 18+, Java 17, Python 3.11), tools (Docker, uv, make)
2. **Install** — `npm install`, `pip install -r requirements.txt`, `mvn install`
3. **Environment** — which `.env` variables are required vs. optional; where to find example values
4. **Run** — the command to start the service locally
5. **Test** — the command to run tests; any flags for fast vs. full suite
6. **Database** — migrations or seed data steps if required
7. **Common pitfalls** — anything in the README, comments, or commit history
   that signals "new developers always hit this"

If any step is missing from documentation, flag it explicitly so the team
knows what to document.

### Step 6: Established conventions

From reading the existing code (not the documentation), extract the team's
actual conventions:
- **Naming** — file naming, class naming, function naming as it appears in code
- **Error handling** — how errors propagate (typed errors, HTTP codes, logging pattern)
- **Testing** — test file co-location vs. separate directory; naming convention
  for test files and test cases; mocking approach
- **Traceability** — work item marker format from `.dev-iq/config.yaml`
- **Branch and PR naming** — from recent git log if readable

These are conventions the new developer must follow from day one. Describe
what IS, not what should be.

### Step 7: The 10 things to know before touching code

Synthesise from the above into a numbered list of the most important context
items — the things that would save a new developer from their first mistake.
Examples of what belongs here:
- "Authentication is handled by the middleware in `src/middleware/auth.ts` —
  never implement auth logic in a controller"
- "All database access goes through the repository layer — services never
  call the ORM directly"
- "The `config/` directory is generated at deploy time — do not commit
  secrets there, use environment variables"
- "The `LegacyOrderAdapter` in `src/adapters/` exists for backward compat
  with v1 clients — do not remove or modify it without checking with the
  platform team"

Limit to 10 items maximum. If there are more, prioritise what would cause
the most damage if missed.

## Inputs Required

| Input | Source | Required |
|-------|--------|----------|
| Repository to onboard | Current workspace | Yes (auto — reads the open repo) |
| Stack / framework | `.dev-iq/config.yaml` → `stack` | Auto-read |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## Developer Onboarding Guide — [Project name]
Generated: [date]
Note: AI-generated from codebase analysis — team should review and supplement.

---

### What this system does
[One clear sentence on the system's purpose and primary consumers.]

---

### Repository structure
[Annotated directory tree — directories and key files only]

---

### Architecture
[Service map: internal layers + external dependencies]
[Simple text diagram if the structure is clear]

---

### Key data flow: [chosen operation]
[Traced request from entry point to persistence and back]

---

### Local development setup
1. Prerequisites: [...]
2. Install: [command]
3. Environment: [which vars are required, where to find examples]
4. Run: [command]
5. Test: [command and flags]
6. Database: [migration steps if applicable]
⚠ Gaps: [any setup steps missing from documentation]

---

### Established conventions
- Naming: [...]
- Error handling: [...]
- Testing: [...]
- Traceability marker: [...]

---

### 10 things to know before touching code
1. [...]
2. [...]
...
10. [...]

---

### Documentation gaps
[Anything that should be documented but isn't — flag for the team to fill in]

---

@di-review-required
```

## Common Rationalizations

These are the statements that get codebase onboarding skipped. Rebut them.

| Rationalization | Reality |
|----------------|---------|
| "New developers should just read the code" | Reading code without context produces a distorted mental model. Knowing what the code does is different from knowing why it's structured that way, where the seams are, and what is safe to change. |
| "We'll pair them with a senior dev instead" | Pairing is valuable — and time-limited. An onboarding guide is always available at 11pm when the senior dev is not. Both are needed. |
| "The README covers enough" | READMEs describe how to run the code, not how the system is designed. Architecture, layer boundaries, key invariants, and known traps are what orient a developer, not installation steps. |
| "Our codebase is too large to document" | A large codebase is exactly the one that needs an orientation guide. The cognitive cost of navigating an undocumented large codebase is measured in days, not hours. |

## Governance

- Describe what IS in the code, not what should be — this guide is for
  orientation, not prescription
- Never fabricate architecture connections that cannot be read from the code
- Flag documentation gaps explicitly so the team knows what to add
- The guide is a draft — mark with `@di-review-required`; a team member who
  knows the codebase must verify before sharing with a new hire
- Do not include secrets, credentials, or internal URLs in the output

## Related Skills

- `/explain-code` — file-level explanation for a new developer who needs to
  understand a specific module once they are oriented
- `/review-architecture` — runs the DI lens on the architecture to find
  problems; this skill describes what exists, not what is wrong
- `/identify-dependencies` — after onboarding, use to map which teams or
  services a new developer must coordinate with for their first task
- `/dev-iq-tailor` — if the pack config has not been tailored to this repo,
  run tailor first so this guide picks up the correct stack and conventions
