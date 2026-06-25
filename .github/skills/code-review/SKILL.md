---
name: code-review
description: Reviews code through the DI four-layer lens covering intent, design, quality, and risk. Use when asked to "review this code", "check my PR", "review this file", "look at these changes", or "is this ready to merge".
di_signal: DESIGN + QUALITY
maturity_required: early
status: approved
---

# Code Review

## Overview
Reviews a code change — file, diff, or pull request — through all four active
DI signal layers (Intent, Design, Quality, Risk) and produces a structured,
severity-rated findings report with a final merge verdict.

Dev.IQ code review focuses on code design, quality, and risk. It is distinct
from Assert.IQ's `/review-test-quality`, which focuses on test design and
coverage signals. Both can be run on the same PR — they complement each other.

## When to Use
- Developer asks for a code review before raising a PR
- Team wants a consistent DI-grounded review on every PR
- Code change touches a high-risk area (auth, payments, core logic)
- Onboarding review — new developer's first few PRs
- Any time the user says: "review", "check", "look at", "is this ready"

## Instructions

Calibrate review depth by input size:
- **< 20 lines:** compact mode — one finding per category max, no sub-bullets
- **20–200 lines:** standard mode — full category-by-category review
- **> 200 lines:** deep mode — extended review, flag large PR as RISK finding, suggest splitting

### Step 1: Read Context
Resolve the code to review:

**If MCP is connected (GitHub / ADO Repos):**
- Pull the PR diff directly using the configured VCS
- Extract: files changed, lines added/removed, linked work item

**If no MCP / file pasted:**
- Use the code provided directly in the chat
- Ask for the linked work item ID if not provided: "Do you have a work item linked to this change? It helps me check Intent."

Then load (mandatory — DESIGN layer is UNGRADED without these):
- `.github/instructions/di-code-standards.instructions.md` → naming, patterns, structure rules. If this file cannot be loaded, the DESIGN layer is UNGRADED: do not invent coding standards for the project.
- `.github/instructions/di-security.instructions.md` → security checklist
- `.github/instructions/di-traceability.instructions.md` → traceability requirements
- `.dev-iq/config.yaml` → language, framework, coverage threshold

## PR Context Gathering Protocol

Run this protocol whenever a PR number is provided or a diff is available, before writing any findings.

**Step 1 — Fetch the diff:** Run `git diff main...HEAD` (substituting the actual base branch if configured in `.dev-iq/config.yaml`). If no git context is available, ask the user to paste the diff.

**Step 2 — Fetch PR comment threads:** Try in this order:
1. GitHub MCP tool (preferred when MCP is connected)
2. `gh pr view --comments` via the CLI
3. GitHub REST API using stored credentials
4. Ask the user to paste the thread list

For each thread, capture: thread ID, status (`active` / `resolved` / `fixed`), file path, line number, and the comment content. Skip system comments (status-change events only).

**Step 3 — Build the iteration timeline:** List all commits on the branch with one-line summaries (`git log --oneline main..HEAD`). Note commits whose message references "fix review comment", "address feedback", "address review", or similar — these indicate claimed fixes that must be verified.

**Step 4 — Reconcile threads against the diff:** For every non-system thread, check whether the code at that location has changed in the cumulative diff:
- Thread is `resolved` or `fixed` and the diff contains a corresponding change → **OK**
- Thread is `resolved` or `fixed` but the diff shows no corresponding change → **MISMATCH** — escalate to 🔴 Critical in the relevant review category
- Thread is `active` / `pending` with no change → **OPEN** — include in reconciliation table for awareness

If PR threads were fetched, include a **PR Comment Reconciliation** table in the output after the main findings:

| Thread | Location | Status in code | Flag |
|--------|----------|---------------|------|

**Flag values:** OK (change found) · OPEN (no change found) · MISMATCH (marked resolved but code unchanged)

---

## Anti-Patterns Pre-flight

Run these six checks before the category-by-category review. Report each hit as a QUALITY finding ahead of the main review.

