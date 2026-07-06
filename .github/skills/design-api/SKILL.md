---
name: design-api
description: Design a REST or GraphQL API from a requirements description, producing endpoint definitions, request/response shapes, and error contracts. Use when asked to "design an API", "spec out endpoints", "create an API contract", or "define the REST interface".
di_signal: DESIGN
maturity_required: early
status: approved
---

# Design API

## Overview
Designs a REST or GraphQL API from a requirements description, producing a
structured endpoint definition with resource model, request/response schemas,
HTTP status codes, authentication requirements, and an error contract.

The DESIGN signal is assessed before producing any schema: if the requirements
do not clearly define the actors, the data being exchanged, or the operations
needed, the skill surfaces those gaps rather than generating an API contract
that will need to be redesigned after the first round of review.

## When to Use
- When starting a new service or feature that needs a public API contract
- When a frontend team needs a backend contract to begin development in parallel
- When reviewing a proposed API design for structural problems before implementation
- When an existing API needs to be versioned and the new version must be designed
- When a work item requires a new endpoint and the team needs a shared spec
- Any time the user says: "design an API", "spec out endpoints", "what should
  this API look like", "create an API contract", "define the REST interface",
  "what endpoints do we need for this feature"

## Instructions

### Step 1: Gather Requirements
**From a work item or feature description:**
- What operations are needed (list, get, create, update, delete, state transition)?
- Who are the callers (web client, mobile app, another service)?
- What data is exchanged in each operation?
- What authentication model is in place (JWT, API key, session)?

Ask for (if not determinable):
- Expected load characteristics (high-frequency reads, infrequent writes?)
- Versioning requirements (new service, or adding to an existing API?)
- Rate limiting requirements (are any endpoints sensitive to abuse?)
- Any existing conventions (read adjacent controllers/routes first)

Load context:
- `.dev-iq/config.yaml` → `stack` for language, framework, and API conventions
- Adjacent route/controller files for established naming and response conventions

### Step 2: Assess INTENT Clarity
Before designing, verify requirements are grounded:

**Clear enough when:**
- The primary resource or domain entity is named
- The operations on that resource are described
- The caller context is known

**Not clear enough when:**
- Only a feature name is given with no operations described
- The data shape is entirely unknown with no analogous entity in the system
- There is a conflict between what the API must do and the system's existing data model

If INTENT is unclear: surface the gap and ask before generating any endpoint definitions.

### Step 3: Propose the Resource Model
Define the primary resource(s) before designing endpoints:
- Canonical resource name (noun, singular: `order`, `user`, `payment`)
- Fields, types, and constraints
- Relationships to other resources

### Step 4: Design Endpoints
Apply REST conventions (or GraphQL if specified):

**REST conventions:**
- Paths use plural nouns: `/orders`, `/users`
- Nested resources for ownership: `/orders/{orderId}/items`
- HTTP verbs carry the operation: GET (read), POST (create), PUT/PATCH (update), DELETE (remove)
- IDs in path segments; filters, sort, pagination in query params
- State transitions: `/orders/{id}/cancel` is acceptable when no sub-resource exists

**For each endpoint define:**
- Method + path
- Path parameters and constraints
- Query parameters (for list operations)
- Request body schema (for POST/PUT/PATCH)
- Success response schema and HTTP status code
- Authentication requirement
- Rate limiting recommendation (for sensitive operations)

### Step 5: Define the Error Contract
A consistent error contract is part of the design, not an afterthought.

Standard error codes and HTTP mappings:
- `VALIDATION_ERROR` → 400
- `UNAUTHORIZED` → 401
- `FORBIDDEN` → 403
- `NOT_FOUND` → 404
- `CONFLICT` → 409
- `INTERNAL_ERROR` → 500

Error response shape:
```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Order with ID abc123 was not found.",
    "details": {}
  }
}
```

### Step 6: Apply DESIGN Checks
Review the design against six dimensions:
- **REST conventions**: noun-based paths, verbs only for state transitions
- **Authentication**: every non-public endpoint protected
- **Versioning**: `/v1/` prefix present for any new API
- **Rate limiting**: auth, payment, email-send endpoints must be rate-limited
- **Idempotency**: financial and notification POST endpoints need an idempotency key
- **Pagination**: list endpoints must support pagination — unbounded list is a RISK finding

