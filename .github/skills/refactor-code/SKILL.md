---
name: refactor-code
description: Refactor existing code with DI-grounded rationale. Use when asked to "refactor this", "clean up", "improve this code", "fix code smell", "simplify", or "restructure".
di_signal: DESIGN + QUALITY
maturity_required: early
status: approved
---

# Refactor Code

## Overview
Analyzes existing code through the DESIGN and QUALITY signal lenses, identifies
refactoring candidates prioritized by severity, proposes a plan for developer
approval, then delivers refactored code with a per-change rationale table.

Every refactor preserves existing behavior unless the developer explicitly
requests otherwise. The goal is signal-grounded improvement, not cosmetic
cleanup — each change must be traceable to a specific DI finding.

## When to Use
- Before raising a PR when code feels structurally unclear
- When a code review surfaces design or quality concerns
- When adding a feature to an area with accumulated technical debt
- When onboarding to a codebase and wanting to understand its patterns
- Any time the user says: "refactor this", "clean up", "simplify",
  "fix code smell", "restructure", "improve this code"

## Instructions

### Step 1: Resolve the Code
**From IDE selection or paste:**
- Accept the code block directly
- Note the file path and function/class scope if provided

**From file path:**
- Read the file at the specified path
- If a specific function or class is named, scope the analysis to it;
  otherwise assess the full file

Ask for:
- Work item ID (recommended for traceability — not blocking)
- Refactoring scope if ambiguous (full file, one function, specific concern)

Load context:
- `.dev-iq/config.yaml` → maturity tier, language, team conventions
- `.github/instructions/di-code-standards.instructions.md` → naming,
  patterns, layer rules for this client

### Step 2: Assess Current State
Scan the code for findings across both DI signal layers:

**DESIGN findings:**
- Layer violations (e.g. business logic in a controller, data access in a service)
- Mixed concerns in a single class or function
- Pattern drift from the established project conventions
- Abstraction gaps or over-abstraction
- Naming that does not reflect intent
- New dependencies introduced without an interface boundary

**QUALITY findings:**
- Missing or incomplete error handling on external calls and state mutations
- Unguarded null/undefined access
- Magic numbers or hardcoded strings that should be constants
- Duplicated logic that should be extracted
- Functions doing more than one thing (violates single responsibility)
- TODOs or commented-out code left in production paths
- Testability issues (tight coupling, no injection point)

Assign each finding a severity:

| Severity | Meaning |
|----------|---------|
| 🔴 Critical | Will cause bugs or security issues as written |
| 🟠 High | Likely to cause problems under load or change |
| 🟡 Medium | Structural weakness — should be fixed before merge |
| ⚪ Low | Style or minor clarity improvement |

### Step 3: Prioritize Findings
Order findings: Critical → High → Medium → Low.
Group by DI layer (DESIGN first, then QUALITY).
Do not include findings below the team's agreed threshold at the current
maturity tier.

### Step 4: Propose the Refactoring Plan
**Before writing any code**, output the plan in this format:

```
## Proposed Refactoring Plan

| # | Change | DI Layer | Severity | Rationale |
|---|--------|----------|----------|-----------|
| 1 | [change description] | DESIGN | 🟡 Medium | [why] |
| 2 | [change description] | QUALITY | 🟠 High   | [why] |
...

Behavior preserved: yes / no (if no, describe what changes)
Test stubs: [list any new functions that need tests — Assert.IQ generates tests]

Proceed?
```

**At Early maturity:** always pause here for developer approval.
**At Mid/Higher maturity:** if the user previously confirmed "apply all
changes", proceed without pausing — but still output the plan first.

### Step 5: Apply Approved Refactors
Once the developer approves (all or a subset):

- Output the complete refactored code block
- Annotate each changed section with a brief inline comment referencing
  the finding number: `// Refactor #2: extracted to avoid duplication`
- Do not change behavior unless explicitly approved in Step 4
- Do not add features, frameworks, or abstractions beyond what the
  findings require

### Step 6: Generate Change Rationale Table
After the code block, output a summary table:

```
## Change Rationale

| # | Location | Change | DI Layer | Finding | Behavior Change? |
|---|----------|--------|----------|---------|-----------------|
| 1 | [file/fn] | [description] | DESIGN | [finding] | No |
...
```

If a work item ID was provided, include it in the header:
`Refactored for: AB#XXXX`

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Code to refactor | IDE selection, paste, or file path | Yes |
| Work item ID | User provides or linked PR | Recommended |
| Refactoring scope | User states or inferred from selection | Auto-inferred |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |
| Language / conventions | `.github/instructions/di-code-standards.instructions.md` | Auto-read |

## Output Format

