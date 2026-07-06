---
name: generate-adr
description: Generate an Architecture Decision Record (ADR) for a technical decision. Use when asked to "write an ADR", "document this decision", "create an architecture record", or "capture why we chose X".
di_signal: DESIGN
maturity_required: early
status: approved
---

# Generate ADR

## Overview
Generates a MADR-style Architecture Decision Record (ADR) for a technical
decision — capturing the context, the decision made, the alternatives
considered, and the consequences (both positive and negative).

ADRs are the team's memory for decisions that would otherwise be invisible
in code. When a decision is not documented, it will be revisited expensively
— either by being reversed unknowingly, or by being debated again without
the original context. This skill surfaces that context at the moment the
decision is fresh.

## When to Use
- When a significant technical decision is being made (choosing a database,
  adopting an architectural pattern, selecting a third-party service)
- When a design review or PR review surfaces a decision that should be recorded
- When refactoring reveals a historical decision that has never been documented
- When an existing ADR needs to be superseded by a new decision
- When the `/design-api` or `/design-data-model` skills produce a design
  choice that warrants a formal record
- Any time the user says: "write an ADR", "document this decision", "capture
  why we chose X", "create an architecture record", "why did we decide to use Y"

## Instructions

### Step 1: Gather Decision Context
Ask for (if not already provided):
- What was decided? (one-sentence statement of the decision)
- What was the context that made this decision necessary?
- What alternatives were considered and why were they not chosen?
- What are the known consequences — both good and bad?
- What status should this ADR carry? (Proposed / Accepted / Deprecated / Superseded)

If the user provides only the chosen option: ask explicitly about alternatives
before generating. An ADR that documents only the chosen path is incomplete —
the value of an ADR is understanding why alternatives were rejected.

**Strict rule on alternatives:** Only list alternatives the user explicitly
confirms were evaluated by the team. Do not generate plausible alternatives
from domain knowledge and present them as considered — this fabricates the
decision record. If the user cannot name any alternatives, ask: "Which options
did the team evaluate and reject?" If the answer is none, write the ADR with
an explicit statement: "Alternatives Considered: None — only one option was
evaluated." An honest single-option ADR is more valuable than an ADR with
invented alternatives that no one actually weighed.

Load context:
- `.dev-iq/config.yaml` → check if an ADR directory convention is configured
  (`adr.path`, default: `docs/adr/` or `docs/decisions/`)
- Existing ADRs in the directory for numbering and title style

### Step 2: Determine ADR Number and Status
- Read the existing ADR directory to determine the next sequential number
- Status values: `Proposed` (decision is under discussion), `Accepted`
  (decision is in effect), `Deprecated` (no longer applies, no replacement),
  `Superseded by ADR-NNNN` (replaced by a later decision)

### Step 3: Generate the ADR
Produce a MADR-style document with all required sections:

**Title:** ADR-NNNN: [Title in imperative mood — "Use PostgreSQL for primary data store"]

**Date:** [ISO 8601 format: YYYY-MM-DD]

**Status:** [Proposed | Accepted | Deprecated | Superseded by ADR-NNNN]

**Context:** What situation or force drove this decision? What was the problem
being solved? What constraints applied (team size, timeline, existing stack,
compliance requirements)?

**Decision:** What was decided, stated clearly and without hedging. The reader
should be able to implement or enforce the decision from this section alone.

**Alternatives Considered:** For each alternative rejected:
- Name and brief description
- Why it was not chosen (technical, organizational, or economic reason)

**Consequences:** What happens as a result of this decision?
- Positive: what does this enable or improve?
- Negative: what new constraints or costs does this introduce?
- Neutral: what changes but is neither clearly better nor worse?

**What Would Change This Decision:** What future conditions would cause this
ADR to be revisited or superseded? (Required — forces the author to think about
when the decision expires.)

### Step 4: Apply DESIGN Signal Assessment
An ADR is itself a DESIGN artifact. Assess it:
- Does it document at least one rejected alternative? (Required)
- Does it state both positive and negative consequences? (Required)
- Does it include the "What would change this" section? (Required)
- Is the decision statement unambiguous? (Required)

Any missing section is a DESIGN finding — prompt the user for the missing
context rather than fabricating it.

At **Early maturity**: add a coaching note explaining why each required section
exists and what goes wrong when it is absent.

At **Mid/Higher maturity**: produce the ADR and assessment only.

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Decision statement | User provides | Yes |
| Context / problem being solved | User provides | Yes |
| Alternatives considered | User provides | Yes — ask if missing |
| Consequences | User provides or inferred | Yes |
| ADR status | User states | Required |
| Work item ID | User provides | Recommended |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## ADR-[NNNN]: [Title in imperative mood]