At **Early maturity**: add a coaching note for each DESIGN finding.
At **Mid/Higher maturity**: structured findings only.

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Feature or requirements description | Work item ID, paste, or user description | Yes |
| Authentication model | User states or inferred from existing API | Required |
| Caller context (web, mobile, service) | User states | Required |
| Existing API conventions | Adjacent route/controller files | Auto-read if path provided |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## API Design — [Feature Name or Work Item ID]
Work Item: [AB#XXXX | PROJ-XXX | #456 | "none provided"]
Design Type: [REST | GraphQL]
Assessed: [date]

---

### INTENT Assessment
[Is the requirement clear enough to design? State any gaps.]

---

### Resource Model

**[ResourceName]**
| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | string (UUID) | required, immutable | system-generated |
| [field] | [type] | [constraints] | [notes] |

---

### Endpoints

#### [METHOD] /v1/[path]
**Purpose:** [one-line description]
**Auth:** [required — JWT bearer | API key | public]
**Rate limit:** [recommended limit if sensitive]

**Path Parameters:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|

**Query Parameters (list endpoints):**
| Param | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|

**Request Body:**
```json
{ "field": "type — description" }
```

**Success Response — [HTTP status]:**
```json
{ "field": "type — description" }
```

[Repeat for each endpoint]

---

### Error Contract

| Code | HTTP Status | When |
|------|-------------|------|
| VALIDATION_ERROR | 400 | Request body fails schema validation |
| UNAUTHORIZED | 401 | Missing or invalid authentication |
| FORBIDDEN | 403 | Valid token, insufficient permissions |
| NOT_FOUND | 404 | Resource ID not found |
| CONFLICT | 409 | Duplicate resource or state conflict |
| INTERNAL_ERROR | 500 | Unhandled server error |

---

### DESIGN Signal Assessment

| Dimension | Assessment | Finding (if any) |
|-----------|------------|-----------------|
| REST conventions | [Pass/Weak/Fail] | |
| Authentication | [Pass/Weak/Fail] | |
| Versioning | [Pass/Weak/Fail] | |
| Rate limiting | [Pass/Weak/Fail] | |
| Pagination | [Pass/Weak/N/A] | |
| Idempotency | [Pass/Weak/N/A] | |

**DESIGN Signal: [STRONG | WEAK | UNGRADED]**

@di-review-required
```

## Examples

### Example 1: User Profile API

**User says:** "Design an API for managing user profiles. Users can view and
update their own profile. Admins can view any profile."

**Result (excerpted):**

```
## API Design — User Profile Management
Work Item: none provided
Design Type: REST
Assessed: 2026-06-06

---

### INTENT Assessment
STRONG — two operations (view, update), one resource (profile), two actor
types (user, admin). Sufficient to design.

---

### Resource Model

**UserProfile**
| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | string (UUID) | required, immutable | matches auth user ID |
| displayName | string | required, 1–100 chars | |
| bio | string | optional, max 500 chars | |
| avatarUrl | string (URL) | optional, HTTPS only | |
| email | string | required, immutable | sourced from auth token |
| updatedAt | string (ISO 8601) | system-set | |

---

### Endpoints

#### GET /v1/users/{userId}/profile
**Purpose:** Retrieve a user's profile
**Auth:** required — JWT bearer
**Rate limit:** 50 req/min per token

**Path Parameters:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| userId | UUID | Yes | The user whose profile to retrieve |

**Success Response — 200:**
```json
{
  "id": "uuid",
  "displayName": "string",
  "bio": "string | null",
  "avatarUrl": "string | null",
  "updatedAt": "ISO 8601 timestamp"
}
```

**Authorization rule:** Callers may retrieve their own profile (userId matches
token subject). Admins (token role = "admin") may retrieve any profile.
Any other combination returns 403 FORBIDDEN.

#### PATCH /v1/users/{userId}/profile
**Purpose:** Update the authenticated user's own profile
**Auth:** required — JWT bearer (own profile only)
**Rate limit:** 10 req/min per token

**Request Body:**
```json
{
  "displayName": "string (optional, 1–100 chars)",
  "bio": "string | null (optional, max 500 chars)",
  "avatarUrl": "string | null (optional, HTTPS URL)"
}
```

**Success Response — 200:** Updated UserProfile object.

---

### DESIGN Signal Assessment

| Dimension | Assessment | Finding |
|-----------|------------|---------|
| REST conventions | Pass | noun-based paths, correct verbs |
| Authentication | Pass | JWT required, auth rules explicit |
| Versioning | Pass | /v1/ prefix present |
| Rate limiting | Pass | conservative limit on write endpoint |
| Pagination | N/A | single-resource endpoints |
| Idempotency | Pass | PATCH is idempotent by HTTP semantics |

**DESIGN Signal: STRONG**

@di-review-required
```

---

### Example 2: Payment Endpoint — Idempotency and Rate Limit Findings

**User says:** "We need a POST /payments endpoint to charge a card for an order."

**Findings excerpt:**

```
### DESIGN Signal Assessment

| Dimension | Assessment | Finding |
|-----------|------------|---------|
| Idempotency | Fail | No idempotency key on POST /payments — retry creates double charge |
| Rate limiting | Weak | No rate limit specified on payment creation |
| Versioning | Weak | /payments not /v1/payments |

**🔴 Critical — Idempotency missing**
- Issue: POST /payments with no idempotency key means a network retry or
  accidental double-submit creates two charges for the same order.
- Recommended fix: Accept an `Idempotency-Key` header. Cache responses for
  24 hours keyed on the value. Return the cached response on retry.

**🟠 High — No rate limit on payment endpoint**
- Issue: Unrate-limited payment creation enables card testing attacks.
- Recommended fix: 5 requests per minute per authenticated user.

**DESIGN Signal: WEAK** — two findings must be addressed before implementation.
```

---

### Example 3: Ambiguous Requirement — INTENT Gap Raised Before Designing

**User says:** "Design an API for the reporting module."

**Result:**

```
## API Design — Reporting Module
Assessed: 2026-06-06

---

### INTENT Assessment
WEAK — "reporting module" does not identify the operations, data, callers, or
output format. Three clarifying questions required before design:

1. What reports exist? (e.g. sales summary, user activity, revenue by period)
2. Who calls this API? (a dashboard frontend, a scheduled export, another service?)
3. What is the output format? (paginated JSON, file download, streaming response?)

API design will begin once these questions are answered.

@di-review-required
```

---

## Common Rationalizations

These are the statements that get API design skipped or rushed. Rebut them.

| Rationalization | Reality |
|----------------|---------|
| "We'll document the API after we build it" | Post-hoc documentation describes what was built, not what was intended. Contract-first design catches disagreements before they're baked into code that consumers depend on. |
| "Just make it work for now, we'll redesign it later" | APIs are contracts. Once consumers depend on a shape, changing it is a breaking change. The "temporary" design becomes permanent the moment the first caller ships. |
| "The client knows what they need, I'll build what they asked for" | What clients ask for and what they need diverge most visibly at the API layer. Design review surfaces that gap before implementation, not at integration time. |
| "REST is obvious, we don't need a design skill for it" | Naming consistency, error semantics, versioning strategy, and pagination shape are where most API tech debt originates — not in the HTTP verb choice. |

## Governance
- DESIGN signal may only be STRONG when all six dimensions are assessed as Pass —
  an unchecked dimension is UNGRADED, not implicitly Pass
- Endpoints for authentication, payment, or notification operations must be
  evaluated for rate limiting and idempotency — not optional
- No new dependencies or frameworks may be introduced without explicit team
  confirmation
- All output carries `@di-review-required` — the API design is a draft for team
  review before implementation begins; the contract is not final until agreed
- Error contracts must always include the six standard codes defined above —
  a generic 500-only error contract is a DESIGN finding
- At Early maturity, every DESIGN finding includes a coaching note explaining
  the production consequence of leaving it unaddressed

## Related Skills
- `/design-data-model` — design the underlying data model before or alongside
  the API design; the resource model should reflect the data model
- `/generate-adr` — if the design makes a significant architectural choice
  (REST vs. GraphQL, versioning strategy, auth model), generate an ADR
- `/review-security` — after designing the API, run a security review on the
  auth, authorization, and input validation surfaces
- `/blast-radius-estimator` — if the design extends an existing contract, estimate
  the blast radius of any changes to existing endpoints
