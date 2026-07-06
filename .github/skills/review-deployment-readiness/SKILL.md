---
name: review-deployment-readiness
description: Assess whether a release is ready to deploy — a go/no-go verdict using all four DI signal layers. Use when asked to "is this ready to deploy", "deployment readiness check", "go/no-go for release", or "can we ship this".
di_signal: QUALITY + RISK
maturity_required: early
status: approved
---

# Review Deployment Readiness

## Overview
Assesses whether a release is ready to deploy by running all four DI signal
layers against the release artifacts, then issues a structured verdict: Go,
Go with conditions, or No-Go.

This skill is not a rubber stamp — it is a structured gate. The verdict is
advisory at Early maturity (the team makes the final call) and authoritative
at Higher maturity. No delivery pressure changes the criteria. A No-Go
with documented conditions is more valuable than a false Go that causes a
production incident.

## When to Use
- Before deploying a release to a production environment
- Before promoting a build from staging to production after QA
- When a release manager needs a structured go/no-go checklist
- Before deploying a hotfix that bypassed normal review gates
- When a scheduled deployment window is approaching and readiness is unclear
- Any time the user says: "is this ready to deploy", "go/no-go for the release",
  "deployment readiness check", "can we ship this", "pre-deploy checklist"

## Instructions

### Step 1: Gather Release Artifacts
Ask for (if not provided):
- The PR list or merge log for this release
- Test results (unit, integration, E2E) — pass/fail summary
- SAST results (if configured)
- Migration list (what database changes are included)
- The deployment environment (staging, production, canary?)

Read:
- `.dev-iq/config.yaml` → maturity tier, deployment topology
- `.dev-iq/governance.md` → compliance posture and release gates

### Step 2: Run the Four-Layer Assessment

**INTENT layer**
- Are all work items in this release tracked? (INTENT UNGRADED flags from release notes)
- Do the shipped changes match the sprint/release plan?
- Are any breaking changes present that were not communicated to consumers?

**DESIGN layer**
- Are there any unresolved architecture or design Hold conditions?
- Did any PR in this release skip a design review for a significant structural change?

**QUALITY layer**
- Test results: pass? Coverage change: within acceptable threshold?
- SAST: any unresolved Critical or High findings?
- Were all new public functions covered by test stubs?
- Any known regression or flaky test that was suppressed for this release?

**RISK layer**
- Schema migrations: is a rollback migration present for each?
- Breaking API changes: are all consumers confirmed updated?
- Dependency changes: were new/updated dependencies reviewed?
- Blast radius: was a blast radius assessment done for high-impact changes?

### Step 3: Check the Deployment Checklist
Verify the operational readiness items:

| Item | Status | Notes |
|------|--------|-------|
| Rollback plan documented | ✓ Verified / ⚠ Unverified / ✗ Missing / N/A | [link or filename, or "claimed, no artifact"] |
| Feature flags configured for gradual rollout | ✓ Verified / ⚠ Unverified / ✗ Missing / N/A | |
| Runbook for new service or significant change | ✓ Verified / ⚠ Unverified / ✗ Missing / N/A | |
| Monitoring/alerting covers new behavior | ✓ Verified / ⚠ Unverified / ✗ Missing / N/A | |
| On-call engineer notified and available | ✓ Verified / ⚠ Unverified / ✗ Missing / N/A | |
| Communication plan for breaking changes | ✓ Verified / ⚠ Unverified / ✗ Missing / N/A | |

**UNVERIFIED vs. UNGRADED:**
- **UNVERIFIED** — the team claims the item is complete but cannot provide an artifact (link, filename, CI run ID). Produces "Go with conditions" — confirm within a defined post-deploy window.
- **UNGRADED** — no claim made and no data available. Produces No-Go when the item is required.

**Artifact requirement for Go verdict:**
A straight Go requires at least one confirmed artifact for the QUALITY layer — a CI run URL, test report filename, or coverage report. "The tests pass" is a claim, not evidence. UNVERIFIED QUALITY = Go with conditions; UNGRADED QUALITY = No-Go.

### Step 4: Issue Verdict

**Go:** All four layers STRONG, no No-Go conditions, all checklist items satisfied.

**Go with conditions:** No No-Go conditions, but one or more Medium findings
or missing checklist items that should be addressed within a defined window
post-deploy.

