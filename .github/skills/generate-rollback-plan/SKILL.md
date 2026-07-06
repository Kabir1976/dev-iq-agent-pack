---
name: generate-rollback-plan
description: Generate a rollback plan for a deployment — what to do if the deployment must be reversed. Use when asked to "create a rollback plan", "what's the rollback strategy", "how do we revert this", or "document the rollback steps".
di_signal: RISK
maturity_required: early
status: approved
---

# Generate Rollback Plan

## Overview
Generates a rollback plan for a deployment — identifying rollback-sensitive
components, defining trigger criteria (what observable signal initiates rollback),
producing a step-by-step reversal procedure, and explicitly documenting what
cannot be rolled back.

A rollback plan written before deployment is worth ten times one improvised
during an incident. When systems are failing, cognitive load is high and time
is short — the rollback procedure must be a checklist, not a design exercise.

## When to Use
- Before any deployment that includes a database schema migration
- Before deploying a breaking API or contract change
- Before enabling a new external integration in production
- As part of a deployment readiness review for any High RISK signal release
- When the team is uncertain about a deployment's reversibility
- Any time the user says: "create a rollback plan", "what's the rollback strategy",
  "how do we revert this", "document the rollback steps", "what happens if we
  have to roll back"

## Instructions

### Step 1: Read the Change Set
**From a PR list or diff:**
- Identify all components being deployed
- Flag rollback-sensitive components (schema changes, config changes, data migrations)

**From a description:**
- Accept the deployment description
- Ask for specifics if the rollback-sensitive components are not clear

Ask for (if not provided):
- The previous stable version or state being rolled back to
- The deployment environment (staging, canary, production, region)
- Monitoring signals available (error rate, latency, specific metrics)

### Step 2: Identify Rollback-Sensitive Components
Not all deployments are equally reversible. Assess each component:

**Application code:** Almost always reversible — revert to the previous build
and redeploy. If the new code has already written data in a new format, assess
compatibility.

**Database schema migrations:**
- Additive only (new table, new nullable column): reversible with a down migration
- Data-destructive (column drop, data type change, data migration): may be
  partially or fully irreversible — flag explicitly
- Additive with data backfill: reversible for schema; data written to the
  new column may need to be handled manually

**Configuration / environment variables:**
- Adding a new config key: reversible (remove the key)
- Changing an existing key: reversible (restore previous value)
- Config that triggers external system setup (webhook registration, OAuth
  app creation): may create external state that persists after rollback

**External integrations:**
- New webhook registrations, OAuth app authorizations, Stripe products: the
  external state persists after rollback and must be manually cleaned up
- Payment transactions processed: irreversible — document explicitly
- Emails or notifications sent: irreversible

**Feature flags:**
- If the deployment is gated behind a feature flag: rollback = disable the flag.
  This is the fastest and safest rollback path available.

### Step 3: Define Rollback Trigger Criteria
A rollback trigger is a specific, observable signal — not a vague "if things
go wrong." Document the threshold that initiates rollback:

Good trigger criteria:
- "Error rate on POST /orders exceeds 2% for 5 consecutive minutes post-deploy"
- "P99 latency on GET /users exceeds 500ms for 3 consecutive minutes"
- "Payment webhook failure rate exceeds 0.5% in the 15 minutes after feature flag enable"

Not acceptable:
- "If something breaks" (not observable)
- "If the team decides" (no threshold — will not be acted on consistently)

### Step 4: Write the Step-by-Step Rollback Procedure

