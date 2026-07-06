---
name: explain-code
description: Explain code through the INTENT lens — what it does, whether it does what it says, and what it assumes. Use when asked to "explain this", "what does this do", "walk me through this code", or "document this function".
di_signal: INTENT
maturity_required: early
status: approved
---

# Explain Code

## Overview
Reads a code artifact and explains it in plain language through the INTENT lens —
what the code is meant to do, whether the implementation matches its stated purpose,
and what assumptions or edge cases a reader would miss on first glance.

Unlike a pure documentation tool, this skill actively checks for INTENT gaps:
mismatches between a function's name, its comments, its linked work item, and
what the code actually does. A confident explanation requires positive evidence
of alignment, not just the absence of obvious errors.

## When to Use
- When onboarding to a new codebase or unfamiliar module
- Before refactoring — to confirm your understanding before changing behavior
- When a code review surfaces confusion about what a section is doing
- When writing documentation and needing a grounded plain-language description
- When a PR diff includes code that is not self-evident from reading the diff
- Any time the user says: "explain this", "what does this do", "walk me through
  this", "document this function", "what is this code for", "I don't understand
  what this does"

## Instructions

### Step 1: Resolve the Code
**From IDE selection or paste:**
- Accept the code block directly
- Note the file path, function name, and class scope if provided

**From file path:**
- Read the file at the specified path
- If a specific function or class is named, scope the explanation to it;
  otherwise explain the full file at a module level

Ask for (if not already known):
- Work item ID (optional — improves INTENT assessment)
- Any known context (e.g. "this is called by the payment flow")

Load context:
- `.dev-iq/config.yaml` → maturity tier, language
- `.github/instructions/di-foundation.instructions.md` → INTENT layer rules

### Step 2: Assess INTENT Signal
Before explaining, assess whether the code's purpose is clear and consistent:

**Check for INTENT alignment:**
- Does the function/class name accurately describe what it does?
- Do inline comments match the actual behavior?
- If a work item is linked, does the code implement what the work item requires?
- Are there behaviors the code performs that are not declared anywhere?

**Assign INTENT signal state:**
- **STRONG** — name, comments, and behavior are aligned; code does exactly
  what it says it does; no hidden side effects
- **WEAK** — name or comments are misleading, behavior contradicts stated
  purpose, or the code does more (or less) than the work item describes
- **UNGRADED** — no name, no comments, and no work item — explanation is
  based on behavior inspection alone; intent cannot be verified

### Step 3: Produce the Explanation
Structure the explanation in three parts:

**Purpose**
One to three sentences stating what this code is for and when it runs.
Use the domain language of the codebase, not generic programming terms.

**How It Works**
Step-by-step walkthrough of the code's execution path:
- What inputs it accepts and what constraints they carry
- Key branches (if/else, try/catch) and what triggers each path
- What the code mutates, returns, or emits
- What external dependencies it calls and what it expects from them

**Assumptions and Edge Cases**
Explicit list of what the code assumes to be true that is not enforced:
- Input constraints that are not validated
- Environmental assumptions (config values, database state)
- Race conditions or concurrency assumptions
- Behaviors that only work correctly under specific conditions

### Step 4: State the INTENT Signal
Close with an explicit INTENT signal verdict and any gap findings.

At **Early maturity**: add a coaching note for each WEAK or UNGRADED finding,
explaining why the gap matters in production (not just what the gap is).

