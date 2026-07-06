---
name: debug-issue
description: Diagnose the root cause of a bug, error, or unexpected behavior. Use when asked to "debug this", "what's causing this error", "help me investigate this bug", or "why is this failing".
di_signal: QUALITY + RISK
maturity_required: early
status: approved
---

# Debug Issue

## Overview
Helps diagnose the root cause of a bug, error, or unexpected behavior by
applying the DI QUALITY and RISK signal layers: where does the failure
originate, what hypotheses explain it, and what does fixing it risk breaking?

The discipline here is the root cause / symptom distinction. The fix must
address the root cause — not silence the error, suppress the log, or wrap
the failure in a catch block that hides it. A symptom-level fix will recur.
A root-cause fix prevents the class of failure.

## When to Use
- When a developer has an error message, stack trace, or unexpected behavior
  they cannot explain
- When a test is failing and the failure mode is unclear
- When a reported user bug needs to be traced to a code location
- When a production incident needs a rapid root cause hypothesis to guide
  investigation
- When a bug was fixed once and has recurred, suggesting the first fix was
  a symptom-level patch
- Any time the user says: "debug this", "what's causing this error", "help me
  investigate", "why is this failing", "trace this bug", "I'm seeing this crash"

## Instructions

### Step 1: Gather the Failure Evidence
Ask for (if not already provided):
- The full error message or exception text
- The stack trace (if available)
- Reproduction steps: what action triggers the failure?
- The environment where it fails: local, CI, staging, production?
- Whether it is consistent or intermittent

If evidence is partial: note what is missing and proceed with what is available,
flagging where gaps reduce confidence in the hypotheses.

Load context:
- `.dev-iq/config.yaml` → stack, language, framework
- The relevant code files if the stack trace points to a specific location

### Step 2: Identify the QUALITY Layer Signal
Locate where in the code the failure originates:

**Read the stack trace bottom-up** (not top-down):
- The bottom of the stack is where control entered the code
- The top is where the error was thrown
- The root cause is usually not where the error was thrown — it is a layer or
  two below, where a precondition was violated

**Common QUALITY failure patterns:**
- Null/undefined access on a value that should have been guarded
- Unhandled error from an external call (database, HTTP, queue) that propagated
  silently until it hit an unguarded path
- State mutation in a shared object that is not expected by the caller
- Race condition between two async operations accessing shared state
- A type mismatch between what was promised (the interface) and what was delivered
- A missing environment variable or configuration key that is read as undefined

**Distinguish:**
- **Root cause** — the condition that made the failure possible
- **Symptom** — where the failure manifested (often a different location than the cause)

### Step 3: Form and Rank Hypotheses
Generate hypotheses in order of likelihood, based on the evidence:

1. Most likely cause (highest prior probability given the evidence)
2. Second most likely cause
3. Less likely alternatives (include if the top hypotheses cannot be confirmed
   without additional data)

For each hypothesis: state what evidence would confirm or refute it.

Do not commit to a single hypothesis without evidence — present ranked options
and the investigation steps to distinguish them.

### Step 4: Propose Investigation Steps
For the top hypothesis, produce ordered investigation steps:

- What to look at first (specific log lines, specific code lines, specific
  environment variables)
- What command or check would confirm or refute the hypothesis
- What to check second if the first step is inconclusive

Keep investigation steps specific. "Check the logs" is not an investigation step.
"Search the logs for `payment.failed` events between 14:00 and 14:15 UTC on
the date of the incident" is an investigation step.

### Step 5: When Root Cause Is Identified
Once the root cause is confirmed:

1. State the root cause clearly: what condition, what code location, what
   missing guard or handler
2. Recommend the fix: what change addresses the root cause (not just the symptom)
3. Assess the RISK of the fix: what does changing this code affect? Is this
   code called from other places? Does the fix change behavior for non-failing
   cases?
4. Recommend a test stub: what test case would catch this class of failure
   if it recurs? (Assert.IQ generates the full test.)

At **Early maturity**: include a coaching note on the root cause / symptom
distinction and why the specific fix addresses root cause.