```
## Refactor — [file name or function name]
Work Item: [AB#XXXX or PROJ-XXX, or "none provided"]
Scope: [full file | function: X | class: Y]
Assessed: [date]

---

### Current State
[2–4 sentence summary of what was found and the dominant signal concern]

### Findings

**[Severity] Finding 1**
- DI Layer: [DESIGN | QUALITY]
- Location: [file/line or function]
- Issue: [description]
- Proposed change: [what to do]

[repeat for each finding]

---

### Proposed Refactoring Plan

| # | Change | DI Layer | Severity | Rationale |
|---|--------|----------|----------|-----------|
...

Behavior preserved: yes
Test stubs required: [list, or "none"]

---

### Refactored Code

```[language]
[complete refactored code with inline // Refactor #N annotations]
```

---

### Change Rationale

| # | Location | Change | DI Layer | Finding | Behavior Change? |
|---|----------|--------|----------|---------|-----------------|
...

@di-review-required
```

## Examples

### Example 1: Service Class with Mixed Concerns

**User says:**
```
/refactor-code
```
*(Selects `OrderService.ts` — 120-line file)*

**Result:**

```
## Refactor — OrderService.ts
Work Item: AB#4521
Scope: full file
Assessed: 2026-05-26

---

### Current State
OrderService mixes three concerns: business logic, direct database access,
and email dispatch. Error handling is absent on the email call. One magic
number (status code 3) is used without a named constant. Overall DESIGN
signal is Medium risk; QUALITY signal has one High finding.

### Findings

**🟠 High — Finding 1**
- DI Layer: QUALITY
- Location: OrderService.ts, sendConfirmation()
- Issue: No error handling around emailClient.send() — silent failure
- Proposed change: Wrap in try/catch, throw typed OrderNotificationError

**🟡 Medium — Finding 2**
- DI Layer: DESIGN
- Location: OrderService.ts, getOrder()
- Issue: Direct database query inside service — violates repository pattern
- Proposed change: Extract to OrderRepository, inject via IOrderRepository

**🟡 Medium — Finding 3**
- DI Layer: QUALITY
- Location: OrderService.ts, line 44
- Issue: Magic number `3` used as shipped status — no named constant
- Proposed change: Replace with OrderStatus.Shipped constant

---

### Proposed Refactoring Plan

| # | Change | DI Layer | Severity | Rationale |
|---|--------|----------|----------|-----------|
| 1 | Wrap emailClient.send() in try/catch | QUALITY | 🟠 High | Silent failure on notification — caller cannot react |
| 2 | Extract DB query to OrderRepository | DESIGN | 🟡 Medium | Repository pattern is established in this codebase |
| 3 | Replace magic number 3 with OrderStatus.Shipped | QUALITY | 🟡 Medium | Magic values make intent unclear and break on refactor |

Behavior preserved: yes
Test stubs required: OrderRepository.getById(), OrderRepository.save()

---

### Refactored Code

```typescript
// Refactor #2: DB access extracted to repository — injected via interface
export class OrderService {
  constructor(
    private readonly orderRepo: IOrderRepository,
    private readonly emailClient: IEmailClient,
  ) {}

  async getOrder(id: string): Promise<Order> {
    return this.orderRepo.getById(id);
  }

  async confirmOrder(id: string): Promise<void> {
    const order = await this.orderRepo.getById(id);
    // Refactor #3: named constant replaces magic number
    order.status = OrderStatus.Shipped;
    await this.orderRepo.save(order);

    // Refactor #1: error handling added — was silent failure
    try {
      await this.emailClient.send(order.customerEmail, buildConfirmation(order));
    } catch (err) {
      throw new OrderNotificationError(`Failed to send confirmation for ${id}`, err);
    }
  }
}
```

---

### Change Rationale

| # | Location | Change | DI Layer | Finding | Behavior Change? |
|---|----------|--------|----------|---------|-----------------|
| 1 | sendConfirmation() | Added try/catch around email send | QUALITY | Silent failure on external call | No — error is now surfaced, not swallowed |
| 2 | getOrder() | Extracted DB query to IOrderRepository | DESIGN | Repository pattern violation | No — same data, different call site |
| 3 | line 44 | `3` → `OrderStatus.Shipped` | QUALITY | Magic number | No — same value, named constant |

@di-review-required
```

---

### Example 2: Nothing to Refactor

```
## Refactor — authGuard.ts
Work Item: none provided
Scope: full file

### Current State
No significant findings. File follows single-responsibility, all external
calls are guarded, naming is consistent with di-code-standards.

### Findings
None above Low severity.

### Verdict
No refactoring required. Code is production-ready as written.

@di-review-required
```

---

### Example 3: Early Maturity — Coaching Mode

At Early maturity, every finding includes a coaching note explaining
the underlying principle, not just the fix:

```
**🟠 High — Finding 1**
- DI Layer: QUALITY
- Location: OrderService.ts, sendConfirmation()
- Issue: No error handling around emailClient.send()
- Proposed change: Wrap in try/catch, throw typed OrderNotificationError

**DI Coaching Note:** External calls (email, payment, notification) can
fail for reasons outside your control — network timeout, service outage,
invalid input. If you don't catch those errors explicitly, the failure
disappears silently: the caller thinks everything worked, the user never
gets their confirmation, and no one knows why. The pattern is: catch the
specific error, wrap it in a domain error your caller understands
(OrderNotificationError), and let it propagate so the caller can decide
whether to retry, alert, or log. This is the "fail loudly" principle —
see di-code-standards.instructions.md.
```

Every finding in Early maturity follows this pattern: issue → fix →
coaching note explaining *why the pattern matters* in production systems.

---

## Governance
- Agent always outputs the refactoring plan before writing code — developer
  approves before any code is produced
- Behavior is preserved unless the developer explicitly states otherwise
- Test generation belongs to Assert.IQ — Dev.IQ produces test stubs only
  (function signatures + empty bodies) to mark what needs coverage
- DESIGN signal is UNGRADED when `di-code-standards.instructions.md` cannot be loaded — do not invent naming conventions or structural rules for the project; surface the gap and ask the user to confirm the conventions before proceeding
- Critical and High findings must be addressed before a Go verdict is
  issued on any downstream `/review-pr-readiness` assessment
- `@di-review-required` on all output — human reviews before applying
- Never introduce new dependencies or frameworks without explicit confirmation

## Related Skills
- `/code-review` — line-level review during development; use before `/refactor-code`
- `/review-pr-readiness` — if refactoring clears all High findings, re-run
  to confirm the PR signal is clean
- `/review-architecture` — for structural concerns beyond a single file
- `/review-security` — for security-specific findings surfaced during refactor
- Assert.IQ `/generate-tests` — generates tests for the refactored code
  once stubs are in place