**Platform confirmation guardrail — read before writing commands:**
Before prescribing specific rollback commands, confirm the deployment platform
from the workspace:
- Check `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `Dockerfile`,
  `helm/`, `terraform/`, or equivalent CI/CD configuration files
- Check `.dev-iq/config.yaml` or `telemetry-overlay.md` for declared infrastructure

If the deployment platform **cannot be confirmed** from workspace files or
explicit user input:
- Write rollback steps in **infrastructure-agnostic terms** (e.g. "revert the
  application to the previous build using your CI/CD pipeline")
- Do NOT prescribe specific commands (e.g. `helm rollback`, `kubectl rollout undo`,
  `eb deploy`, `flyway undo`) without platform confirmation
- Add a warning block to every step:
  ```
  ⚠️ Platform not confirmed. This command is illustrative.
  Verify it matches your actual infrastructure before executing during an incident.
  ```

For each rollback-sensitive component, write numbered steps:
- Specific commands or actions (not general descriptions)
- Who executes each step (role, not name — "on-call engineer", "DBA", "release manager")
- Expected time per step
- Verification step after each action to confirm it succeeded

### Step 5: Document Irreversible Actions
List explicitly what cannot be undone even after rollback:
- Payment transactions
- Sent emails or notifications
- Webhook deliveries to external systems
- Data deleted without a backup
- Messages published to a queue that has already been consumed

**Database migration reversibility guardrail:**
Do NOT mark a database migration as reversible unless one of the following is
confirmed from workspace files:
- A `down` migration file exists (e.g. `migrate:rollback`, `flyway undo`
  target, Liquibase rollback tag)
- The migration is additive-only (new nullable column or new table with no
  data transformation)

If neither can be confirmed, mark the migration as **IRREVERSIBLE — UNVERIFIED**
and state: "No down migration was found in the workspace. Treat as irreversible
until a DBA confirms a reversal path exists."

Irreversible actions require a communication plan — who gets notified if
rollback is initiated and these actions are in a partial state?

At **Early maturity**: include coaching notes explaining why trigger criteria
must be pre-defined and what "irreversible" really means in production.

At **Mid/Higher maturity**: structured procedure only.

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Deployment change set (PR list, migrations, config changes) | User provides | Yes |
| Previous stable version or state | User provides | Required |
| Available monitoring signals | User states or inferred | Required for trigger criteria |
| Deployment environment | User states | Required |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## Rollback Plan — v[version] → [environment]
Work Item: [AB#XXXX | PROJ-XXX | #456 | "none provided"]
Rollback target: v[previous version] or [previous state]
Prepared: [date]

---

### Rollback Trigger Criteria

Initiate rollback if ANY of the following are observed within [N] minutes of deploy:

- [ ] [Metric 1 threshold — e.g. "Error rate on POST /orders > 2% for 5 min"]
- [ ] [Metric 2 threshold]
- [ ] [On-call escalation — e.g. "Any P1 incident filed within 30 minutes of deploy"]

**Who initiates:** [on-call engineer | release manager]
**How to initiate:** [Slack #incidents | PagerDuty | runbook link]

---

### Rollback Procedure

**Step 1: Disable feature flag (if applicable)**
- Action: Set `[FEATURE_FLAG_NAME]` to `false` in [config system]
- Who: On-call engineer
- Expected time: < 2 minutes
- Verify: [how to confirm the flag is disabled — e.g. "Check /health endpoint returns flag status false"]

**Step 2: Revert application deployment**
- Action: [specific command or CI/CD action — e.g. `helm rollback app-name 1` or "Deploy previous tag from CI"]
- Who: On-call engineer
- Expected time: 3–5 minutes
- Verify: GET /health returns version [previous version]

**Step 3: Reverse database migration (if applicable)**
- Action: [specific command — e.g. `npx knex migrate:rollback` or `flyway undo`]
- Who: DBA or on-call engineer with DB access
- Expected time: [N minutes — state based on table size]
- Verify: [specific SQL check — e.g. `SELECT column_name FROM information_schema.columns WHERE table_name='orders'` confirms column removed]

**Step 4: Restore configuration (if applicable)**
- Action: [specific steps to restore previous config values]
- Who: On-call engineer
- Expected time: < 5 minutes
- Verify: [how to confirm config is restored]

**Step 5: Notify stakeholders**
- Action: Post rollback status to [#incidents, #releases, or equivalent channel]
  Message template: "Rollback of v[version] initiated at [time]. Reason: [trigger].
  System is on v[previous version]. Impact: [describe]."
- Who: Release manager or on-call lead
- Expected time: < 5 minutes

---

### Irreversible Actions

The following cannot be undone after rollback is initiated:

- [Action 1 — e.g. "Payment transactions processed during the deploy window"]
- [Action 2 — e.g. "Order confirmation emails sent to customers"]

**Communication plan for partial state:**
If rollback is initiated and irreversible actions are in a partial state:
- [Who is notified — e.g. "Finance team for any payment anomalies"]
- [What manual remediation is required, if any]

---

### RISK Signal: [STRONG | WEAK | UNGRADED]
STRONG = rollback plan covers all sensitive components with specific triggers and steps.
WEAK = one or more components have irreversible actions or unclear rollback steps that were not resolvable.
UNGRADED = trigger criteria cannot be defined (monitoring signals unknown), or the change set is too vague to identify rollback-sensitive components — a plan cannot be written without this data.

@di-review-required
```

