---
name: blast-radius-estimator
description: Estimate the downstream impact of a proposed change — how many consumers, services, schemas, or teams are affected. Use when asked to "estimate blast radius", "what does this change affect", "who will this break", or "map the impact of this change".
di_signal: RISK
maturity_required: mid
status: approved
---

# Blast Radius Estimator

## Overview
Maps the downstream impact of a proposed change — identifying every consumer,
service, schema, or team that will be affected, rating each impact as Breaking,
Degraded, or Transparent, and producing a deployment sequencing recommendation.

At Early maturity this skill runs in advisory mode with simplified output.
At Mid and Higher maturity it produces a full structured blast radius map with
deployment sequencing and rollback trigger criteria.

## When to Use
- Before merging a change that touches a shared API contract, schema, interface,
  or utility
- When a refactor moves, renames, or removes a public function or endpoint
- Before a database schema change that multiple services or queries depend on
- When a team is evaluating whether a change can be feature-flagged or must be
  coordinated across multiple teams
- Before deprecating a feature or removing a field from a shared response
- Any time the user says: "estimate blast radius", "what does this change affect",
  "who will this break", "map the impact", "how many consumers does this touch"

## Instructions

### Step 1: Read the Diff or Change Description
**From a git diff:**
- Read the changed files
- Identify the change surface: what public interface, API endpoint, schema,
  or shared utility is being modified?

**From a description:**
- Accept the description
- Ask for the specific function/field/endpoint/table being changed if not stated

**At Early maturity:** Simplify — ask the user to describe the change surface
rather than attempting to scan the full codebase. Produce an advisory map.

### Step 2: Classify the Change Type

| Change Type | Description | Default Blast Radius |
|-------------|-------------|---------------------|
| API contract change | Modifying a REST endpoint (method, path, request shape, response shape) | High — all API consumers |
| Schema change | Adding/removing/renaming a database column or table | Medium to High |
| Interface change | Modifying a shared interface, abstract class, or type definition | Medium to High — all implementors and callers |
| Shared utility | Modifying a shared function, library, or helper used across the codebase | Medium — all callers |
| Config change | Environment variable, feature flag, or configuration key change | Low to High — depends on usage scope |
| Internal implementation | Private function, no public interface change | Low |

### Step 3: Identify Consumers

**INFERRED vs CONFIRMED distinction — apply to every consumer identified:**

Consumer relationships have two confidence levels:

| Level | Meaning | How to determine |
|-------|---------|------------------|
| **CONFIRMED** | Relationship verified by reading workspace files (imports, API calls, schema references found via code search) | Agent read the file and found the reference |
| **INFERRED** | Relationship assumed from naming conventions, known architecture, or user description — not verified in workspace files | Agent did not verify in actual code |

Always label each consumer row in the output with its confidence level.
Do not present an INFERRED relationship as a confirmed impact.

**If no dependency map is available (`blast_radius.dependency_map_path` not
set in `.dev-iq/config.yaml`) and the workspace cannot be searched:**
- Fall back to advisory mode regardless of maturity tier
- State: "Full consumer scan unavailable — dependency map not configured and
  workspace search could not be completed. The following assessment is INFERRED
  and must be verified by the team before acting on it."
- Do not produce a Breaking/Degraded/Transparent verdict table as if it were confirmed

For each changed surface, find all consumers:

**For API endpoints:**
- Search for callers of the endpoint URL in the codebase and known clients
- Check API gateway routing rules
- Review API documentation for listed consumers

**For database schemas:**
- Search for query statements referencing the changed column/table
- Check ORM model definitions
- Check migration files for dependencies

**For interfaces/types:**
- Search for all implementors of the interface
- Search for all callers of the changed function signature
- Check for serialization/deserialization code that depends on the type shape

**For shared utilities:**
- Search for all import/require statements of the changed module
- Identify which services or packages import it

### Step 4: Rate Impact Per Consumer

| Rating | Meaning |
|--------|---------|
| **Breaking** | The consumer will fail at compile time, startup, or runtime after this change |
| **Degraded** | The consumer continues to function but with incorrect behavior or data |
| **Transparent** | The change is backward-compatible — the consumer is unaffected |

A change that is Transparent to all consumers has zero blast radius. A change
with one or more Breaking consumers requires coordinated deployment.

### Step 5: Recommend Deployment Sequence
For changes with Breaking consumers:

1. Identify the deployment order (what must deploy first?)
2. Identify whether a feature flag or backward-compatible bridge is possible
3. Identify the rollback trigger criteria (what signal indicates the deployment
   must be reversed?)

At **Early maturity**: produce an advisory note — "consult your team before
proceeding; this analysis is simplified." Blast radius estimation is not
autonomous at Early maturity.

At **Mid maturity**: produce the full structured map. Verdict is advisory.