**No-Go:** One or more of the following are present:
- Critical or High security finding unresolved (always blocks, no override)
- No rollback plan for a schema change that modifies existing data
- QUALITY layer UNGRADED (no test evidence — cannot confirm the change works)
- Breaking API or contract change with consumers not confirmed updated
- Missing runbook for a new service in production
- Known regression suppressed without documented acceptance

At **Early maturity**: verdict is advisory. Every No-Go condition includes a
coaching note. The team makes the final decision.

At **Mid maturity**: structured report. High findings block; verdict is
suggest-only for the team.

At **Higher maturity**: autonomous verdict. No-Go is authoritative.

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Release PR list or merge log | Git, CI artifacts, or user provides | Yes |
| Test results summary | CI artifact or user provides | Required for QUALITY layer |
| SAST results | CI artifact or user provides | Required for QUALITY — UNGRADED if absent |
| Migration list | User provides or inferred from PR list | Required if any schema changes |
| Deployment environment | User states | Required |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## Deployment Readiness — v[version] → [environment]
Work Item: [release tracking ID or "none"]
Assessed: [date]
Maturity: [Early (advisory) | Mid | Higher]

---

### Four-Layer DI Assessment

| Layer | Signal | Key Finding |
|-------|--------|-------------|
| INTENT | [STRONG/WEAK/UNGRADED] | [finding or "all changes tracked"] |
| DESIGN | [STRONG/WEAK/UNGRADED] | [finding or "no outstanding design holds"] |
| QUALITY | [STRONG/WEAK/UNGRADED] | [finding or "tests passing, no SAST findings"] |
| RISK | [STRONG/WEAK/UNGRADED] | [finding or "rollback plans in place, consumers confirmed"] |

---

### No-Go Conditions

[List each No-Go condition found, or "None identified."]

**🔴 [Condition 1]** — [description and what must change before Go]

---

### Deployment Checklist

| Item | Status | Notes |
|------|--------|-------|
| Rollback plan documented | [✓ / ✗ / N/A] | |
| Feature flag configured | [✓ / ✗ / N/A] | |
| Runbook available | [✓ / ✗ / N/A] | |
| Monitoring covers new behavior | [✓ / ✗ / N/A] | |
| On-call available | [✓ / ✗ / N/A] | |
| Breaking change communication sent | [✓ / ✗ / N/A] | |

---

### Verdict: [Go | Go with conditions | No-Go]

**Rationale:** [1–3 sentences explaining the verdict]

**Conditions (if Go with conditions):**
1. [What must be confirmed or addressed within [timeframe] post-deploy]

**Blocking issues (if No-Go):**
1. [Issue 1 — what must be resolved and who owns it]
2. [Issue 2]

---

@di-review-required
```

## Examples

### Example 1: Clean Release — Go

**User says:** `/review-deployment-readiness` for v1.5.0 → production

**Result:**

```
## Deployment Readiness — v1.5.0 → production
Work Item: AB#2800 (release tracking)
Assessed: 2026-06-06
Maturity: Mid

---

### Four-Layer DI Assessment

| Layer | Signal | Key Finding |
|-------|--------|-------------|
| INTENT | STRONG | All 5 work items tracked; no untracked commits in release log |
| DESIGN | STRONG | No outstanding architecture holds; all PRs reviewed |
| QUALITY | STRONG | 247 tests passing, 0 failing; SAST: 0 critical, 0 high |
| RISK | STRONG | No schema changes; no breaking API changes; rollback plan documented |

---

### No-Go Conditions
None identified.

---

### Deployment Checklist

| Item | Status | Notes |
|------|--------|-------|
| Rollback plan documented | ✓ | `WISHLIST_SHARING_ENABLED` flag disable is the rollback |
| Feature flag configured | ✓ | v1.5.0 ships with flag off in production |
| Runbook available | ✓ | Wishlist sharing runbook added to docs/runbooks/ |
| Monitoring covers new behavior | ✓ | Datadog dashboard updated for share token generation |
| On-call available | ✓ | On-call rotation confirmed for deploy window |
| Breaking change communication | N/A | No breaking changes in this release |

---

### Verdict: Go

**Rationale:** All four DI layers are STRONG, no No-Go conditions, and all
deployment checklist items are satisfied. The release is ready for production.

---