**Date:** [YYYY-MM-DD]
**Status:** [Proposed | Accepted | Deprecated | Superseded by ADR-NNNN]
**Work Item:** [AB#XXXX | PROJ-XXX | "none"]

---

### Context

[2–4 sentences describing the situation, the problem, and the constraints
that made this decision necessary.]

---

### Decision

[1–3 sentences stating clearly what was decided. Imperative mood.
No hedging. Unambiguous enough to enforce in a code review.]

---

### Alternatives Considered

**[Alternative A name]**
[Brief description of the alternative]
Rejected because: [specific technical, organizational, or economic reason]

**[Alternative B name]**
[Brief description]
Rejected because: [reason]

---

### Consequences

**Positive:**
- [What this enables or improves]

**Negative:**
- [New constraints or costs this introduces]

**Neutral:**
- [What changes but is neither clearly better nor worse]

---

### What Would Change This Decision

[Specific future conditions under which this ADR would be revisited,
superseded, or deprecated. Examples: "If read throughput exceeds 50k req/s
and vertical scaling is no longer cost-effective", or "If the team adopts
a GraphQL federation layer that makes REST versioning redundant."]

---

@di-review-required
```

## Examples

### Example 1: Choosing PostgreSQL Over MongoDB

**User says:** "Write an ADR for our decision to use PostgreSQL as the primary
database instead of MongoDB."

**Result:**

```
## ADR-0004: Use PostgreSQL as the Primary Data Store

**Date:** 2026-06-06
**Status:** Accepted
**Work Item:** AB#1901

---

### Context

The team evaluated database options for the new platform. The primary data
consists of highly relational entities (users, orders, products, payments)
with complex reporting requirements across multiple entities. The team has
existing PostgreSQL expertise. Startup compliance requirements mandate ACID
guarantees for financial data.

---

### Decision

All production application data will be stored in PostgreSQL. MongoDB will
not be used as a primary data store. New services requiring persistent storage
must use PostgreSQL unless a subsequent ADR documents a specific exception.

---

### Alternatives Considered

**MongoDB (document store)**
A document model was evaluated for the product catalog, which has varying
attribute shapes per product type.
Rejected because: the relational query requirements (joins across orders, users,
and payments) are extensive. Emulating joins in a document store would add
significant application complexity. PostgreSQL's JSONB column type handles the
variable product attributes without sacrificing relational query capability.

**MySQL**
Functionally similar to PostgreSQL for this use case.
Rejected because: the team has deeper PostgreSQL expertise, PostgreSQL's JSONB
and window function support is more mature, and the existing infrastructure
tooling (migrations, monitoring) targets PostgreSQL.

**SQLite**
Considered for the test/local environment only.
Rejected for production because: no concurrent write support at the required
scale; no native replication.

---

### Consequences

**Positive:**
- ACID guarantees satisfy compliance requirements for financial data.
- Rich JOIN and window function support simplifies reporting queries.
- Team expertise shortens onboarding and reduces operational risk.

**Negative:**
- Horizontal write scaling requires additional architecture (sharding or
  read replicas + connection pooling) at high load — accepted tradeoff
  for this team size and current traffic projections.
- Schema migrations are required for structural changes — adds discipline
  overhead compared to a schemaless store.

**Neutral:**
- Variable product attributes handled via JSONB columns — slightly less
  ergonomic than a native document store but functionally equivalent.

---

### What Would Change This Decision

If write throughput exceeds 100k transactions per second and vertical scaling
is no longer cost-effective, a sharding strategy or migration to a distributed
SQL database (CockroachDB, Spanner) would be evaluated. If a service requires
pure document semantics with no relational requirements and PostgreSQL overhead
is measurably harmful, a targeted exception ADR would be appropriate.

---

@di-review-required
```

---

### Example 2: Superseding a Prior ADR

**User says:** "We decided to move from REST to GraphQL for the mobile API.
There's an existing ADR-0002 that says REST."

**Result:**

```
## ADR-0007: Adopt GraphQL Federation for the Mobile API Layer

**Date:** 2026-06-06
**Status:** Accepted — Supersedes ADR-0002

**Work Item:** AB#3301

---

### Context

ADR-0002 established REST as the API standard. Since then, the mobile team has
reported that REST endpoints require multiple round trips per screen, causing
performance issues on low-bandwidth connections. The mobile team has 4+
screens that each aggregate data from 3–5 REST endpoints. GraphQL federation
allows a single query to retrieve all required data and enables field-level
caching that REST cannot achieve with our current cache infrastructure.

---

### Decision

The mobile API layer will adopt GraphQL federation. The existing REST APIs
remain in place and are not deprecated — they continue to serve the web
client and third-party integrations. New mobile-facing data access will be
implemented as GraphQL resolvers. ADR-0002 is superseded for the mobile layer only.

---

### Alternatives Considered

**BFF (Backend for Frontend) REST service**
A dedicated REST service that aggregates the existing endpoints for mobile.
Rejected because: this adds another service to maintain and deploy, and the
performance problem is the number of round trips — a BFF reduces client trips
but does not enable field-level caching or subscriptions.

**gRPC**
Binary protocol with strong typing.
Rejected because: limited browser support (required for the web client) and the
team has no existing gRPC expertise.

---

### Consequences

**Positive:**
- Mobile screens reduced from 4+ round trips to 1 query.
- Field-level caching reduces backend load for common mobile queries.
- Schema introspection improves mobile developer experience.

**Negative:**
- Adds a GraphQL gateway to the deployment topology — new failure surface.
- Team requires GraphQL training (estimated: 2-day ramp per developer).
- Query complexity attacks require depth-limiting and complexity scoring
  in the gateway.

**Neutral:**
- REST APIs unchanged — zero impact on web client and third-party consumers.

---

### What Would Change This Decision

If the GraphQL gateway becomes a reliability bottleneck (p99 latency > 300ms
under load) and the gateway cannot be scaled further, reverting mobile to a
REST BFF would be evaluated. If the team shrinks to a point where maintaining
two API styles (REST + GraphQL) is impractical, consolidation would be assessed.

---

@di-review-required
```

---

### Example 3: Early Maturity — Coaching Note When Alternatives Are Missing

**User says:** "Write an ADR. We decided to use JWT for authentication."

At Early maturity, when the user provides no alternatives:

```
Before generating the ADR, one clarifying question is required:

What alternatives were considered and why were they not chosen?

Common alternatives for authentication: opaque session tokens (server-side
session store), OAuth2 with opaque tokens, PASETO.

**DI Coaching Note (Early maturity):** The alternatives section is the most
valuable part of an ADR — not the decision itself. The decision is visible
in the code. The alternatives are invisible. When a future engineer questions
why JWT was chosen, they should find the answer in the ADR, not have to
reconstruct the reasoning from Slack history or tribal knowledge. "We
considered session tokens but rejected them because we need stateless
horizontal scaling" is worth more than a two-page decision statement.
```

---

## Common Rationalizations

These are the statements that get ADR generation skipped. Rebut them.

| Rationalization | Reality |
|----------------|---------|
| "We don't need documentation for every decision" | ADRs are not for every decision — they're for significant ones that a future team member would question or want to reverse. If you'd struggle to explain the choice in six months, write the ADR now. |
| "Everyone on the team knows why we chose this" | The person who joins next quarter doesn't. The team six months into a product shift doesn't. An ADR costs 20 minutes and eliminates hours of archaeology. |
| "We'll document it after we ship" | After the ship, the context is gone — the rejected alternatives, the constraints that ruled them out, the tradeoffs that seemed obvious at the time. ADRs must be written while the decision is fresh. |
| "An ADR is too formal for a team our size" | The format can be as lightweight as the team needs. The value — recording the decision, the context, and the rejected alternatives — is independent of team size. |

## Governance
- ADRs must document at least one rejected alternative — an ADR with only the
  chosen option is a DESIGN finding and will not be generated without prompting
  the user for the missing context
- Both positive and negative consequences must be stated — an ADR that only
  documents benefits is misleading and will be flagged as a DESIGN finding
- The "What Would Change This Decision" section is required — decisions without
  an expiry condition become load-bearing tribal knowledge indefinitely
- ADRs are not modified after acceptance — if the decision changes, a new ADR
  is created with status "Superseded by ADR-NNNN"; the old ADR is updated to
  "Superseded" with a reference to the new one
- All output carries `@di-review-required` — the ADR is a draft until the team
  formally accepts it and assigns the Accepted status
- Never fabricate alternatives or consequences — if the user cannot provide them,
  ask; document only what is known
- Alternatives must be explicitly confirmed as evaluated by the user — never
  inferred from the domain or generated from general knowledge; fabricated
  alternatives create a false decision record that cannot be corrected by
  future readers

## Related Skills
- `/review-architecture` — if an architectural review surfaces a significant
  decision, generate an ADR to capture it
- `/design-api` — if the API design makes a significant architectural choice
  (REST vs. GraphQL, versioning strategy), generate an ADR from the design
- `/design-data-model` — if the data model includes an intentional denormalization
  or novel pattern, generate an ADR to document the tradeoff
- `/refactor-code` — if a refactor introduces or removes a significant pattern,
  an ADR may be warranted to document the transition