At **Mid/Higher maturity**: state the signal and findings concisely without
coaching notes.

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Code to explain | IDE selection, paste, or file path | Yes |
| Work item ID | User provides or linked PR | Optional — improves INTENT assessment |
| Calling context | User describes or inferred from file structure | Optional |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## Explain Code — [function name or file name]
Work Item: [AB#XXXX or PROJ-XXX, or "none provided"]
Scope: [function: X | class: Y | module: Z]
Assessed: [date]

---

### Purpose
[1–3 sentences describing what this code is for and when it runs,
using domain language]

### How It Works
1. [First step in execution — inputs and their constraints]
2. [Key logic or branching — what each path does]
3. [External calls — what is called and what is expected back]
4. [Output or mutation — what the code produces or changes]
[Continue for each meaningful execution step]

### Assumptions and Edge Cases
- [Assumption 1 — what must be true that is not enforced]
- [Assumption 2 — environmental or state dependency]
- [Edge case 1 — behavior that may surprise a caller]
[Continue for each assumption or edge case found]

---

### INTENT Signal: [STRONG | WEAK | UNGRADED]
[One sentence verdict: does the code do what it says it does?]

[If WEAK or UNGRADED:]
**INTENT Gap:**
- [Gap description — what is misaligned or unverifiable]
- [Recommended fix — rename, add comment, link work item, or split function]

@di-review-required
```

## Examples

### Example 1: Clean JWT Validator (INTENT STRONG)

**User says:** `/explain-code` *(selects `validateToken.ts`)*

```typescript
export function validateToken(token: string): JwtPayload {
  const payload = jwt.verify(token, config.jwtSecret, {
    algorithms: ['HS256'],
    issuer: 'api.example.com',
    audience: 'web-client',
  });
  return payload as JwtPayload;
}
```

**Result:**

```
## Explain Code — validateToken.ts
Work Item: none provided
Scope: function: validateToken
Assessed: 2026-06-06

---

### Purpose
Validates a JWT bearer token and returns its decoded payload. Called on
every authenticated request before the handler executes. Returns the
payload if valid, throws if not.

### How It Works
1. Accepts a raw JWT string from the request (expects the raw token value,
   not a "Bearer ..." header string — the caller strips the prefix).
2. Calls `jwt.verify()` with three constraints enforced by the library:
   algorithm must be HS256 (rejects algorithm:none attacks), issuer must
   match `api.example.com`, and audience must be `web-client`.
3. The secret is read from `config.jwtSecret` — a runtime config value,
   not a hardcoded string.
4. On success, returns the decoded payload cast to `JwtPayload`.
   On failure (expired, wrong issuer, bad signature), `jwt.verify()`
   throws — the error propagates to the caller.

### Assumptions and Edge Cases
- The caller is responsible for stripping the `Bearer ` prefix before
  passing the token. If the full header value is passed, verification fails.
- `config.jwtSecret` is assumed to be set at startup — no guard if it is
  undefined.
- The JwtPayload cast is unchecked — if the token payload doesn't match
  the type shape, downstream code will fail silently on missing fields.

---

### INTENT Signal: STRONG
Function name, behavior, and constraints are aligned. The code does
exactly what it says and nothing more.

@di-review-required
```

---

### Example 2: Payment Function with Silent Error Swallow (INTENT WEAK)

**User says:** `/explain-code` *(selects `processPayment` in `billing.js`)*

```javascript
async function processPayment(orderId, amount) {
  try {
    const result = await stripeClient.charges.create({ amount, currency: 'usd' });
    await db.orders.update({ id: orderId }, { status: 'paid', chargeId: result.id });
  } catch (e) {
    console.log('payment failed');
  }
}
```

**Result:**

```
## Explain Code — billing.js
Work Item: none provided
Scope: function: processPayment
Assessed: 2026-06-06

---

### Purpose
Charges a customer via Stripe and marks the order as paid in the database.
However, the current implementation silently absorbs all failures — the
caller receives no indication that payment or the database update failed.

### How It Works
1. Accepts an order ID and a charge amount (in the smallest currency unit —
   cents for USD).
2. Creates a Stripe charge for the amount in USD via `stripeClient.charges.create()`.
3. On success, updates the order record in the database to status "paid"
   with the Stripe charge ID.
4. On any error from either the Stripe call or the database update: logs
   "payment failed" and returns normally — no error is thrown or returned.

### Assumptions and Edge Cases
- The function assumes USD currency — no way for the caller to specify
  another currency.
- A Stripe success followed by a database failure leaves the customer
  charged but the order still in an unpaid state. The catch block will
  swallow this, making it undetectable.
- The caller receives `undefined` whether payment succeeded or failed —
  there is no way to distinguish the two outcomes.
- `chargeId` is written to the database but there is no idempotency check —
  double-calling with the same orderId will create a second Stripe charge.

---

### INTENT Signal: WEAK
The function name implies a payment is processed, but the implementation
hides all failure modes from the caller. The code does less than it
claims — callers cannot act on failure.

**INTENT Gap:**
- Silent catch means the caller cannot distinguish a successful payment
  from a failed one. A function named `processPayment` must surface
  payment failures.
- Recommended fix: remove the try/catch or rethrow as a typed
  `PaymentProcessingError` so callers can handle retries and alerts.

@di-review-required
```

---

### Example 3: Early Maturity — Coaching Note on INTENT Gap

At Early maturity, WEAK findings include a coaching note explaining why
the principle matters, not just what to fix:

```
### INTENT Signal: WEAK
...

**INTENT Gap:**
- Function name is `getUserPreferences` but the code also writes a
  default preference record on first call. A read function with a
  hidden write side effect will surprise callers and is untestable
  as a pure read.
- Recommended fix: rename to `getOrCreateUserPreferences`, or extract
  the write to a separate `ensureDefaultPreferences()` call.

**DI Coaching Note (Early maturity):** INTENT gaps at the function level
accumulate into architecture problems. When a function does more than its
name says, callers start relying on the side effect — then it's load-bearing
behavior with no tests and no documentation. Naming is the cheapest form of
documentation available. If the name is wrong, fix the name first; if the
behavior is wrong, fix the behavior. Don't leave both wrong.
```

---

## Common Rationalizations

These are the statements that get code explanation skipped. Rebut them.

| Rationalization | Reality |
|----------------|---------|
| "Just read the code" | Code tells you what it does — not why it was written that way, what constraints shaped it, or what assumptions it relies on. Those are what understanding requires. |
| "It's obvious from the variable names" | Naming captures intent at the point of writing, not the tradeoffs rejected, the edge cases handled, or the system context it lives in. Obvious to the author ≠ obvious to the next developer. |
| "We don't need this for a quick fix" | Fixes applied without understanding produce secondary bugs. The fastest path to a correct fix is understanding the code first, not assuming. |
| "AI-generated code is self-explanatory" | AI-generated code is fluent, not transparent. It can be plausible-looking while encoding subtle assumptions or missing edge cases that only become visible with a DI-layer explanation. |

## Governance
- INTENT signal must be assessed and stated explicitly — not implied or omitted
- STRONG may only be assigned when name, behavior, and (if available) work item
  are positively verified as aligned; absence of obvious gaps is UNGRADED, not STRONG
- Explanations must not introduce interpretations beyond what the code does —
  if behavior is ambiguous, state the ambiguity
- All output carries `@di-review-required` — the explanation is a draft, not a
  substitute for the developer's own understanding
- At Early maturity, every WEAK or UNGRADED finding includes a coaching note
  explaining the production consequence, not just the fix
- Never fabricate intent from naming alone when the implementation contradicts
  the name — state the contradiction as an INTENT gap

## Related Skills
- `/refactor-code` — after explaining, if INTENT gaps or QUALITY issues are
  found, use refactor-code to address them with a plan before changing anything
- `/validate-acceptance-criteria` — if the code is tied to a work item,
  verify the ACs are met after understanding what the code actually does
- `/generate-adr` — if the explanation reveals a design decision that is not
  documented anywhere, generate an ADR to capture it
- `/review-pr-readiness` — a code explanation is a useful precursor to a full
  PR readiness assessment when reviewers are unfamiliar with the changed module
