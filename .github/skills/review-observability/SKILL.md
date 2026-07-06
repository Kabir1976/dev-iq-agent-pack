---
name: review-observability
description: Review code for adequate observability coverage — logging, metrics instrumentation, distributed tracing, alerting hooks, and health endpoints. Use when asked to "review logging", "check observability", "do we have enough monitoring", "is this instrumented properly", "review telemetry".
di_signal: QUALITY
maturity_required: early
status: approved
---

# Review Observability

## Overview

Assesses whether new or changed code is observable in production: can an
on-call engineer diagnose a failure, measure impact, and understand system
state from the instrumentation alone?

Observability review is part of the QUALITY signal. A PR that passes unit
tests but emits no useful signal when it fails in production is not
production-ready. This skill closes that gap.

The review covers four pillars:
1. **Logging** — are the right events logged at the right levels?
2. **Metrics** — are key business and technical events measured?
3. **Tracing** — can a request be followed across service boundaries?
4. **Alerting** — do critical failure paths have alertable signals?

It also checks for anti-patterns: PII in logs, stack traces returned to
callers, and silent error swallowing.

## When to Use

- Before merging a PR that adds a new feature, service, or integration
- When an incident post-mortem reveals "we had no signal" for a failure mode
- When reviewing a PR that touches error handling, external calls, or business
  logic that could silently degrade
- When `/review-pr-readiness` raises an UNGRADED QUALITY finding because
  observability cannot be assessed from the diff alone
- Any time the user says: "review logging", "check observability", "is this
  instrumented properly", "review telemetry", "do we have enough monitoring"

## Instructions

### Step 1: Gather scope

Accept a diff, PR number (fetched via GitHub/ADO MCP), or specific file(s).
Read `.dev-iq/config.yaml` → `stack.languages` and `signals.quality` to
identify the logging framework and observability stack in use (Sentry, Grafana,
Datadog, Honeycomb, etc.). If observability tools are configured in MCP, note
which are available for live correlation.

### Step 2: Log level discipline

For every log statement in the diff, verify correct level assignment per the
DI code standards:

| Level | Correct use | Anti-pattern |
|-------|------------|--------------|
| `ERROR` | Unexpected failures — unhandled exceptions, broken invariants | Using for expected/recoverable conditions |
| `WARN` | Recoverable issues — retry triggered, degraded mode entered | Using for normal branching |
| `INFO` | Key state changes — order placed, payment processed, user authenticated | Over-logging routine operations |
| `DEBUG` | Internal detail for developers — stripped in production | Leaving DEBUG-level PII in code paths |

Flag:
- **PII, credentials, or secrets in any log statement** — QUALITY Critical
- **Stack traces or internal error details returned to the caller** — QUALITY High
- **Silent error swallowing** (catch block with no log) — QUALITY High
- **Log at entry AND exit of key business operations** — flag if missing

### Step 3: External call coverage

Every call to an external system (database, HTTP, message queue, cache,
filesystem) must be wrapped in error handling AND logged before throwing.
Scan the diff for:
- `fetch`, `axios`, `HttpClient`, `RestTemplate`, `requests.get`, etc.
- Database queries and ORM calls
- Message queue publish/consume calls
- Any `await` on a network-bound operation

For each: is there a try/catch? Is the error logged with enough context
(which service, which endpoint, what the payload shape was — without PII)?

### Step 4: Metrics instrumentation

Check whether new business-critical operations emit metrics:
- New endpoints: request count, latency histogram, error rate
- Payment/checkout flows: success rate, abandonment rate
- Background jobs: run count, duration, failure count
- Cache operations: hit/miss ratio

Flag as QUALITY WEAK when a new business operation is added with no metric
instrumentation and the stack supports it (read `signals.quality` in config).

At **Early maturity**: note missing metrics but do not block. Suggest the
instrumentation call the team should add.

At **Mid/Higher maturity**: missing metrics on a new business operation is a
QUALITY finding that affects the PR verdict.

### Step 5: Distributed tracing

When the stack uses distributed tracing (OpenTelemetry, Jaeger, Zipkin,
Datadog APM, Honeycomb), check:
- New service calls are wrapped with span creation
- Trace context is propagated across async boundaries (thread pools, queues,
  background jobs)
- Spans include relevant attributes (user ID hash, order ID, service name) —
  without PII

### Step 6: Health and readiness endpoints

For new services or new external dependencies added to an existing service:
- Does a health endpoint exist? Does it check the new dependency?
- Does the readiness probe exclude the service from load until it is healthy?

Flag missing health checks as QUALITY WEAK when a new external dependency is
introduced.