At **Higher maturity**: produce the full map with deployment sequencing and
rollback triggers. Verdict is authoritative.

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Change description or git diff | Paste, file path, or diff | Yes |
| List of known consumers (if not discoverable from codebase) | User provides | Recommended |
| Deployment environment topology | `.dev-iq/config.yaml` or user states | Recommended |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## Blast Radius — [Change Description]
Work Item: [AB#XXXX | PROJ-XXX | #456 | "none provided"]
Change Type: [API contract | Schema | Interface | Shared utility | Config | Internal]
Assessed: [date]
Maturity: [Early (advisory) | Mid | Higher]
Scan confidence: [CONFIRMED — workspace searched | INFERRED — advisory only]

---

### Change Surface

[Precise description of what is changing — which field, method, endpoint,
or table, and what specifically is changing about it]

---

### Consumer Impact

| Consumer | Type | Confidence | Impact | Notes |
|----------|------|------------|--------|-------|
| [service/component name] | [API / Schema / Interface] | CONFIRMED | Breaking | [what breaks — verified in workspace] |
| [service/component name] | [API] | CONFIRMED | Transparent | [why unaffected] |
| [service/component name] | [Schema] | INFERRED | Degraded | [assumed from architecture — not verified in code] |

---

### Blast Radius Summary

- **Breaking:** [N consumers]
- **Degraded:** [N consumers]
- **Transparent:** [N consumers]
- **Overall blast radius:** [Low / Medium / High / Critical]

---

### Deployment Sequence

1. [What must deploy or be updated first]
2. [What can deploy next]
3. [Validation step before proceeding]

**Feature flag option:** [Yes — describe | No — explain why]

---

### Rollback Trigger Criteria

Roll back the deployment if:
- [Observable signal 1 — e.g. "error rate on /orders exceeds 1% within 5 minutes of deploy"]
- [Observable signal 2]

---

### RISK Signal: [STRONG | WEAK | UNGRADED]

@di-review-required
```

## Examples

### Example 1: Removing a Response Field — High Blast Radius

**User says:** "We want to remove the `legacyId` field from the GET /orders
response."

**Result:**

```
## Blast Radius — Remove legacyId from GET /orders response
Work Item: AB#4102
Change Type: API contract
Assessed: 2026-06-06
Maturity: Mid

---

### Change Surface

Removing the `legacyId` string field from the response body of GET /v1/orders
and GET /v1/orders/{id}. The field currently returns a nullable string.

---

### Consumer Impact

| Consumer | Type | Impact | Notes |
|----------|------|--------|-------|
| web-client (React SPA) | API | Breaking | src/hooks/useOrder.ts reads legacyId for legacy redirect |
| mobile-ios (v2.3+) | API | Transparent | iOS 2.3+ changelog shows legacyId removed from parsing |
| mobile-ios (v2.2 and earlier) | API | Degraded | Older clients silently ignore unknown fields; legacyId absence is handled gracefully |
| reporting-service | API | Breaking | ReportingService.mapOrder() crashes on undefined legacyId |
| third-party-partner-api | API | Breaking | Partner contract specifies legacyId in order webhook payload |

---

### Blast Radius Summary

- **Breaking:** 3 consumers (web-client, reporting-service, third-party partner)
- **Degraded:** 1 consumer (iOS v2.2 and earlier)
- **Transparent:** 1 consumer (iOS v2.3+)
- **Overall blast radius:** High

---

### Deployment Sequence

1. Update web-client to stop reading `legacyId` (PR + deploy)
2. Update reporting-service mapOrder() to handle missing legacyId (PR + deploy)
3. Coordinate with partner API team — this is a contract change; notify
   with 30-day deprecation notice per SLA
4. After all consumers confirm readiness: deploy the field removal
5. Monitor error rates on /orders for 30 minutes post-deploy

**Feature flag option:** Yes — gate field removal behind a feature flag per
consumer to allow staged rollout without a big-bang coordinate.

---

### Rollback Trigger Criteria

Roll back if:
- Error rate on GET /orders exceeds 0.5% within 10 minutes of deploy
- Any consumer team reports a production incident linked to legacyId absence
- Partner API team escalates a contract violation

---

### RISK Signal: WEAK
Three Breaking consumers — coordinated rollout required. Do not deploy
field removal until all three breaking consumers are confirmed updated.

@di-review-required
```

---

### Example 2: Adding an Optional Response Field (Low Blast Radius)

**User says:** "We want to add a new `deliveryEta` field to the GET /orders response."

**Result:**

```
## Blast Radius — Add deliveryEta to GET /orders response
Work Item: AB#4201
Change Type: API contract
Assessed: 2026-06-06
Maturity: Mid

---

### Change Surface

Adding a new nullable string field `deliveryEta` (ISO 8601 timestamp) to the
GET /v1/orders and GET /v1/orders/{id} response body. Consumers that do not
read the field are unaffected.

---

### Consumer Impact

| Consumer | Type | Impact | Notes |
|----------|------|--------|-------|
| web-client | API | Transparent | Will display field once UI is updated (separate PR) |
| mobile-ios | API | Transparent | Additive field — ignored by older clients |
| reporting-service | API | Transparent | Does not map this field |
| third-party-partner | API | Transparent | Additive fields do not break their parser |

---

### Blast Radius Summary

- **Breaking:** 0 consumers
- **Degraded:** 0 consumers
- **Transparent:** 4 consumers
- **Overall blast radius:** Low

---

### Deployment Sequence

1. Deploy field addition to API — no coordination required
2. Web-client UI update can follow independently

**Feature flag option:** Not required — zero consumer impact.

---

### Rollback Trigger Criteria

Roll back if:
- API error rate increases above baseline within 10 minutes of deploy
  (unlikely for additive change, but monitor as standard practice)

---

### RISK Signal: STRONG
Additive change with zero Breaking consumers. No deployment coordination needed.

@di-review-required
```

---

### Example 3: Early Maturity — Advisory Mode

```
## Blast Radius — Rename orders.status column to orders.order_status
Work Item: none provided
Change Type: Schema
Assessed: 2026-06-06
Maturity: Early (advisory mode)

---

### Advisory Note

At Early maturity, blast radius estimation runs in simplified advisory mode.
A full consumer scan requires Mid maturity or higher.

**Simplified assessment:**

Renaming a column (`status` → `order_status`) on a live table is a breaking
change for every query, ORM model, migration file, and reporting tool that
references the column by name. Column renames in SQL cannot be done in a
single atomic step — they require a multi-phase migration:

1. Add `order_status` column
2. Copy data from `status` to `order_status` (backfill)
3. Update all consumers to use `order_status`
4. Remove `status` column

**Before proceeding:** Identify all locations in the codebase that reference
`orders.status` by running a codebase search for the string. Review each hit.
The count of hits is your blast radius.

**Recommended next step:** Upgrade to Mid maturity to enable a full automated
blast radius scan, or perform the consumer search manually and share the
results.

@di-review-required
```

---

## Common Rationalizations

These are the statements that get blast radius assessment skipped. Rebut them.

| Rationalization | Reality |
|----------------|---------|
| "It's a small change, it can't affect much" | Blast radius is determined by what you touch, not how much you change. A one-line signature change on a shared interface has a larger radius than a 500-line internal refactor. |
| "We'll deal with breakage if it happens" | Unplanned breakage is an incident. A blast radius estimate is the difference between a managed migration and a production fire at 2am. |
| "Only the team using this API matters" | Every consumer you don't know about is a consumer you can't notify. Unknown consumers become support escalations after the deploy. |
| "We've done similar changes before without issues" | Prior success doesn't map blast radius. Codebase growth and new consumers change the impact profile of every subsequent change. |

## Governance
- At Early maturity, blast radius estimation is advisory only — the tool will
  not produce an authoritative blast radius map; it will guide the developer
  to conduct the analysis themselves
- A Breaking consumer that is not updated before the change deploys is a
  production incident waiting to happen — never mark a change as low risk
  when Breaking consumers have not confirmed readiness
- Rollback trigger criteria are required for every change rated Medium blast
  radius or higher — "monitor for errors" is not a trigger criterion; a
  specific metric and threshold are required
- All output carries `@di-review-required` — the blast radius map is a draft;
  the team must verify the consumer list is complete before relying on it
- RISK signal STRONG may only be assigned when zero Breaking consumers are
  identified and the consumer scan is confirmed complete — UNGRADED if the
  scan could not be completed
- Feature flag strategies must be evaluated for every High blast radius change —
  coordinated big-bang releases are a risk multiplier
- **Do not present an INFERRED consumer relationship as a confirmed impact.**
  Every consumer in the output table must be labeled CONFIRMED or INFERRED.
  INFERRED relationships must carry a note: "not verified in workspace files —
  team must confirm before treating this as a blocking finding."
- **Fall back to advisory mode** when a dependency map is not configured and
  the workspace cannot be searched. Do not produce a structured Breaking/Degraded
  verdict table based on inference alone — the team will act on it as if it
  were confirmed.

## Related Skills
- `/review-dependencies` — if the blast radius change involves package updates,
  combine with a dependency review
- `/generate-rollback-plan` — always generate a rollback plan alongside a High
  blast radius change
- `/review-deployment-readiness` — blast radius assessment is a key input to
  the deployment readiness verdict
- `/review-architecture` — if the blast radius reveals unexpected coupling between
  components, escalate to an architecture review
