---
name: review-error-handling
description: Review error handling coverage in a PR diff, file, or module. Surfaces unhandled external calls, silent catches, swallowed errors, and missing typed domain errors. Use when asked to "review error handling", "check our error coverage", "are errors handled correctly", or "error handling review".
di_signal: QUALITY
maturity_required: early
status: approved
---

# Review Error Handling

## Overview

Reviews error handling coverage in a PR diff, file, or module across four
dimensions: external call coverage, error propagation discipline, logging
discipline, and typed domain error usage. The output is a structured QUALITY
signal assessment with findings ranked by severity.

The focus is on the failure paths — the code that executes when something goes
wrong. Production reliability is determined more by how code handles failures
than by how it handles the happy path. A function that handles the success
case perfectly but swallows errors from its database call is a reliability
liability waiting for a failure condition to trigger.

## When to Use

- Before merging a PR that touches external calls (database, HTTP, queue, filesystem)
- When reviewing code that handles payments, authentication, or data integrity
- When debugging a silent failure whose root cause turns out to be a swallowed error
- When onboarding a module and assessing its operational reliability
- Any time the user says: "review error handling", "check our error coverage",
  "are errors handled correctly", "error handling review", "is this production-ready"

## Instructions

### Step 1: Gather Inputs

Accept one of:
- **PR diff** — `git diff main...HEAD`
- **File or module path** — read the specified file(s)
- **Code paste** — scan pasted code

Load context:
- `.dev-iq/config.yaml` → `stack.language` and `stack.framework` for language-specific patterns
- Read 2–3 adjacent files to understand the team's established error handling patterns

### Step 2: Identify External Call Sites

Mark every call to an external system as a coverage obligation:

| Category | Examples |
|----------|---------|
| Database / ORM | `db.query()`, `repo.save()`, `findOrFail()`, `transaction()` |
| HTTP / network | `fetch()`, `axios.get()`, `http.Get()`, `requests.post()` |
| Filesystem | `fs.readFile()`, `open()`, `writeFileSync()` |
| Message queue | `queue.send()`, `consumer.receive()`, `publish()` |
| External service | Email, SMS, payment gateway, third-party API calls |
| Subprocess | `exec()`, `spawn()`, `subprocess.run()` |

For each identified call site: assess whether error handling is present and correct.

### Step 3: Assess Each Dimension

**Dimension 1: External call coverage**
Every identified external call must be wrapped in error handling. An unhandled
external call is a QUALITY finding.

| Finding | Severity |
|---------|---------|
| External call with no error handling whatsoever | 🔴 High |
| Error caught but not propagated (silent catch) | 🔴 High |
| Error caught and logged but return value is success | 🔴 High |
| Error handling present but incomplete (e.g., only catches one exception type) | 🟡 Medium |

**Dimension 2: Error propagation**
Errors must propagate as typed domain errors, not generic exceptions.

