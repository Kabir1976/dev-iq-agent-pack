---
name: review-pr-readiness
description: Assesses whether a pull request is ready to merge using the DI four-layer signal model. Use when asked "is this PR ready", "should I merge this", "review my PR", "pre-merge check", or before raising a PR for review.
di_signal: RISK + QUALITY
maturity_required: early
status: approved
---

# Review PR Readiness

## Overview
Runs a structured pre-merge assessment across all four DI signal layers and
produces a signal scorecard, severity-rated findings, a clear
Go / Go with comments / Hold verdict, and a ready-to-paste PR description
with a DI risk band.

This is the capstone skill of the developer workflow. Where `/review-code`
examines code quality in detail, `/review-pr-readiness` asks the higher-order
question: *is this PR safe to merge right now?*

## When to Use
- Before raising a PR for team review
- Before merging a PR that has been reviewed
- When a reviewer wants a structured second opinion
- When the team wants a consistent DI risk band on every PR
- Any time the user says: "is this ready", "should I merge", "pre-merge check",
  "review my PR", "PR assessment"

## Instructions

### Step 1: Resolve the PR
**If MCP is connected (GitHub / ADO Repos):**
- Pull the PR diff, title, description, and linked work item
- Extract: files changed, lines added/removed, existing reviewer comments

**If no MCP:**
- Accept the diff or code paste from the user
- Ask for: linked work item ID, PR title, target branch

Load context:
- `.dev-iq/config.yaml` → maturity tier, language, coverage threshold
- `.dev-iq/telemetry-overlay.md` → signal sources for this client
- `.github/instructions/di-code-standards.instructions.md`
- `.github/instructions/di-security.instructions.md`
- `.github/instructions/di-traceability.instructions.md`

**If no diff can be accessed** (no MCP, no paste, no file path): all four DI signals are UNGRADED — do not proceed to assessment. State the gap and ask the user to provide the code.

### Step 2: INTENT Check
Verify the PR delivers what was asked:

1. Pull the linked work item's acceptance criteria
2. Map each AC to the diff — is it addressed?
3. Check scope: does the diff contain changes beyond the work item?
4. Check traceability: does the PR description reference the work item?

Output one of:
```
INTENT ✅ — All [N] ACs covered. Scope contained.
INTENT 🟡 — [N] of [N] ACs covered. AC[X] not found in diff.
INTENT 🔴 — Work item not linked. ACs cannot be verified.
```

Flag out-of-scope changes as Medium findings — they are not blocking but
should be noted for the reviewer.

### Step 3: DESIGN Check
Verify the change follows established patterns:

- Check for architectural drift (layer violations, pattern deviations)
- Check naming conventions against `di-code-standards.instructions.md`
- Flag any new abstractions or patterns introduced without ADR
- Flag any dependency added without confirmation

Output one of:
```
DESIGN ✅ — Follows established patterns.
DESIGN 🟡 — [finding summary]
DESIGN 🔴 — [critical deviation]
```

### Step 4: QUALITY Check
Assess production-readiness of the change:

- Error handling: all external calls and state mutations protected
- Null safety: no unguarded property access
- Logging: key operations logged
- Test coverage: are test stubs or tests present for the new code?
- No magic numbers, hardcoded strings, or TODOs left uncommitted

Output one of:
```
QUALITY ✅ — Production-ready. Error handling and tests present.
QUALITY 🟡 — [medium finding summary]
QUALITY 🟠 — [high finding summary]
QUALITY 🔴 — [critical finding summary]
```

### Step 5: RISK Check
Assess the risk profile of merging this PR:

- **Blast radius:** which other modules, services, or consumers are affected?
- **Security:** run the security checklist from `di-security.instructions.md`
- **Breaking changes:** public API, interface, or schema changes?
- **New dependencies:** version pinned? license checked? security scan run?
- **Data changes:** migrations present? rollback plan exists?

Output one of:
```
RISK ✅ — Contained change. No security concerns. No breaking changes.
RISK 🟡 — [medium risk summary]
RISK 🟠 — [high risk summary]
RISK 🔴 — [critical risk — always Hold]
```

### Step 6: Build Signal Scorecard
Compile the four signal assessments into a scorecard table.

### Step 7: Issue Verdict
Apply verdict logic:

| Verdict | Condition |
|---------|-----------|
| 🟢 **Go** | All four signals Green — no Critical or High findings, no UNGRADED signals |
| 🟡 **Go with comments** | No Critical findings, Medium or Low only — mergeable, address before or after |
| 🔴 **Hold** | Any Critical finding, two or more High findings, or INTENT gap (AC uncovered) |
| ⬜ **UNGRADED** | Any DI signal layer could not be assessed — data was unavailable |

**UNGRADED rule:** UNGRADED signals produce Hold at Mid+ maturity. At Early maturity: 'Go with comments' with the UNGRADED gap explicitly noted and the developer required to confirm the gap before merging. Never issue a Go verdict when any signal is UNGRADED — absence of data is not evidence of quality.