1. **Wrapper helpers re-implementing standard library functions** — flag any helper whose body is a thin pass-through to a well-known framework or standard-library call (file copy, directory create, deep clone, group-by, regex compile). Recommend deleting the helper and calling the built-in directly. Severity: 🟡 Medium.

2. **Invariant work inside loops** — flag computations whose result does not change per iteration but are recomputed every iteration (string normalization, `ToUpper`/`ToLower`/`toLowerCase`, regex compilation, reflection lookups, repeated service calls). Hoist to a local variable before the loop or switch to a case-insensitive comparer. Severity: 🟡 Medium; 🔴 High if the loop is unbounded or the call performs I/O.

3. **Untyped traversal of typed data** — flag code that navigates a dynamic, weakly-typed representation (`JObject` indexing, `dict.get(...)`, `map[string]interface{}`, `any`-typed JSON access) when a typed model for the same payload already exists in the codebase or is trivial to introduce. Recommend deserializing once and reading properties. Severity: 🟡 Medium.

4. **Over-defensive try/catch that swallows errors** — flag try/catch blocks that wrap code with no realistic failure mode, or that catch `Exception` (or equivalent) at the top level and then return null/empty/default without a real recovery path. Either delete the try/catch or narrow it to the specific exception type with a real recovery action. Severity: 🟡 Medium; 🔴 High when the swallow hides a data-integrity or correctness failure.

5. **Unused parameters in function signatures** — flag parameters that callers must supply but the method body never reads. Remove them and simplify call sites. Severity: 🟡 Medium.

6. **Repo hygiene issues in production paths** — flag `console.log` / `print` / `fmt.Println` in non-debug paths; TODO comments in production code paths; commented-out code blocks left in place. Severity: 🟡 Medium.

---

### Step 2: INTENT Check
Verify the code does what was asked:

- If a work item is linked: check each AC against the code change
- Flag any AC not addressed by the diff
- Flag any code that goes beyond the scope of the work item

Output:
```
INTENT: ✅ All 4 ACs addressed
— or —
INTENT: ⚠️ AC3 not found in diff. AC5 appears out of scope.
```

### Step 3: DESIGN Check
Review the structural quality of the code:

Check for:
- Adherence to established patterns (from `di-code-standards.instructions.md`)
- SOLID principles (single responsibility, open/closed, etc.)
- Naming clarity — classes, functions, variables
- Function length and complexity (flag functions > 30 lines)
- Code duplication (DRY violations)
- Appropriate abstraction levels
- New dependencies introduced without confirmation
- Dead code or commented-out blocks

### Step 4: QUALITY Check
Review the production-readiness of the code:

Check for:
- Error handling — missing try/catch, generic exceptions, silent failures
- Null/undefined safety — missing guards, optional chaining
- Logging — key operations logged at appropriate level
- Testability — tight coupling, hard-to-mock dependencies
- Performance — N+1 queries, unnecessary loops, blocking async operations
- Magic numbers or strings (should be constants)
- Missing documentation on public interfaces

### Step 5: RISK Check
Assess the risk profile of the change:

Check for:
- Security vulnerabilities:
  - SQL/NoSQL injection
  - XSS vulnerabilities
  - Hardcoded secrets or credentials
  - Insecure deserialization
  - Missing authentication/authorization checks
  - Sensitive data exposure in logs or responses
- Breaking changes to public APIs or interfaces
- Schema or database changes without migration
- New external dependencies (version pinned? license checked?)
- Blast radius — which other modules does this touch?

### Step 6: Build Findings Report
For each issue found, structure it as:

```
**Finding [N]**
- **Severity:** Critical / High / Medium / Low
- **DI Layer:** INTENT / DESIGN / QUALITY / RISK
- **Location:** Line X, function name, or file
- **Issue:** What is wrong
- **Why It Matters:** Impact if not fixed
- **Suggestion:** How to fix it
- **Example:** [corrected code if applicable]
```

Severity definitions:

| Severity | When to Use |
|----------|-------------|
| 🔴 Critical | Security vulnerability, data loss, system failure risk |
| 🟠 High | Logic error, major pattern violation, missing critical error handling |
| 🟡 Medium | Code smell, performance concern, minor pattern deviation |
| 🔵 Low | Style issue, naming improvement, minor readability suggestion |

When writing inline comments on individual lines, prefix each with its action weight:

| Prefix | Meaning | Author action |
|--------|---------|---------------|
| `Critical:` | Must fix — blocks merge | Fix before merge |
| `High:` | Should fix — blocks at Mid+ maturity | Fix before merge at Mid+ |
| `Nit:` | Minor style or naming issue | May ignore |
| `Optional:` | Suggestion — no wrong answer | No action required |
| `FYI:` | Informational context — not a finding | No action required |

### Step 7: Issue Verdict
After all findings, produce the DI Signal Summary and Verdict:

| Verdict | When |
|---------|------|
| 🟢 Approve | No Critical or High issues |
| 🟡 Approve with comments | Medium/Low issues only — mergeable after addressing |
| 🔴 Request changes | Any Critical or High issue present |

At **Early maturity**: all verdicts are advisory with coaching notes.
At **Mid maturity**: High issues block the verdict.
At **Higher maturity**: automated verdict posted directly to PR via MCP.

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Code / diff / PR | GitHub/ADO via MCP, or paste | Yes |
| Work item ID | From PR or user | Recommended |
| Language / framework | `.dev-iq/config.yaml` | Auto-read |
| Code standards | `di-code-standards.instructions.md` | Auto-read |
| Security rules | `di-security.instructions.md` | Auto-read |

## Output Format

```
## Code Review — [filename or PR title]
DI Signals: DESIGN + QUALITY
Work Item: [AB#XXXX or PROJ-XXX if available]
Reviewed: [date]

---

### 🔴 Critical Issues
[findings — each in structured format]

### 🟠 High Issues
[findings]

### 🟡 Medium Issues
[findings]

### 🔵 Low Issues
[findings]

---

### PR Comment Reconciliation
> Include this section only when PR threads were fetched in the PR Context Gathering Protocol.
> Omit entirely for file-only reviews with no PR context.

| Thread | Location | Status in code | Flag |
|--------|----------|---------------|------|
| #N     | file.ts:42 | [change found / no change found] | OK / OPEN / MISMATCH |

**Flag values:** OK (change found) · OPEN (no change found) · MISMATCH (marked resolved but code unchanged)

---

### DI Signal Summary
| Signal  | Status | Notes |
|---------|--------|-------|
| INTENT  |        |       |
| DESIGN  |        |       |
| QUALITY |        |       |
| RISK    |        |       |

### Verdict
[🟢 Approve / 🟡 Approve with comments / 🔴 Request changes]
[One sentence rationale]

### Pre-Approval Checklist
- [ ] All Critical findings resolved
- [ ] All High findings resolved or explicitly deferred with justification
- [ ] INTENT verified — code addresses the stated work item
- [ ] No hardcoded secrets or credentials
- [ ] Error handling present on all external calls
- [ ] Tests added or test stubs documented

@di-review-required
```

## Examples

### Example 1: Critical Security Finding

**User says:** `/code-review` *(pastes user-service.ts)*