At **Mid/Higher maturity**: structured output only.

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Error message or stack trace | User provides | Yes |
| Reproduction steps | User provides | Recommended |
| Environment where failure occurs | User states | Required |
| Code files identified in stack trace | File paths or paste | Strongly recommended |
| Consistency (consistent vs. intermittent) | User states | Recommended |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## Debug — [Error or Issue Title]
Work Item: [AB#XXXX | PROJ-XXX | #456 | "none provided"]
Environment: [local | CI | staging | production]
Assessed: [date]

---

### Failure Summary

**Error:** [error message or exception type]
**Where it manifests:** [file/function/endpoint where the error appears]
**When it occurs:** [trigger — always / intermittent / specific input]
**Evidence quality:** [Complete | Partial — [what is missing]]

---

### QUALITY Signal
[Which layer of the QUALITY signal does this failure originate from?
Error handling gap? Null safety? Race condition? External call without guard?]

---

### Root Cause vs. Symptom

**Symptom:** [where the error manifests — the visible failure]
**Probable root cause:** [the underlying condition that made the failure possible]

---

### Hypotheses (ranked by likelihood)

**Hypothesis 1 (most likely):** [description]
- Evidence supporting: [what in the trace/code supports this]
- Evidence that would confirm: [specific check or log line]
- Evidence that would refute: [what would rule this out]

**Hypothesis 2:** [description]
- Evidence supporting: [what suggests this]
- Evidence that would confirm: [specific check]

---

### Investigation Steps

1. [Specific step 1 — what to check, where, how]
2. [Specific step 2 — what to do if step 1 is inconclusive]
3. [Specific step 3 — escalation check if first two are inconclusive]

---

### Root Cause (when confirmed)

**Root cause:** [clear statement of the confirmed cause]
**Code location:** [file/function/line]

**Recommended fix:** [what change addresses the root cause]

```[language]
[code snippet showing the fix, if the root cause is clear]
```

**RISK assessment of the fix:**
- Blast radius: [what else calls this code?]
- Behavior change: [does fixing this change behavior for non-failing inputs?]
- Recommended test stub:
  ```
  // TEST STUB — [work item ID or "debug fix"]
  // Scenario: [what this test would verify to prevent recurrence]
  ```

---

### QUALITY Signal: [STRONG | WEAK | UNGRADED]
[STRONG = root cause identified and fix is clear; WEAK = symptom is clear
but root cause unconfirmed; UNGRADED = insufficient evidence to form hypotheses]

@di-review-required
```

## Examples

### Example 1: NullPointerException Traced to Missing Guard

**User provides:** Stack trace showing `TypeError: Cannot read property 'id' of
undefined` at `OrderService.ts:47 — order.customer.id`

**Result:**

```
## Debug — TypeError: Cannot read property 'id' of undefined
Work Item: none provided
Environment: production
Assessed: 2026-06-06

---

### Failure Summary

**Error:** TypeError: Cannot read property 'id' of undefined
**Where it manifests:** OrderService.ts line 47 — `order.customer.id`
**When it occurs:** Intermittent — approximately 2% of order fetch requests
**Evidence quality:** Partial — stack trace available, no logs from the database call

---

### QUALITY Signal
Null safety failure — the code accesses `order.customer` without verifying
it exists. The QUALITY finding is an unguarded property access on a value
that can be null.

---

### Root Cause vs. Symptom

**Symptom:** TypeError thrown at line 47 when accessing `customer.id`
**Probable root cause:** Orders are being created without an associated
customer record in some code path — when `getOrder()` fetches such an order,
`order.customer` is null and the access throws.

---

### Hypotheses

**Hypothesis 1 (most likely):** Guest checkout or admin-created orders
have no customer association. The `customer` field is nullable in the
database but `OrderService.getOrder()` assumes it is always populated.
- Evidence supporting: intermittent failure rate (~2%) matches the proportion
  of guest/admin orders
- Evidence to confirm: query `SELECT id FROM orders WHERE customer_id IS NULL`
  — if rows exist, this is the cause
- Evidence to refute: if no orders have NULL customer_id, the null is coming
  from elsewhere

**Hypothesis 2 (less likely):** A race condition between order creation and
customer record creation is leaving a window where the order exists but
the customer does not.
- Evidence to confirm: check order creation timestamp vs. customer record
  creation timestamp for the failing orders

---

### Investigation Steps

1. Run `SELECT id, created_at FROM orders WHERE customer_id IS NULL LIMIT 10;`
   on the production read replica. If rows exist: Hypothesis 1 is confirmed.

2. If no NULL customer_id orders: search logs for the order ID in the error
   and trace the order creation event. Look for any code path that creates an
   order without setting customer_id.

3. If neither confirms: add temporary logging before line 47 to capture
   `order.customer` value before the access, and re-observe for the next
   occurrence.

---

### Root Cause (confirmed after Step 1)

**Root cause:** Orders created via the admin panel do not require a customer
association — the `customer_id` field is set to NULL for admin-created orders.
`OrderService.getOrder()` does not handle the null case.

**Code location:** OrderService.ts, line 47

**Recommended fix:**
```typescript
// Before (crashes on admin-created orders):
const customerId = order.customer.id;

// After (guards the null case):
const customerId = order.customer?.id ?? null;
if (!customerId) {
  // Admin-created order — no customer association
  return { ...order, customerId: null };
}
```

**RISK assessment:**
- Blast radius: `getOrder()` is called from 3 locations — all callers
  receive `customerId: null` for admin orders. Callers must handle null.
- Behavior change: changes the return shape for admin-created orders from
  a crash to a structured null. This is a behavior improvement, not a
  breaking change for non-admin orders.
- Recommended test stub:
  ```
  // TEST STUB — debug fix: null customer guard
  // Scenario: getOrder() with an admin-created order (customer_id IS NULL)
  //           should return order with customerId: null, not throw TypeError
  ```

---

### QUALITY Signal: STRONG
Root cause identified and fix is specific. Null guard addresses the root
cause — not just the symptom.

@di-review-required
```

---

### Example 2: Silent API Failure Traced to Missing Error Handler

**User reports:** "The payment confirmation webhook is being received by our
server but orders are not getting marked as paid. No error in the logs."

**Result (excerpt):**

```
### Failure Summary

**Error:** No exception — silent failure
**Symptom:** Webhook received; orders not updated
**Evidence quality:** Partial — no stack trace, no error logs

---

### Root Cause vs. Symptom

**Symptom:** Orders remain in 'pending' status after webhook fires
**Probable root cause:** The webhook handler calls `orderRepo.markAsPaid()`
but the error from the database call is being swallowed — the webhook returns
200 OK to Stripe regardless of whether the database update succeeded.

---

### Investigation Steps

1. Add temporary logging immediately after `orderRepo.markAsPaid()` to log
   the return value and any error. A silent catch block is the most likely
   cause of the missing log trail.

2. Search the webhook handler for `catch` blocks that log without rethrowing.
   "Silent catch" — catching, logging, and returning success — is the most
   common cause of "no logs, no update."

---

### Recommended fix

Remove or replace the silent catch. The webhook handler must return 4xx or 5xx
to Stripe on database failure — Stripe will retry the webhook until it receives
a success response, which gives the system a second chance to update the order.
```

---

### Example 3: Flaky Test Traced to Shared State Between Tests

**User reports:** "This test fails about 30% of the time when run with the full
test suite but always passes in isolation."

**Root cause excerpt:**

```
### Root Cause

**Root cause:** The test for `UserService.getUser()` modifies a shared
in-memory cache object (the module-level `userCache` singleton). When tests
run in parallel, the preceding test's write to `userCache` is visible to
this test, causing it to return stale data and fail the assertion.

**Recommended fix:** Reset `userCache` in a `beforeEach` or `afterEach` hook.
Alternatively, inject the cache as a dependency so each test can pass a fresh
instance. The module-level singleton is the root cause — not the test itself.

**Test stub:**
```
// TEST STUB — flaky test fix
// Scenario: UserService.getUser() after cache was written by a preceding
//           test — should return fresh data, not the cached value from another test
```
```

---

## Common Rationalizations

These are the statements that get root cause analysis skipped. Rebut them.

| Rationalization | Reality |
|----------------|---------|
| "I'll just keep changing things until it works" | Random changes without a hypothesis waste time and commonly introduce new bugs while hiding the original one. Hypothesis-first is faster, not slower. |
| "It worked in my environment" | "Works here, broken there" is a symptom, not a diagnosis. Environment differences are evidence — follow them to the root cause rather than dismissing them as noise. |
| "Restarting it fixes it, good enough" | Restart-to-recover masks the root cause and guarantees the same incident recurs. A fix that requires restarting is not a fix. |
| "The logs don't say anything useful" | Unhelpful logs are a QUALITY finding in their own right — they mean the next incident will be equally undiagnosable. Surface the logging gap alongside the fix. |

## Governance
- Every fix recommendation must address the root cause — not just silence the
  error, suppress the exception, or hide the symptom behind a broader catch block
- The root cause / symptom distinction must be explicitly stated in every output —
  if the distinction is unclear, state the hypotheses and the investigation steps
  needed to resolve it
- QUALITY signal UNGRADED is appropriate when insufficient evidence prevents
  hypothesis formation — do not fabricate a root cause from incomplete evidence
- All output carries `@di-review-required` — the debug assessment is a hypothesis,
  not a guaranteed root cause; the developer must verify before applying the fix
- Test stubs must be provided for every confirmed root cause — the fix without a
  test means the class of failure can recur silently
- At Early maturity, the coaching note on root cause vs. symptom must be included
  when the fix is a guard/catch that could be interpreted as a symptom-level patch

## Related Skills
- `/refactor-code` — after confirming the root cause, use refactor-code to
  apply the fix with a DI-grounded plan and change rationale table
- `/review-security` — if the bug involves an auth failure, input handling issue,
  or data access anomaly, escalate to a security review
- `/blast-radius-estimator` — if the fix touches a shared function or interface,
  estimate the blast radius before applying the change
- Assert.IQ `/generate-tests` — use to implement the test stub recommended in
  the debug output and prevent recurrence of the same failure class