## Examples

### Example 1: Feature Flag Rollback — Simple

**User says:** "Generate a rollback plan for deploying the wishlist sharing
feature. It's gated behind a feature flag."

**Result:**

```
## Rollback Plan — v1.5.0 → production
Work Item: AB#2202
Rollback target: v1.4.2 (or flag-off state)
Prepared: 2026-06-06

---

### Rollback Trigger Criteria

Initiate rollback if ANY of the following within 30 minutes of flag enable:

- [ ] Error rate on GET /wishlists/shared/:token > 1% for 5 consecutive minutes
- [ ] Any P1 incident filed referencing the wishlist sharing feature
- [ ] Share token generation failure rate > 0.5% (monitor: Datadog — wishlist.share.error)

**Who initiates:** On-call engineer
**How to initiate:** Post in #incidents, then execute Step 1 immediately

---

### Rollback Procedure

**Step 1: Disable feature flag**
- Action: Set `WISHLIST_SHARING_ENABLED` to `false` in LaunchDarkly
- Who: On-call engineer
- Expected time: < 2 minutes
- Verify: Confirm "Share wishlist" button is no longer visible in the UI
  (incognito session) and GET /wishlists/shared/:token returns 404 for
  new requests

**Step 2: Monitor for 10 minutes post-flag-disable**
- If error rate returns to baseline: rollback complete, no further steps needed
- If error rate does not recover: escalate to Step 3

**Step 3: Revert application deployment (escalation only)**
- Action: Trigger "Deploy v1.4.2" in the CI/CD release pipeline
- Who: On-call engineer
- Expected time: 5–7 minutes
- Verify: GET /health returns `"version": "1.4.2"`

---

### Irreversible Actions

None. The wishlist sharing feature is read-only — no payments, emails, or
external registrations were triggered by the rollback-sensitive code path.

---

### RISK Signal: STRONG
Complete rollback is achievable via flag disable alone. Application code
rollback is available as a fallback. No irreversible actions.

@di-review-required
```

---

### Example 2: Schema Migration Rollback with Risks Noted

**User says:** "Generate a rollback plan for the orders.charge_id migration."

**Result:**

```
## Rollback Plan — orders.charge_id migration
Work Item: AB#3301
Rollback target: pre-migration schema state
Prepared: 2026-06-06

---

### Rollback Trigger Criteria

Initiate rollback if within 15 minutes of migration run:

- [ ] Application error rate > 2% (any endpoint)
- [ ] Any database timeout error on orders queries
- [ ] Payment integration test in staging fails after migration

---

### Rollback Procedure

**Step 1: Revert application deployment**
- Action: Deploy previous application tag (v2.0.1) from CI pipeline
- Who: On-call engineer
- Expected time: 5–7 minutes
- Verify: GET /health returns v2.0.1

**Step 2: Run down migration**
- Action: `npx knex migrate:rollback --to 20260606_add_charge_id`
- Who: DBA or on-call engineer with DB access
- Expected time: < 1 minute (the column is nullable with no data constraint)
- Verify: `SELECT charge_id FROM orders LIMIT 1;` — should return "column does
  not exist" error confirming removal

**Step 3: Notify stakeholders**
- Who: Release manager
- Message: "Migration for orders.charge_id rolled back at [time]. Reason: [trigger].
  Stripe integration is not active. Finance team: no charges were processed
  against this column during the migration window."

---

### Irreversible Actions

None during this migration specifically. The `charge_id` column is additive
and nullable — no existing data was modified. Any charges processed during
the window will have been created in Stripe but the `charge_id` value was
not written to any order record (the column didn't exist yet during the
window). Finance team should reconcile Stripe records manually for the
deployment window.

---

### RISK Signal: WEAK
Down migration is present and reversible. However: any Stripe charges processed
during the migration window cannot be automatically linked to orders after
rollback. Manual Stripe reconciliation is required for the window.

@di-review-required
```

