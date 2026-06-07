---
name: identify-dependencies
description: Surface blockers, external dependencies, and delivery risks for a work item before work begins. Use when asked to "find blockers", "what are the dependencies", "what could block this", or "pre-flight this story".
di_signal: INTENT + RISK
maturity_required: early
status: approved
---

# Identify Dependencies

## Overview
Maps the technical, team, and external dependencies for a work item before
development begins, rating each dependency by severity and recommending a
resolution order. The goal is to surface blockers at planning time — not
mid-sprint when a developer is blocked and waiting.

This skill applies both INTENT (is the scope clear enough to identify what
depends on it?) and RISK (what is the probability and impact of each dependency
becoming a blocker?). A dependency that is not identified before sprint start
is an unmanaged risk — it will manifest, just unpredictably.

## When to Use
- During sprint planning before committing to a story
- During backlog refinement when assessing delivery risk of a work item
- When a work item involves a shared service, schema change, or third-party integration
- When a feature spans multiple teams and sequencing matters
- Before raising a PR for a change that touches shared infrastructure
- Any time the user says: "find blockers", "what are the dependencies for this",
  "what could block this story", "pre-flight this", "map the risks before we start"

## Instructions

### Step 1: Read the Work Item and Scope
**From a work item ID:**
- Read the title, description, and acceptance criteria
- Note any referenced systems, services, or teams

**From a feature description:**
- Accept the description
- Identify the systems, services, schemas, and teams mentioned explicitly
  or implied by the domain

Ask for (if not determinable):
- Which environment the work targets (prod, staging, dev)
- Whether any related work items are already in flight that might conflict
- The expected delivery date (affects which dependencies are Blocking vs. advisory)

### Step 2: Scan Across Four Dependency Categories

**Technical dependencies — shared infrastructure**
- Database schemas that must be extended or migrated before the feature works
- APIs or services the feature calls that do not yet exist or need new endpoints
- Shared libraries or utilities being changed by another team concurrently
- Configuration changes (environment variables, feature flags) that must be
  in place before deployment
- Infrastructure provisioning (new queues, buckets, certificates) with lead times

**Team dependencies — human coordination**
- Another team that must deliver a component before this work can be tested
- A design sign-off required before implementation can start
- A security review required before an endpoint can be exposed
- QA resourcing required for a feature that cannot be self-tested by the developer

**External dependencies — outside the organization**
- Third-party API availability (sandbox access, credentials, rate limits)
- Client or stakeholder approval required at a specific milestone
- Vendor SLA or contract that governs when a service can be used
- Compliance or legal review triggered by the feature's data handling

**Sequencing constraints — ordering within the sprint**
- Story B cannot start until Story A's schema migration is deployed
- Story C requires an environment variable that Story D's deployment sets
- Multiple stories writing to the same table (conflict risk during development)

### Step 3: Rate Each Dependency

| Rating | Meaning |
|--------|---------|
| **Blocker** | Work cannot proceed until resolved — starting now wastes effort |
| **Risk** | Work can proceed but this could cause a mid-sprint stoppage or rework |
| **FYI** | Worth noting for coordination; unlikely to block delivery |

### Step 4: Recommend Resolution Order
1. Address Blockers first — resolve before committing to the sprint
2. Assign owners and confirmation dates to Risks
3. Share FYIs with relevant teams and proceed

At **Early maturity**: include a coaching note for each Blocker explaining why
starting before resolution wastes effort in this specific case.