### Step 7: Alerting coverage

Identify the critical failure paths introduced by the change:
- If payment processing fails, is there an alertable signal?
- If an external integration goes down, does on-call know within the SLA window?

This is a RISK finding when a new critical path has no alerting path. Flag it
with the specific failure scenario and the missing alert.

### Step 8: Anti-patterns checklist

| Anti-pattern | Severity | Description |
|-------------|---------|-------------|
| PII in logs | Critical | Any personal data (email, name, address, card number) in a log statement |
| Secrets in logs | Critical | API keys, tokens, passwords logged at any level |
| Stack trace to caller | High | Internal exception detail in an HTTP response body |
| Silent catch | High | `catch (e) {}` or `except: pass` with no log or rethrow |
| Log-and-swallow | Medium | Logging the error but returning success to the caller |
| Missing entry/exit log | Medium | Key business operation with no observability at boundaries |
| Wrong log level | Low | INFO for failures, ERROR for routine branching |

## Inputs Required

| Input | Source | Required |
|-------|--------|----------|
| Diff, PR, or file(s) to review | Paste, PR number, or file path | Yes |
| Observability stack | `.dev-iq/config.yaml` → `signals.quality` | Auto-read |
| Stack / framework | `.dev-iq/config.yaml` → `stack` | Auto-read |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## Observability Review — [PR title / file / feature]
Source: [PR # | file path | paste]
Stack: [logging framework, metrics platform]
Generated: [date]

---

### Logging — [STRONG | WEAK | UNGRADED]

[Findings table]
| File | Line | Finding | Severity |
|------|------|---------|---------|
| payments/checkout.ts | 87 | Silent catch — PaymentGatewayError swallowed | High |
| orders/order-service.ts | 134 | PII (email) in INFO log | Critical |

[Or: "No logging issues found — level discipline correct, entry/exit logged for OrderService.processOrder()."]

---

### External Call Coverage — [STRONG | WEAK | UNGRADED]

[List of external calls found and their error handling status]

---

### Metrics — [STRONG | WEAK | UNGRADED]

[What is instrumented vs. what is missing for new business operations]

---

### Tracing — [STRONG | WEAK | UNGRADED | N/A — tracing not configured]

---

### Alerting — [STRONG | WEAK | UNGRADED]

[Critical failure paths and whether alertable signals exist]

---

### Anti-patterns

| Anti-pattern | Location | Severity |
|-------------|---------|---------|
| [found anti-patterns] | | |

---

### QUALITY Signal: [STRONG | WEAK | UNGRADED]
[Overall assessment: is this observable enough to operate in production?]

**Blocking findings:** [list Critical/High findings that must be resolved]
**Recommended additions:** [non-blocking improvements]

@di-review-required
```

## Common Rationalizations

These are the statements that get observability review skipped. Rebut them.

| Rationalization | Reality |
|----------------|---------|
| "We'll add logging when we need to debug something" | You need logging at the moment something breaks in production — not after. Logging added reactively is logging that doesn't exist for the incident that's happening right now. |
| "The framework logs enough automatically" | Framework logs tell you what happened at the infrastructure level. Business operation logs — order placed, payment processed, user authenticated — are what incident responders need to diagnose failures. |
| "Metrics are expensive to set up" | Unobserved services are expensive in a different way: every incident in an unobserved system is a blind investigation. Setup cost is paid once; observability pays for itself on the first production issue. |
| "Our system is simple enough that we don't need dashboards" | Simple systems become complex ones. Adding observability before complexity arrives is easier than retrofitting it after an incident reveals you're flying blind. |

## Governance

- PII or credentials in any log statement is always Critical — flag immediately
  regardless of maturity tier or delivery pressure
- Stack traces in HTTP responses are always High — flag immediately
- Silent error swallowing is always High — a failure that produces no signal
  is worse than a failure that crashes visibly
- At Early maturity: missing metrics are advisory; at Mid/Higher: they affect
  the QUALITY signal verdict
- Never fabricate observability coverage ("no issues found") when the code
  path could not be assessed — mark as UNGRADED with reason

## Related Skills

- `/review-security` — runs the complementary QUALITY check (OWASP + LLM);
  often run together before a PR merge
- `/review-pr-readiness` — incorporates this review's QUALITY signal into the
  overall Go/Hold/Discuss verdict
- `/debug-issue` — when an incident occurs, poor observability is often why
  diagnosis is hard; this skill is the prevention step
- `/review-ai-integration` — when LLM calls are in scope, includes token usage
  and cost logging checks alongside this review
