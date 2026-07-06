---
name: review-test-coverage
description: Map acceptance criteria to test stubs in a PR or module and surface coverage gaps. Use when asked to "check test coverage", "are the ACs covered by tests", "what's missing from our tests", or "coverage review". Produces test stubs only — full test generation belongs to Assert.IQ.
di_signal: QUALITY
maturity_required: early
status: approved
---

# Review Test Coverage

## Overview

Maps acceptance criteria and new public functions to test stubs in the current
PR or module, and surfaces gaps where ACs are implemented but not verified.
The output is a structured QUALITY signal assessment — a coverage matrix that
shows what is covered, what has a stub but no implementation, and what is not
covered at all.

This skill produces **test stubs only** — empty function signatures with a
comment describing the scenario to cover. Full test generation (implemented
tests, mocks, fixtures) belongs to Assert.IQ. The boundary is deliberate:
Dev.IQ assesses coverage gaps and provides the scaffold; Assert.IQ fills it.

## When to Use

- Before opening a PR to verify that new ACs have corresponding test stubs
- When reviewing a PR that claims to be "tested" and you want a structured
  coverage map
- When a module has grown and you suspect test coverage has drifted from the ACs
- When estimating Assert.IQ test generation scope — this review produces the
  input list
- Any time the user says: "check test coverage", "are the ACs covered", "what
  tests are missing", "coverage review", "do we have tests for this"

## Instructions

### Step 1: Gather Inputs

**ACs — read from one or more of:**
- Linked work item (ADO, Jira, GitHub Issues) — fetch via MCP if ID is provided
- PR description (ACs addressed section)
- User-provided AC list

**Code under review — read from one or more of:**
- Git diff (`git diff main...HEAD`)
- Specified file or module path
- User-provided code paste

If neither ACs nor code are provided: ask for both before proceeding. Coverage
cannot be assessed without a definition of what should be covered.

### Step 2: Identify What Must Be Covered

From the diff or module, extract every **new public function or method** —
these are coverage obligations independent of the ACs.

From the ACs, extract every **verifiable acceptance criterion** — statements
that describe observable system behavior that can be confirmed by a test.

Non-testable ACs (performance targets, UX statements, documentation requirements)
are noted as `N/A — not unit-testable` in the matrix, not flagged as gaps.

### Step 3: Locate Existing Test Coverage

Search for test files adjacent to the changed code:
- Common patterns: `*.test.ts`, `*.spec.ts`, `*_test.go`, `test_*.py`, `*Test.java`
- Test directories: `tests/`, `__tests__/`, `spec/`
- Load `.dev-iq/config.yaml` → `stack.test_pattern` if configured

For each AC and each new public function: determine whether a matching test
or test stub exists.

**Matching criteria:**
- A test is considered to cover an AC if the test description references the
  AC behavior (exact match not required — behavioral equivalence is sufficient)
- A stub is a test function body that is empty or contains only a comment —
  it counts as `Stub present` in the matrix, not `Covered`

Mark UNGRADED (not "not covered") when test files cannot be located — the
absence of a visible test file doesn't prove no test exists.

### Step 4: Produce the Coverage Matrix

One row per AC, one row per new public function without an AC.

Status values:

| Status | Meaning |
|--------|---------|
| `Covered` | Test exists and verifies the behavior described |
| `Stub present` | Test function exists but body is empty or comment-only |
| `Not covered` | No test or stub found |
| `N/A` | Behavior is not unit-testable (UI, performance, UX) |
| `UNGRADED` | Test files not locatable — assessment incomplete |

### Step 5: Generate Missing Test Stubs

For every `Not covered` AC or public function: produce a test stub.

```
// TEST STUB — [work item ID or "coverage review"]
// Scenario: [description of what to verify]
// Covers: [AC number or function name]
```

Stubs are output in the review — they are not written to the codebase. The
developer applies them; Assert.IQ implements them.

At **Early maturity**: include a coaching note for each `Not covered` gap
explaining the production risk of shipping an AC with no test.

At **Mid/Higher maturity**: structured output only.

## Inputs Required

