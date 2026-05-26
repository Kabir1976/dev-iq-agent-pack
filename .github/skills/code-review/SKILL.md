---
name: code-review
description: Reviews code through the DI five-layer lens covering design, quality, security, and risk. Use when asked to "review this code", "check my PR", "review this file", "look at these changes", or "is this ready to merge".
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

### Step 1: Read Context
Resolve the code to review:

**If MCP is connected (GitHub / ADO Repos):**
- Pull the PR diff directly using the configured VCS
- Extract: files changed, lines added/removed, linked work item

**If no MCP / file pasted:**
- Use the code provided directly in the chat
- Ask for the linked work item ID if not provided: "Do you have a work item linked to this change? It helps me check Intent."

Then load:
- `.github/instructions/di-code-standards.instructions.md` → naming, patterns, structure rules
- `.github/instructions/di-security.instructions.md` → security checklist
- `.github/instructions/di-traceability.instructions.md` → traceability requirements
- `.dev-iq/config.yaml` → language, framework, coverage threshold

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