**Result:**
```
## Code Review — user-service.ts
DI Signals: DESIGN + QUALITY
Work Item: AB#4521

### 🔴 Critical Issues

**Finding 1**
- **Severity:** Critical
- **DI Layer:** RISK
- **Location:** Line 14, getUserById()
- **Issue:** SQL query built via string concatenation
- **Why It Matters:** SQL injection — attacker can bypass auth or dump the database
- **Suggestion:** Use parameterized queries
- **Example:**
  // Before
  const query = `SELECT * FROM users WHERE id = '${userId}'`;
  // After
  const user = await db.query('SELECT * FROM users WHERE id = $1', [userId]);

### 🟠 High Issues

**Finding 2**
- **Severity:** High
- **DI Layer:** QUALITY
- **Location:** Line 31, updateUser()
- **Issue:** No error handling around database write
- **Why It Matters:** Silent failure — caller receives no signal when update fails
- **Suggestion:** Wrap in try/catch, throw typed exception

### 🟡 Medium Issues

**Finding 3**
- **Severity:** Medium
- **DI Layer:** QUALITY
- **Location:** Line 8
- **Issue:** Magic string 'admin' used directly in role check
- **Suggestion:** Extract to a constant or enum: UserRole.ADMIN

### DI Signal Summary
| Signal  | Status | Notes |
|---------|--------|-------|
| INTENT  | ✅     | Matches AB#4521 ACs |
| DESIGN  | ✅     | Follows service layer pattern |
| QUALITY | ⚠️     | Error handling gap in updateUser |
| RISK    | 🔴     | Critical SQL injection on line 14 |

### Verdict
🔴 Request changes — Critical SQL injection must be resolved before merge.

@di-review-required
```

### Example 2: Clean Code — Approve

```
## Code Review — notification.service.ts

### No Critical Issues
### No High Issues

### 🔵 Low Issues
**Finding 1** — Severity: Low | DI Layer: DESIGN
Line 22: sendEmail could be more descriptive — consider sendOrderStatusEmail

### DI Signal Summary
| Signal  | Status | Notes |
|---------|--------|-------|
| INTENT  | ✅     | All 4 ACs addressed |
| DESIGN  | ✅     | Follows established service pattern |
| QUALITY | ✅     | Error handling, logging, null checks present |
| RISK    | ✅     | No new dependencies, no security concerns |

### Verdict
🟢 Approve — Code is production-ready. One low-priority naming suggestion above.

@di-review-required
```

### Example 3: Early Maturity — Coaching Mode

At Early maturity, every finding includes a coaching note:

```
**Finding 1**
- **Severity:** High | **DI Layer:** DESIGN
- **Issue:** Business logic in the controller layer
- **DI Coaching Note:** The DESIGN signal checks for clean layer separation.
  Controllers handle HTTP concerns only; services handle business logic.
  This follows the Service/Controller pattern in di-code-standards.instructions.md.
```

## Common Rationalizations

These are the statements that get review findings dismissed. Rebut them.

| Rationalization | Reality |
|----------------|---------|
| "AI-generated code is probably fine" | AI code needs more scrutiny, not less. It's confident and plausible — even when wrong. |
| "The tests pass, so it's good" | Tests are necessary but not sufficient. They don't catch architecture problems, security issues, or readability failures. |
| "It's a small change, doesn't need a full review" | Small changes introduce the majority of production bugs. Size is not a proxy for risk. |
| "I'll clean it up later" | Later never comes. Technical debt compounds. Flag it now and track it as a follow-up. |
| "The CI is green" | CI validates that code runs — not that it's correct, secure, or maintainable. |
| "The reviewer approved it already" | A human approval is not a DI signal assessment. Both add value independently. |

## Governance
- Critical and High security findings always block — regardless of maturity tier
- Never approve code with hardcoded secrets or credentials
- `@di-review-required` on all output — human makes the final merge decision
- At Early maturity: all verdicts are advisory with coaching notes
- At Mid maturity: High issues block the verdict
- At Higher maturity: verdict can be posted to PR via MCP if configured

## Related Skills
- `/review-acceptance-criteria` — review ACs before coding starts
- `/review-security` — deeper security-only review for high-risk changes
- `/review-pr-readiness` — full PR assessment including DI risk band
- `/blast-radius-estimator` — assess downstream impact of this change
- Assert.IQ `/review-test-quality` — review test coverage and quality (QE signal)

## Post-Review Follow-Up

After delivering the review output, offer these options:

- "Want me to run /new-pull-request and attach this review to the PR description?"
- "Want me to run /review-security for a dedicated security pass?"
- "Want me to fix the Critical and High findings now?"
- "Want me to generate test stubs for the functions flagged in this review?"

Keep the offer to one or two options — pick the highest-impact follow-up based on the findings. MISMATCH threads in the PR Comment Reconciliation table take precedence over general code findings.