---
name: review-architecture
description: Review an architecture or design proposal against the DI DESIGN signal layer. Use when asked to "review this design", "is this architecture sound", "check this proposal", or "review the system design".
di_signal: DESIGN + RISK
maturity_required: early
status: approved
---

# Review Architecture

## Overview
Reviews an architecture or design proposal against the DI DESIGN signal layer,
assessing layer separation, dependency direction, scalability assumptions,
coupling, single points of failure, and data flow — then issues a structured
verdict: Go, Go with recommendations, or Hold.

Unlike code review (which operates at the function level), architecture review
operates at the system level: the question is not whether the code is clean,
but whether the system is structured in a way that can be built, operated, and
changed safely over time.

## When to Use
- When a new service, module, or system is being designed before implementation
- When a significant refactoring proposes a structural change to the system
- When a PR or design doc introduces a new architectural pattern not previously
  used by the team
- When a team is evaluating two competing architectural approaches
- When an existing architecture has grown organically and needs a formal assessment
- Any time the user says: "review this design", "is this architecture sound",
  "check this proposal", "review the system design", "is this how we should
  structure this"

## Instructions

### Step 1: Read the Architecture Artifact
**From a design document or diagram description:**
- Accept the document or description directly
- Note what is explicitly described vs. what is implied

**From a PR or codebase:**
- Read the relevant files to understand the structural boundaries
- Map the layers (controller/handler → service → repository/data access)
- Map the dependencies (what calls what)

Ask for (if not determinable):
- The system's expected load characteristics (single-tenant, multi-tenant, batch, real-time)
- Known non-functional requirements (availability SLA, latency targets, data volume)
- The team's established architectural patterns (what is the existing norm?)

Load context:
- `.dev-iq/config.yaml` → `stack`, `workspace.role`
- Existing architectural patterns in the codebase

### Step 2: Assess DESIGN Signal Across Six Dimensions

**Layer Separation**
Does each layer have a clear, single responsibility?
- Controllers/handlers: receive request, delegate to service, return response — no business logic
- Services: business logic only — no direct data access
- Repositories/data access: persistence only — no business logic
- Cross-cutting concerns (logging, auth, caching): in middleware or interceptors

Fail conditions: business logic in a controller; direct DB call from a service;
mixing request handling and business logic in the same class.

**Dependency Direction**
Do dependencies flow in one direction (from outer to inner layers)?
- Controllers depend on services; services depend on interfaces/repositories
- No circular dependencies
- Concrete implementations hidden behind interfaces

Fail condition: circular dependency between any two components. Always a Hold.

**Coupling**
How tightly are components bound to each other?
- Loose coupling: components communicate via well-defined interfaces or events
- Tight coupling: one component directly instantiates or imports from another's
  internals; a change to one requires changes to others

High coupling is a RISK finding — it multiplies the blast radius of any change.

**Scalability Assumptions**
Are the stated or implied scalability assumptions realistic?
- Stateless services can scale horizontally; stateful services cannot
- Shared mutable state (in-memory cache, singleton counters) breaks under multiple instances
- Database connection limits under concurrency
- Synchronous chains that block under load

Flag any assumption that is not documented — an undocumented assumption is
a hidden risk.

**Single Points of Failure**
Are there components whose failure brings down the entire system?
- No retry or circuit breaker on external service calls
- No fallback when a critical dependency is unavailable
- Single database with no read replica or failover

**Data Flow**
Is the data flow through the system clear, traceable, and secure?
- Can a request be traced from entry point to storage and back?
- Is PII flowing through layers where it should not be logged?
- Are there any data fan-outs (one write triggers many others) that are not bounded?

### Step 3: Identify Hold Conditions
The following conditions always produce a Hold verdict:

- Circular dependencies between components
- No clear layer separation (business logic mixed with data access across the design)
- Tight coupling to an external service with no abstraction layer (vendor lock-in risk)
- No documented failure mode for a critical integration point
- A single point of failure with no mitigation in a system with an availability SLA

### Step 4: Issue Verdict