@di-review-required
```

---

### Example 2: Release with Unresolved High Security Finding — No-Go

**User provides:** Release artifacts for v2.1.0 including a SAST report with
one unresolved High finding (IDOR on GET /invoices/{id}).

**Result (excerpt):**

```
### Four-Layer DI Assessment

| Layer | Signal | Key Finding |
|-------|--------|-------------|
| INTENT | STRONG | All changes tracked |
| DESIGN | STRONG | No holds |
| QUALITY | WEAK | SAST: 0 critical, 1 high (unresolved) — GET /invoices/{id} IDOR |
| RISK | WEAK | High security finding unresolved |

---

### No-Go Conditions

**🔴 Unresolved High security finding: IDOR on GET /invoices/{id}**
The SAST report identifies a missing ownership check on the invoice retrieval
endpoint — any authenticated user can retrieve any invoice by ID. This is an
Insecure Direct Object Reference (IDOR) vulnerability. Per governance rules,
High security findings block the deployment verdict at all maturity tiers.

Resolution required: Add an ownership check verifying the authenticated user
owns the invoice before returning it. Re-run SAST to confirm the finding is
resolved.

---

### Verdict: No-Go

**Rationale:** A High security finding (IDOR) is unresolved. Security findings
rated High or Critical always block the deployment verdict regardless of
delivery pressure, timeline, or maturity tier.

**Blocking issues:**
1. Resolve IDOR on GET /invoices/{id} — add ownership check; owner: Backend team
2. Re-run SAST to confirm resolution
3. Re-run deployment readiness assessment after fix is merged

---

@di-review-required
```

---

### Example 3: Go with Conditions — Incomplete Monitoring

**Result (verdict excerpt):**

```
### Verdict: Go with conditions

**Rationale:** No No-Go conditions identified. One Medium finding: the new
payment webhook handler is not yet covered by the existing Datadog dashboard.
This does not block deployment but creates an observability gap.

**Conditions:**
1. Add a Datadog monitor for `payment.webhook.failed` events within 24 hours
   of deploy. Owner: Platform team. The deploy may proceed without this but
   the on-call engineer should monitor webhook error logs manually until the
   monitor is in place.

---

@di-review-required
```

---

## Common Rationalizations

These are the statements that get deployment readiness review skipped. Rebut them.

| Rationalization | Reality |
|----------------|---------|
| "It passed CI, so it's ready to deploy" | CI validates that code runs — not that environment variables are configured, migrations are ready to execute, or feature flags are set correctly for the target environment. |
| "We've deployed this service many times, we know the checklist" | Informal checklists drift. Steps added for past incidents get dropped. A structured readiness review catches gaps that familiarity masks — especially for environment-specific configuration. |
| "We can hotfix anything that goes wrong" | A hotfix takes 20-40 minutes minimum — longer if a migration is involved. A deployment readiness review takes 5 minutes. The math favors the review. |
| "It's a small change, the deployment is trivial" | Small changes can have non-trivial deployment requirements: a single added environment variable that isn't set in production will take the service down at startup. |

## Governance
- Critical and High security findings always produce No-Go — no delivery timeline,
  sprint pressure, or maturity tier override this rule; report it and let the
  team decide whether to take the risk explicitly
- QUALITY UNGRADED (no test evidence) always produces No-Go or Go with conditions
  requiring test verification — never Go; absence of test data is not the same
  as passing tests
- The rollback plan must exist before Go for any release containing a schema
  migration that modifies existing data — a No-Rollback migration requires explicit
  team acknowledgment in writing before Go may be issued
- At Early maturity, verdict is advisory — include coaching notes on every No-Go
  condition and explicitly state that the team makes the final deployment decision
- All output carries `@di-review-required` — the readiness assessment is a
  decision-support tool, not a deployment authorization
- Breaking changes with consumers not confirmed updated always produce No-Go —
  coordinate consumer updates before proceeding

## Related Skills
- `/generate-rollback-plan` — generate the rollback plan that this skill verifies
  is in place before issuing a Go verdict
- `/review-dependencies` — unresolved dependency security findings from this skill
  feed into the RISK layer assessment here
- `/blast-radius-estimator` — high blast radius changes require the consumer impact
  table as evidence for the RISK STRONG assessment
- `/generate-release-notes` — generate release notes after a Go verdict is issued
  to communicate what shipped and any known conditions