| Finding | Severity |
|---------|---------|
| `throw new Error("something failed")` — generic, no type | 🟡 Medium |
| Error rethrown without context (caller can't distinguish failure reason) | 🟡 Medium |
| Error swallowed in a catch block (logged but not rethrown or returned) | 🔴 High |
| Error converted to a domain type with context — no finding | Pass |

**Dimension 3: Logging discipline**
Errors must be logged before throwing. Log messages must be actionable.

| Finding | Severity |
|---------|---------|
| Error thrown without any log statement | 🟡 Medium |
| Error logged at wrong level (DEBUG for a payment failure) | ⚪ Low |
| PII or credentials present in the log message | 🔴 High (security) |
| Log message is not actionable ("something went wrong") | ⚪ Low |
| Error logged appropriately at ERROR level with context — no finding | Pass |

**Dimension 4: Null and undefined safety at call site**
Results from external calls must be checked before use.

| Finding | Severity |
|---------|---------|
| `.find()` / `.get()` result used without null check | 🟡 Medium |
| Optional return value accessed directly without guard | 🟡 Medium |
| Result checked and guarded — no finding | Pass |

### Step 4: Identify Patterns

After scanning individual call sites, identify systemic patterns:

- **Silent catch pattern**: `catch(e) { console.log(e); return; }` — all errors in a
  module are logged and swallowed. Flag as a systemic QUALITY finding.
- **Generic exception pattern**: `throw new Error("...")` used throughout — no
  typed domain errors anywhere. Flag as a systemic DESIGN finding.
- **Log-then-rethrow done correctly**: `logger.error(e); throw e;` — note as PASS.

### Step 5: Produce the Report

At **Early maturity**: include a coaching note for each High finding explaining
the production failure mode that the missing error handling enables.

At **Mid/Higher maturity**: structured findings only.

## Inputs Required

| Input | Source | Required |
|-------|--------|----------|
| PR diff, file path, or code paste | User provides | Yes |
| Stack language and framework | `.dev-iq/config.yaml` | Auto-read |
| Adjacent files for established error handling patterns | Auto-read | Recommended |
| Work item ID | User provides | Recommended |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## Error Handling Review — [PR title / file / module]
Work Item: [AB#XXXX | PROJ-XXX | #456 | "none provided"]
Language: [TypeScript | Python | Go | Java | ...]
External call sites identified: [N]
Assessed: [date]

---

### Findings

#### [file path]

**🔴 High — [finding title]**
- Location: [file:line]
- Pattern: [what the code does — e.g., "catches DatabaseError, logs it, returns undefined"]
- Risk: [the production failure this enables — e.g., "caller receives undefined and crashes on the next property access; no alert fires"]
- Fix: [specific, actionable suggestion]

**🟡 Medium — [finding title]**
- Location: [file:line]
- Pattern: [what the code does]
- Risk: [production risk]
- Fix: [suggestion]

**⚪ Low — [finding title]**
- Location: [file:line]
- Pattern: [what the code does]
- Fix: [suggestion]

[Repeat per file]

---

### Coverage Summary

| Dimension | Status | Findings |
|-----------|--------|---------|
| External call coverage | [Pass / Weak / Fail] | [N High, N Medium] |
| Error propagation | [Pass / Weak / Fail] | [N findings] |
| Logging discipline | [Pass / Weak / Fail] | [N findings] |
| Null / undefined safety | [Pass / Weak / Fail] | [N findings] |

**Overall: [N] High, [N] Medium, [N] Low**

---

### QUALITY Signal: [STRONG | WEAK | UNGRADED]

STRONG: no High findings; Medium findings are isolated and documented
WEAK: one or more High findings present
UNGRADED: code could not be read or call sites could not be identified

@di-review-required
```

## Examples

### Example 1: Payment Service — Silent Catch Found

**Code reviewed:**

```typescript
async processPayment(orderId: string): Promise<void> {
  try {
    await this.stripeClient.charge(orderId);
    await this.orderRepo.markAsPaid(orderId);
  } catch (error) {
    console.log('Payment failed:', error);
    return; // ← silent swallow
  }
}
```

**Finding:**

```
#### src/payments/PaymentService.ts

**🔴 High — Silent catch swallows payment failure**
- Location: PaymentService.ts:L47 (catch block)
- Pattern: Catches all errors from stripeClient.charge() and orderRepo.markAsPaid(),
  logs at console.log level, and returns undefined — indicating success to the caller.
- Risk: The caller receives no signal that the payment failed. The order is not
  marked as paid (correct), but the caller assumes success and may send a
  confirmation email or redirect to a success page. Stripe may not retry because
  the webhook handler returned 200. The payment is lost silently.
- Fix:
  ```typescript
  } catch (error) {
    logger.error('Payment processing failed', { orderId, error });
    throw new PaymentProcessingError(`Payment failed for order ${orderId}`, { cause: error });
  }
  ```
  The caller must handle PaymentProcessingError and return an appropriate response.
```

---

### Example 2: Go HTTP Call — No Error Check

**Code reviewed:**

```go
resp, _ := http.Get(inventoryServiceURL + "/stock/" + productID)
defer resp.Body.Close()
```

**Finding:**

```
**🔴 High — HTTP error return discarded with blank identifier**
- Location: InventoryClient.go:L23
- Pattern: http.Get() error discarded with `_`; resp is used directly.
- Risk: When the inventory service is unreachable, http.Get returns (nil, error).
  `resp.Body.Close()` panics on nil. The service crashes on any inventory
  service outage rather than returning a graceful error to its caller.
- Fix:
  ```go
  resp, err := http.Get(inventoryServiceURL + "/stock/" + productID)
  if err != nil {
    return nil, fmt.Errorf("inventory service unreachable: %w", err)
  }
  defer resp.Body.Close()
  ```
```

---

### Example 3: Strong Error Handling — QUALITY STRONG

```
## Error Handling Review — feature/user-authentication
External call sites identified: 4

---

### Findings

No High findings. No Medium findings.

⚪ Low — Log message at L67 could include the request ID for correlation
- Location: AuthService.ts:L67
- Pattern: `logger.error('Token validation failed', { userId })` — missing requestId
- Fix: Add `requestId` from the request context to the log payload for tracing

---

### QUALITY Signal: STRONG

All 4 external call sites (database query, JWT validation, session store write,
audit log write) are wrapped in typed error handling with appropriate logging.
One Low finding for log context improvement — does not affect verdict.

@di-review-required
```

---

## Common Rationalizations

These are the statements that get error handling review skipped. Rebut them.

| Rationalization | Reality |
|----------------|---------|
| "The happy path works, so it's ready to ship" | Production environments expose failure paths that test environments don't: network timeouts, database connection limits, downstream service outages. The happy path is not the reliability test. |
| "We have a global error handler, so individual handlers don't matter" | Global handlers catch what individual handlers don't swallow. A silent catch that logs and returns success will never reach the global handler — it has already told the caller everything is fine. |
| "We'll add better error handling when we see problems in production" | Production is where customers discover the problem first. Error handling added after a silent failure incident is error handling that cost you a customer and a postmortem. |
| "Error handling is boilerplate — AI tools generate it" | AI-generated error handling is structurally present but often semantically wrong: catching and rethrowing the same error type, logging without context, swallowing in a catch-all. Presence of error handling code ≠ correct error handling. |

## Governance

- Every external call site is a coverage obligation — no exceptions for
  "simple" or "unlikely to fail" calls
- Silent catches (catch → log → return success) are always High findings —
  they actively deceive the caller about the state of the system
- PII or credentials in error log messages are always escalated as a security
  finding to `review-security` — not handled as a QUALITY finding only
- STRONG may only be assigned when no High findings exist; isolated Medium
  findings do not block STRONG but must be documented
- At Early maturity, every High finding includes a coaching note describing
  the specific production failure mode — "unhandled error" is not sufficient;
  "caller receives undefined and silently processes a failed payment" is
- All output carries `@di-review-required`

## Related Skills

- `/review-security` — escalate findings for PII in logs, exposed stack traces
  in error responses, or auth-related error handling gaps
- `/debug-issue` — when a production bug turns out to be a swallowed error,
  use debug-issue to trace root cause and recommend the specific fix
- `/refactor-code` — when error handling findings are systemic across a module,
  use refactor-code to plan a cohesive improvement rather than fixing each
  site in isolation
- `/review-pr-readiness` — includes QUALITY signal assessment; error handling
  is one of the dimensions checked in the full PR readiness review