| Verdict | Meaning |
|---------|---------|
| **Go** | All six dimensions STRONG — design is structurally sound |
| **Go with recommendations** | No Hold conditions, but Medium or Low findings that should be addressed |
| **Hold** | One or more Hold conditions present — design must be revised before implementation begins |

At **Early maturity**: include coaching notes on each Hold condition explaining
the production consequence. Verdicts are advisory — team makes the final call.

At **Mid/Higher maturity**: structured assessment and verdict only.

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Architecture document, diagram, or description | Paste, file path, or PR link | Yes |
| Non-functional requirements | User states or inferred | Recommended |
| Existing architectural patterns | Codebase or user states | Auto-read if path provided |
| Load characteristics | User states | Recommended |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## Architecture Review — [System or Feature Name]
Work Item: [AB#XXXX | PROJ-XXX | #456 | "none provided"]
Assessed: [date]

---

### INTENT Assessment
[Does the architecture address the stated requirements? Any alignment gaps?]

---

### DESIGN Signal Assessment

| Dimension | Rating | Finding |
|-----------|--------|---------|
| Layer Separation | [STRONG/WEAK/FAIL] | [finding or "none"] |
| Dependency Direction | [STRONG/WEAK/FAIL] | |
| Coupling | [STRONG/WEAK/FAIL] | |
| Scalability Assumptions | [STRONG/WEAK/UNGRADED] | |
| Single Points of Failure | [STRONG/WEAK/FAIL] | |
| Data Flow | [STRONG/WEAK/UNGRADED] | |

---

### Findings

**[Severity] Finding 1 — [Dimension]**
- Issue: [description]
- Impact: [what goes wrong in production or under change]
- Recommended change: [specific design adjustment]

[Repeat for each finding]

---

### Hold Conditions (if any)
- [Hold condition 1 — must be resolved before implementation begins]

---

### Verdict: [Go | Go with recommendations | Hold]

**Rationale:** [1–3 sentences explaining the verdict]

**If Go with recommendations:**
Recommendations (address before next major release):
1. [Recommendation 1]

**If Hold:**
Blocking issues (must resolve before implementation begins):
1. [Blocking issue 1]
2. [Blocking issue 2]

---

@di-review-required
```

## Examples

### Example 1: Microservice Design — Clean Domain Boundaries (Go)

**User provides:** "We're designing an order service. It has a REST API layer
that calls an OrderService class. OrderService uses an IOrderRepository interface.
The repository implementation talks to PostgreSQL. Email notifications go through
an INotificationClient interface. The service never calls the database directly."

**Result:**

```
## Architecture Review — Order Service
Work Item: none provided
Assessed: 2026-06-06

---

### INTENT Assessment
STRONG — the design is consistent with the stated requirement of handling order
creation and notification.

---

### DESIGN Signal Assessment

| Dimension | Rating | Finding |
|-----------|--------|---------|
| Layer Separation | STRONG | Controller → Service → Repository clearly separated |
| Dependency Direction | STRONG | All dependencies point inward; no circular references |
| Coupling | STRONG | External dependencies (DB, email) hidden behind interfaces |
| Scalability Assumptions | STRONG | Stateless service design supports horizontal scaling |
| Single Points of Failure | WEAK | No circuit breaker mentioned for notification client |
| Data Flow | STRONG | Request path traceable; PII not logged |

---

### Findings

**⚪ Low Finding 1 — Single Points of Failure**
- Issue: No circuit breaker or fallback documented for INotificationClient.
  If the notification service is unavailable, the order workflow may be affected.
- Impact: Order confirmation emails fail to send; depending on error handling,
  the order creation may also fail.
- Recommended change: Add a note on the expected behavior when the notification
  client is unavailable — either fail-open (order succeeds, notification retried
  async) or fail-closed (order fails if notification unavailable). Document the
  chosen behavior.

---

### Hold Conditions
None.

---

### Verdict: Go with recommendations

**Rationale:** Layer separation and dependency direction are clean. The single
recommendation is advisory — document the notification failure behavior before
the first production incident makes the decision under pressure.

Recommendations:
1. Document the notification failure mode and add a circuit breaker or async
   retry queue for the notification client.

---

@di-review-required
```

---

### Example 2: Monolith with Business Logic in Controllers (Hold)

**User provides:** "We have controllers that call the database directly using
the ORM. Business logic like discount calculations and inventory checks also
live in the controllers."

**Result:**

```
## Architecture Review — Current Monolith Structure
Work Item: none provided
Assessed: 2026-06-06

---

### DESIGN Signal Assessment

| Dimension | Rating | Finding |
|-----------|--------|---------|
| Layer Separation | FAIL | Business logic and data access both in controllers |
| Dependency Direction | WEAK | Controllers depend directly on ORM models (concrete, not abstracted) |
| Coupling | FAIL | Business logic tightly coupled to HTTP request lifecycle |
| Scalability Assumptions | UNGRADED | Cannot assess without load data |
| Single Points of Failure | WEAK | No data on resilience patterns |
| Data Flow | WEAK | Business logic in controllers makes PII logging risk harder to audit |

---

### Findings

**🔴 Critical Finding 1 — Layer Separation**
- Issue: Discount calculations and inventory checks live in HTTP controllers.
  Business logic must not live in the request handling layer.
- Impact: Business rules cannot be tested without an HTTP context; they
  cannot be reused across API endpoints, background jobs, or CLI commands;
  a change to a business rule requires navigating HTTP routing code.
- Recommended change: Extract all business logic to service classes.
  Controllers call services; services contain no HTTP concepts.

**🟠 High Finding 2 — Coupling**
- Issue: Controllers directly instantiate ORM models — no repository
  interface between the controller and the database.
- Impact: The database cannot be swapped, mocked in tests, or behind
  a caching layer without changing every controller.
- Recommended change: Introduce repository interfaces. Controllers depend
  on the interface; the ORM implementation is injected.

---

### Hold Conditions
- Business logic in controllers violates layer separation throughout the system.
  The architecture must be restructured before new features are added to this surface.

---

### Verdict: Hold

**Rationale:** Two Hold conditions present. The current architecture will
compound technical debt with every feature added. Refactoring to a proper
service/repository pattern should precede new feature development in these
controllers.

Blocking issues:
1. Extract business logic (discount, inventory) to service classes.
2. Introduce IOrderRepository (or equivalent) to abstract data access.

---

@di-review-required
```

---

### Example 3: Early Maturity — Coaching Note on a Hold Condition

```
**Hold Condition: Business logic in controllers**

**DI Coaching Note (Early maturity):** This pattern feels harmless at first —
putting the logic "right next to" the route is convenient. The cost shows
up when you need to: (1) call the same business rule from a background job,
(2) write a unit test without spinning up an HTTP server, (3) add a second
API endpoint for the same operation. At that point you either duplicate the
logic or you refactor. The service/repository pattern exists specifically to
pay this cost once, upfront, rather than many times later under pressure. The
refactor is two steps: move business logic to a service class, inject the
service into the controller. It's 2–3 hours now or a week of tangled refactoring
when the codebase is twice the size.
```

---

## Governance
- Go verdict may only be issued when all six dimensions are rated STRONG or have
  only Low findings — any Medium or High finding produces "Go with recommendations"
  and any Hold condition produces "Hold"
- Hold conditions are not negotiable based on delivery pressure — report the
  finding; the team decides whether to proceed and documents the exception
- UNGRADED dimensions (where data is not available to assess) do not produce a Go
  — they produce "Go with recommendations" if no other blocker exists, with the
  UNGRADED dimension explicitly called out
- All output carries `@di-review-required` — architecture assessments are advisory;
  the human architect and team make the final structural decisions
- At Early maturity, every Hold condition includes a coaching note explaining the
  production consequence, not just the fix
- Never produce a Go verdict when a circular dependency is present — this is a
  hard block regardless of maturity tier or delivery pressure

## Related Skills
- `/generate-adr` — when a review surfaces a significant architectural decision,
  generate an ADR to capture the context and rationale
- `/blast-radius-estimator` — after a Hold condition is resolved, estimate the
  blast radius of the structural changes before implementing them
- `/refactor-code` — use to address DESIGN findings at the code level once the
  architectural direction is confirmed
- `/review-deployment-readiness` — architecture review is a prerequisite input
  to deployment readiness for new service launches