---

### Example 3: Payment Integration — Irreversible Transactions Flagged

**Irreversible Actions excerpt:**

```
### Irreversible Actions

- **Payment transactions processed during the deploy window:**
  Any Stripe charges created between deploy start and rollback complete
  are irreversible. Customers have been charged. Rollback does not refund them.
  
  Communication plan: Finance team must be notified immediately on rollback
  initiation. They will cross-reference Stripe dashboard with the order system
  to identify any charges with no corresponding order record.

- **Order confirmation emails sent:**
  Any confirmation emails dispatched before rollback are irreversible.
  If an order fails to persist due to rollback but an email was already sent,
  customer support must be notified to handle inbound queries.

**DI Note:** Payment rollbacks are not code rollbacks — they are financial
reconciliation exercises. The technical rollback may take 10 minutes; the
financial remediation may take days. Plan accordingly.
```

---

## Common Rationalizations

These are the statements that get rollback planning skipped. Rebut them.

| Rationalization | Reality |
|----------------|---------|
| "We can always just redeploy the old version" | "Just redeploy" assumes no schema changes, no data state changes, no shared dependencies that have already moved. An untested rollback is a second incident waiting to happen alongside the first. |
| "Our deployments are simple, rollback is obvious" | Rollback feels obvious until you're doing it under pressure at 2am with an incident bridge open and a database migration half-applied. Obvious plans written in advance beat improvised plans written under duress. |
| "We've never needed to rollback before" | Prior success doesn't guarantee future simplicity. Every release that adds schema changes or external dependencies increases the rollback complexity. |
| "The rollback plan is in someone's head" | Knowledge in someone's head is unavailable when that person is on vacation, off-call, or asleep when the incident fires. Plans must be written and accessible to whoever is on duty. |

## Governance
- Rollback trigger criteria must be specific and observable before a deployment
  is approved for production — "monitor for problems" is not a trigger criterion
- Irreversible actions must be documented explicitly; omitting them is a RISK
  WEAK finding that must be resolved before the plan is used
- Rollback plans are prepared before deployment, not during the incident —
  a rollback plan prepared during an incident will be wrong
- All output carries `@di-review-required` — the rollback plan must be reviewed
  by the on-call engineer and release manager before the deployment window opens
- Schema migrations that are irreversible (data-destructive) must be flagged
  as RISK WEAK even if a down migration exists — the down migration reverses
  the schema but not the data loss
- Never issue a RISK STRONG verdict when irreversible actions are present and
  the communication plan is not documented
- **Do not prescribe platform-specific rollback commands** (e.g. `helm rollback`,
  `kubectl rollout undo`, `flyway undo`, `eb deploy`) unless the deployment
  platform is confirmed from workspace CI/CD configuration files or explicit
  user input. Invented platform-specific commands executed during an incident
  can cause more damage than the incident itself. Use infrastructure-agnostic
  descriptions and mark all illustrative commands with a ⚠️ warning.
- **Do not mark a migration reversible** without confirming a down migration
  exists in the workspace. Assumption of reversibility is a production risk.
- **RISK UNGRADED** when monitoring signals are unknown — trigger criteria cannot be specific without them; a rollback plan with vague triggers is not a rollback plan

## Related Skills
- `/review-deployment-readiness` — the rollback plan generated here is a required
  input to the deployment readiness checklist
- `/blast-radius-estimator` — the blast radius of the change informs how many
  consumers need to be considered in the rollback communication plan
- `/generate-release-notes` — include a rollback summary in the release notes
  for any release where rollback was initiated
- `/identify-dependencies` — dependencies identified before development may
  surface rollback-sensitive components early, before the rollback plan is needed