| Input | Source | Required |
|-------|--------|----------|
| Acceptance criteria | Work item ID, PR description, or paste | Yes |
| Code diff or module | Git diff, file path, or paste | Yes |
| Test file location pattern | `.dev-iq/config.yaml` or auto-detected | Auto-detect |
| Work item ID | User provides | Recommended |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## Test Coverage Review — [PR title / work item / module]
Work Item: [AB#XXXX | PROJ-XXX | #456 | "none provided"]
ACs assessed: [N]
New public functions: [N]
Assessed: [date]

---

### Coverage Matrix

| Item | Type | Test / Stub | Status |
|------|------|-------------|--------|
| AC 1: [description] | Acceptance Criterion | [test file: line or "none"] | Covered |
| AC 2: [description] | Acceptance Criterion | [none] | Not covered |
| AC 3: [description] | Acceptance Criterion | [test file: stub] | Stub present |
| [functionName()] | New public function | [none] | Not covered |
| AC 4: [UX requirement] | Acceptance Criterion | — | N/A |

---

### Missing Test Stubs

[For every Not covered item:]

```[language]
// TEST STUB — [work item ID]
// Scenario: [description]
// Covers: [AC N or functionName()]
[empty test function signature]
```

---

### QUALITY Signal

| Dimension | Status |
|-----------|--------|
| AC coverage | [N/N ACs covered or stubbed] |
| Public function coverage | [N/N new functions covered or stubbed] |
| Test file locatable | [Yes / Partial / No → UNGRADED] |

**QUALITY Signal: [STRONG | WEAK | UNGRADED]**

STRONG: all ACs and public functions have at least a stub
WEAK: one or more ACs or public functions have no test and no stub
UNGRADED: test files could not be located — state the reason

@di-review-required
```

## Examples

### Example 1: Wishlist Sharing Feature — 2 Gaps Found

**Work item:** AB#2202, 3 ACs
**Diff:** `ShareableLink.ts` (2 new public methods), `sharedWishlist.ts` (1 route handler)

**Result:**

```
## Test Coverage Review — feature/wishlist-share
Work Item: AB#2202
ACs assessed: 3
New public functions: 2
Assessed: 2026-07-05

---

### Coverage Matrix

| Item | Type | Test / Stub | Status |
|------|------|-------------|--------|
| AC 1: Share link generated and copied | Acceptance Criterion | tests/ShareableLink.test.ts: L12 | Covered |
| AC 2: Recipient read-only view | Acceptance Criterion | tests/sharedWishlist.test.ts: L8 | Covered |
| AC 3: Invalid/expired link returns 404 | Acceptance Criterion | none | Not covered |
| ShareableLink.generate() | New public function | tests/ShareableLink.test.ts: L12 | Covered |
| ShareableLink.revoke() | New public function | none | Not covered |

---

### Missing Test Stubs

```typescript
// TEST STUB — AB#2202
// Scenario: GET /v1/wishlists/shared/:token with expired token
//           should return 404, not 401 or 200
// Covers: AC 3
it('returns 404 for expired share token', () => {})

// TEST STUB — AB#2202
// Scenario: ShareableLink.revoke() should mark token as revoked
//           and subsequent validation should fail
// Covers: ShareableLink.revoke()
it('revoke() marks token invalid for future validation', () => {})
```

---

### QUALITY Signal

| Dimension | Status |
|-----------|--------|
| AC coverage | 2/3 ACs covered |
| Public function coverage | 1/2 functions covered |
| Test file locatable | Yes |

**QUALITY Signal: WEAK** — 2 gaps must be resolved (AC 3, revoke()).

@di-review-required
```

---

### Example 2: All ACs Covered — STRONG Signal

```
### Coverage Matrix

| Item | Type | Test / Stub | Status |
|------|------|-------------|--------|
| AC 1: User can update profile | Acceptance Criterion | tests/UserProfile.test.ts: L14 | Covered |
| AC 2: Email field is immutable | Acceptance Criterion | tests/UserProfile.test.ts: L38 | Covered |
| updateProfile() | New public function | tests/UserProfile.test.ts: L14 | Covered |

QUALITY Signal: STRONG — all ACs and public functions have test coverage.
```

---

### Example 3: Test Files Not Locatable — UNGRADED

```
QUALITY Signal: UNGRADED

Test files could not be located for this module. Searched:
- tests/payments/ — not found
- src/payments/__tests__/ — not found
- *.test.ts adjacent to PaymentService.ts — not found

Resolution: provide the test file path via `.dev-iq/config.yaml → stack.test_pattern`,
or confirm that no tests exist (which would make this WEAK, not UNGRADED).
```

---

## Common Rationalizations

These are the statements that get test coverage review skipped. Rebut them.

| Rationalization | Reality |
|----------------|---------|
| "Coverage percentage is 80%, we're good" | Coverage percentage measures lines executed, not behaviors verified. An 80% coverage number is consistent with zero tests for the ACs in this PR if other files are well-covered. |
| "The developer said they tested it" | Manual testing and automated test stubs are different claims. A manual test leaves no record that future developers can run. A test stub is the minimum record that makes the AC verifiable by the next person. |
| "Assert.IQ will generate the tests later" | Assert.IQ generates tests from stubs. Without stubs, there is nothing for Assert.IQ to build from — and "later" becomes "never" as soon as the next sprint starts. |
| "The feature is too complex to test right now" | Complexity is an argument for more tests, not fewer. Complex features have more failure modes. The coverage review surfaces which behaviors are unprotected — that's the input to a test plan, not an argument to skip it. |

## Governance

- This skill produces test stubs only — never generates implemented test code;
  that boundary belongs to Assert.IQ
- STRONG may only be assigned when every AC and every new public function has
  at least a stub present — `Not covered` anywhere produces WEAK
- UNGRADED is appropriate when test file location is unclear — do not assume
  "no tests found" means "no tests exist"
- Coverage matrix must not be fabricated — if an AC cannot be mapped to a test,
  the status is `Not covered` or `UNGRADED`, never assumed `Covered`
- At Early maturity, every `Not covered` gap includes a coaching note on the
  production risk of an unverified AC
- Never assess coverage based on line coverage metrics alone — the matrix must
  map ACs to specific test behaviors, not file-level percentage numbers

## Related Skills

- `/validate-acceptance-criteria` — run first to verify ACs are testable before
  assessing whether they have tests; untestable ACs produce N/A rows, not gaps
- `/review-pr-readiness` — includes a QUALITY signal check on test stub coverage
  as part of the full four-layer PR readiness assessment
- Assert.IQ `/generate-tests` — implements the stubs surfaced by this review;
  the coverage matrix is the direct input to Assert.IQ test generation
- `/generate-traceability` — produces the full traceability matrix mapping
  work items → code → tests; this review feeds the test column of that matrix