At **Mid/Higher maturity**: produce the structured table and sequence only.

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Work item or feature description | Work item ID or paste | Yes |
| Target environment | User states or inferred | Recommended |
| Related in-flight work items | User provides | Optional — improves risk rating |
| Delivery date or sprint boundary | User provides | Optional — affects Blocker vs. Risk |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## Dependency Map — [Work Item ID or Feature Name]
Work Item: [AB#XXXX | PROJ-XXX | #456 | "none provided"]
Assessed: [date]

---

### INTENT Assessment
[1–2 sentences: is the work item scoped clearly enough to identify dependencies?
State any gaps.]

---

### Dependency Table

| # | Dependency | Type | Rating | Owner | Status | Notes |
|---|-----------|------|--------|-------|--------|-------|
| 1 | [description] | Technical | Blocker | [team/person] | Unknown | [context] |
| 2 | [description] | Team | Risk | [team/person] | In Progress | [context] |
| 3 | [description] | External | FYI | [team/person] | Known | [context] |

---

### Blockers — Resolve Before Sprint Commitment

**Blocker 1: [Name]**
- What: [description]
- Why it blocks: [what cannot proceed without it]
- Owner: [who resolves this]
- Recommended action: [specific next step and typical lead time]

---

### Risks — Monitor and Assign Owners

**Risk 1: [Name]**
- What: [description]
- Impact if it fires: [rework or delay]
- Owner: [who monitors]
- Trigger: [what would escalate this to a Blocker]

---

### FYI Dependencies
- [Dependency name] — [one-line description, owner, no action required]

---

### Recommended Start Sequence
1. [Resolve Blocker 1 — action and owner]
2. [Confirm Risk 1 status — by what date]
3. [Begin implementation once blockers are cleared]

---

### RISK Signal: [STRONG | WEAK | UNGRADED]

@di-review-required
```

## Examples

### Example 1: Feature with 3 Blockers and 2 Risks

**User says:** `/identify-dependencies` for AB#3301 — "Add Stripe payment integration to checkout"

**Result:**

```
## Dependency Map — AB#3301: Add Stripe payment integration to checkout
Work Item: AB#3301
Assessed: 2026-06-06

---

### INTENT Assessment
STRONG — scope is well-defined: Stripe integration at checkout, covering charge
creation and order status update. Sufficient to identify dependencies.

---

### Dependency Table

| # | Dependency | Type | Rating | Owner | Status | Notes |
|---|-----------|------|--------|-------|--------|-------|
| 1 | Stripe sandbox credentials provisioned | External | Blocker | Platform | Unknown | No keys in dev env |
| 2 | orders table: add charge_id column | Technical | Blocker | DB team | Unknown | Migration required pre-integration |
| 3 | PCI-DSS scoping review | External | Blocker | Security | Not started | Card data path triggers review |
| 4 | Payment service library v2 | Technical | Risk | Backend | In Progress | v1 API is incompatible |
| 5 | QA environment webhook config | Technical | Risk | DevOps | Unknown | End-to-end tests require webhooks |
| 6 | Stripe rate limit policy reviewed | External | FYI | Any | Known | Sandbox limits lower than production |

---

### Blockers

**Blocker 1: Stripe sandbox credentials**
- What: No Stripe API keys exist in the development environment.
- Why it blocks: Development and tests both fail at the integration boundary
  without credentials — even mocking cannot fully substitute.
- Owner: Platform team
- Recommended action: Request Stripe sandbox project from Platform before sprint
  planning. Typical lead time: 1 business day.

**Blocker 2: orders table migration**
- What: The `charge_id` column does not exist on the `orders` table.
- Why it blocks: Integration writes `charge_id` on success — without the column,
  every successful payment throws at the database layer.
- Owner: DB team
- Recommended action: Create and review migration PR before sprint start.

**Blocker 3: PCI-DSS scoping review**
- What: Any code path handling card data requires security review before merge.
- Why it blocks: The PR will be blocked at merge regardless of code quality
  until the review completes.
- Owner: Security team
- Recommended action: Open review ticket today with design doc attached.
  Reviews typically take 3–5 business days.

---

### Risks

**Risk 1: Payment library v2 timeline**
- What: Backend team is updating the payment service library to a v2 API.
- Impact if it fires: If v2 ships after this story, a rework cycle is needed.
- Owner: Backend team
- Trigger: If v2 is not merged by Sprint Day 3, escalate to PM.

**Risk 2: QA webhook configuration**
- What: Stripe webhook events are not routed to the QA environment.
- Impact if it fires: End-to-end testing must be done in staging instead of QA.
- Owner: DevOps
- Trigger: If not in place by Sprint Day 5, flag for QA coordination.

---

### FYI Dependencies
- Stripe rate limits — sandbox has lower thresholds than production. Use
  test mode sparingly to avoid rate errors mid-demo.

---

### Recommended Start Sequence
1. Request Stripe credentials from Platform (Blocker 1) — today
2. Raise migration PR for orders.charge_id (Blocker 2) — today
3. Open PCI-DSS review ticket (Blocker 3) — today
4. Confirm payment library v2 timeline with Backend (Risk 1) — EOD today
5. Confirm QA webhook config with DevOps (Risk 2) — Sprint Day 2
6. Begin implementation once Blockers 1 and 2 are confirmed resolved

---

### RISK Signal: WEAK
Three Blockers present. Do not commit this work item to a sprint until all
three have a confirmed resolution timeline.

@di-review-required
```

---

### Example 2: Clean Work Item with FYI Dependencies Only

**User says:** `/identify-dependencies` for AB#2870 — "Add 'remember me' checkbox to login form"

**Result:**

```
## Dependency Map — AB#2870: Add 'remember me' checkbox to login form
Work Item: AB#2870
Assessed: 2026-06-06

---

### INTENT Assessment
STRONG — narrow scope: UI checkbox + session persistence duration change.
No external integrations or schema changes required.

---

### Dependency Table

| # | Dependency | Type | Rating | Owner | Status | Notes |
|---|-----------|------|--------|-------|--------|-------|
| 1 | Design sign-off on checkbox placement | Team | FYI | Design | In review | Mockup exists |
| 2 | Cookie policy coverage check | External | FYI | Legal | Existing | Extended session duration may be covered |

---

### Blockers
None.

### Risks
None.

### FYI Dependencies
- Design sign-off — confirm placement before starting UI to avoid rework.
- Cookie policy — confirm the extended session duration is covered by the
  existing consent policy. No new legal work expected.

---

### Recommended Start Sequence
1. Confirm design sign-off status (FYI) — 5 minutes
2. Verify cookie policy coverage (FYI) — quick check with legal contact
3. Begin implementation — no blockers

---

### RISK Signal: STRONG
No blockers or risks. Work can begin immediately after FYI confirmations.

@di-review-required
```

---

### Example 3: Early Maturity — Coaching Note on a Blocker

```
**Blocker 2: orders table migration**
...

**DI Coaching Note (Early maturity):** Starting implementation before a required
schema migration is deployed is one of the most common "works on my machine,
breaks in QA" failure modes. The developer writes code against a locally-applied
migration; CI and QA environments don't have it yet; tests pass locally and fail
everywhere else. The fix is simple: merge the migration PR, let it deploy to all
environments, then start the feature. The two-day delay upfront saves a half-day
of confused debugging later — and avoids a broken QA environment mid-sprint.
```

---

## Governance
- Blockers must be communicated to the team before a story is committed to a sprint —
  a Blocker discovered mid-sprint is a process gap, not a sprint failure
- RISK signal may only be STRONG when all dependencies are either resolved or
  confirmed as FYI — any Blocker or unowned Risk makes the signal WEAK
- External dependencies (third-party APIs, client approvals) with unknown lead
  times are always rated Risk or higher, never FYI
- Never start the dependency map without reading the full work item including
  ACs — dependencies embedded in ACs are real blockers, not hypotheticals
- All output carries `@di-review-required` — dependency maps are drafts;
  the team must verify ownership and status before relying on the map
- At Early maturity, every Blocker includes a coaching note explaining why
  starting before resolution wastes effort in the specific case

## Related Skills
- `/generate-user-stories` — run before this skill; stories must exist before
  dependencies can be mapped against them
- `/blast-radius-estimator` — if a technical dependency involves changing a shared
  interface, estimate the blast radius before committing to the change
- `/review-deployment-readiness` — after delivery, verify that all dependencies
  identified here were resolved before the release goes to production
- `/generate-rollback-plan` — for schema change or external integration dependencies,
  generate a rollback plan alongside the dependency map