**Maturity adjustment:**
- **Early:** All verdicts advisory — append coaching note, developer decides
- **Mid:** High findings produce Hold verdict
- **Higher:** Verdict posted directly to PR via MCP; auto-assigns reviewer on 🟡

### Step 8: Verification Story
Before issuing the verdict, confirm:

- [ ] All Critical findings are resolved
- [ ] All High findings are resolved or explicitly deferred with written justification
- [ ] INTENT verified — code addresses all stated ACs
- [ ] No hardcoded secrets or credentials anywhere in the diff
- [ ] Error handling present on all external calls
- [ ] Breaking changes documented in the PR description
- [ ] Dependent PRs or migrations listed

If any item is unchecked and unresolved, the verdict is **Hold** regardless of signal colors.

### Step 9: Generate PR Description
Produce a ready-to-paste PR description:

```markdown
## Summary
[one-line description derived from the work item title]

## Linked Work Item
[AB#XXXX or PROJ-XXX]

## What Changed
[bullet list of key changes — files, classes, behaviour]

## DI Risk Band
| Signal  | Status | Notes |
|---------|--------|-------|
| INTENT  |        |       |
| DESIGN  |        |       |
| QUALITY |        |       |
| RISK    |        |       |

## Checklist
- [ ] All ACs verified against diff
- [ ] Tests added or updated
- [ ] No hardcoded secrets or credentials
- [ ] Breaking changes documented
- [ ] Dependent PRs / migrations listed

@di-review-required
```

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| PR diff or code | GitHub/ADO via MCP, or paste | Yes |
| Work item ID | Linked in PR or user provides | Recommended |
| PR title | From PR or user | Recommended |
| Target branch | From PR or config | Auto-read |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## PR Readiness Assessment — [PR title or number]
DI Signals: RISK + QUALITY
Work Item: [AB#XXXX or PROJ-XXX]
Target Branch: [branch]
Assessed: [date]

---

### INTENT [✅/🟡/🔴]
[Summary — ACs covered, scope, traceability]

### DESIGN [✅/🟡/🔴]
[Summary — pattern adherence, findings]

### QUALITY [✅/🟡/🟠/🔴]
[Summary — production-readiness, findings]

### RISK [✅/🟡/🟠/🔴]
[Summary — blast radius, security, breaking changes]

---

### Findings

**[Severity] Finding 1**
- DI Layer: [layer]
- Location: [file/line]
- Issue: [description]
- Suggestion: [fix]

[repeat for each finding]

---

### DI Signal Scorecard
| Signal  | Status | Notes |
|---------|--------|-------|
| INTENT  |        |       |
| DESIGN  |        |       |
| QUALITY |        |       |
| RISK    |        |       |

### Verdict
[🟢 Go / 🟡 Go with comments / 🔴 Hold]
[One sentence rationale]

---

### PR Description (ready to paste)

## Summary
[derived from work item]

## Linked Work Item
[ID]

## What Changed
[bullet list]

## DI Risk Band
[scorecard table]

## Checklist
- [ ] ACs verified
- [ ] Tests added / updated
- [ ] No hardcoded secrets
- [ ] Breaking changes documented

@di-review-required
```

## Examples

### Example 1: Go with Comments

**User says:**
```
/review-pr-readiness
```
*(PR #142 — Add order notification service, linked to AB#4521)*

**Result:**
```
## PR Readiness Assessment — PR #142
Add order notification service
Work Item: AB#4521 | Target: main | Assessed: 2026-05-26

---

### INTENT ✅
4 of 4 ACs covered in the diff.
No out-of-scope changes detected.
Work item linked in PR description.

### DESIGN 🟡
1 medium finding:
NotificationService directly imports EmailClient — should use
IEmailProvider interface to follow the project's dependency
inversion pattern and improve testability.

### QUALITY 🟠
1 high finding:
notifyOrderShipped has no error handling around the email send call.
Silent failure — caller receives no signal if email fails.

### RISK ✅
No new dependencies introduced.
No schema changes.
Blast radius: NotificationService only — no downstream consumers yet.
No security concerns found.

---

### Findings

**🟠 High — Finding 1**
- DI Layer: QUALITY
- Location: notification.service.ts, notifyOrderShipped()
- Issue: No try/catch around emailService.send() — silent failure on error
- Suggestion: Wrap in try/catch, throw typed NotificationError

**🟡 Medium — Finding 2**
- DI Layer: DESIGN
- Location: notification.service.ts, line 4
- Issue: Direct import of EmailClient instead of IEmailProvider interface
- Suggestion: Inject IEmailProvider — matches di-code-standards pattern

---

### DI Signal Scorecard
| Signal  | Status | Notes |
|---------|--------|-------|
| INTENT  | 🟢     | All 4 ACs covered, scope clean |
| DESIGN  | 🟡     | Interface pattern not followed |
| QUALITY | 🟠     | Missing error handling — high |
| RISK    | 🟢     | Contained, no security concerns |

### Verdict
🟡 Go with comments
One high finding (error handling) should be addressed before merge.
One medium finding (interface) can be addressed as a follow-up.

---

### PR Description (ready to paste)

## Summary
Add email notification service for order status changes (shipped, delivered)

## Linked Work Item
AB#4521

## What Changed
- Added NotificationService with notifyOrderShipped() and notifyOrderDelivered()
- Added IEmailProvider interface
- Added test stubs for both notification methods

## DI Risk Band
| Signal  | Status | Notes |
|---------|--------|-------|
| INTENT  | 🟢     | All 4 ACs covered |
| DESIGN  | 🟡     | Interface injection follow-up noted |
| QUALITY | 🟠     | Error handling to be addressed |
| RISK    | 🟢     | Contained change, no new deps |

## Checklist
- [x] All ACs verified against diff
- [ ] Tests added or updated
- [x] No hardcoded secrets or credentials
- [x] No breaking changes
- [x] No migrations required

@di-review-required
```

---

### Example 2: Hold — Critical Security Issue

```
## PR Readiness Assessment — PR #156
Update user authentication flow
Work Item: AB#4612

### RISK 🔴
Critical finding:
JWT secret hardcoded in auth.service.ts line 12.
This would expose the signing secret in the repository.

### Verdict
🔴 Hold — Critical security issue must be resolved before this PR
can be reviewed. Move JWT secret to environment variable immediately.

@di-review-required
```

---

### Example 3: Clean PR — Go

```
## PR Readiness Assessment — PR #160
Fix null reference in sendWelcomeEmail
Work Item: AB#4633

### INTENT ✅  All 2 ACs covered.
### DESIGN ✅  Follows service + guard utility pattern.
### QUALITY ✅  Error handling present. Test added.
### RISK ✅    Single-function fix. No new deps. No security concerns.

### DI Signal Scorecard
| Signal  | Status | Notes |
|---------|--------|-------|
| INTENT  | 🟢     | Both ACs covered |
| DESIGN  | 🟢     | findOrThrow pattern followed |
| QUALITY | 🟢     | Test added, error handling present |
| RISK    | 🟢     | Single function, no blast radius |

### Verdict
🟢 Go — All signals green. PR is ready to merge.

@di-review-required
```

---

### Example 4: Early Maturity — Coaching Mode

At Early maturity, the verdict is advisory and includes coaching:

```
### Verdict
🟡 Go with comments (Early maturity — advisory)

**DI Coaching Note:** The QUALITY signal flagged missing error handling.
In production systems, every call to an external service (email, payment,
notification) should be wrapped in error handling so that failures are
surfaced explicitly rather than silently swallowed. This is the "fail fast
and loudly" principle — see di-code-standards.instructions.md.
```

## Common Rationalizations

These are the statements that get PR readiness review skipped. Rebut them.

| Rationalization | Reality |
|----------------|---------|
| "The PR is small, it doesn't need a full readiness check" | Small PRs introduce the majority of production bugs. A readiness check that takes 2 minutes is not proportional to PR size — it's proportional to what's at stake if a gap is missed. |
| "My reviewer will catch anything I missed" | Reviewers focus on design and correctness — they are not a substitute for the developer verifying that the PR is complete. Missing test stubs, unset environment variables, and deferred ACs are the developer's responsibility. |
| "We're in a hurry — we'll review it after we merge" | Post-merge reviews address what is already in the main branch. Readiness review is what prevents RISK WEAK signals from shipping — it cannot be done retrospectively. |
| "The build passed — that's the readiness check" | Build success confirms compilation and test runs. Readiness covers ACs, DESIGN signal, security surface, deployment requirements, and risk assessment — none of which a green build verifies. |

## Governance
- Critical findings always produce Hold — no exceptions, regardless of maturity
- Never post a Go verdict on a PR with hardcoded secrets or credentials
- Never post a Go verdict when any DI signal layer is UNGRADED — absence of evidence is not a passing signal; it is uncertainty that must be resolved before merge
- `@di-review-required` on all output — human makes the final merge decision
- At Higher maturity with MCP: verdict is posted to the PR as a comment;
  reviewer is auto-assigned on Go with comments
- PR description template is a starting point — developer should review
  before pasting

## Related Skills
- `/scaffold-feature` — start of the workflow; generate the code structure
- `/review-code` — detailed line-level review during development
- `/blast-radius-estimator` — deeper blast radius analysis for high-risk PRs
- `/review-security` — deeper security review for auth, payments, data handling
- `/create-pull-request` — raise the PR with the DI risk band already filled in
- Assert.IQ `/check-merge` — QE signal assessment to complement this DI assessment