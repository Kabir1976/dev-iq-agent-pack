---
name: review-acceptance-criteria
description: Review acceptance criteria for completeness, testability, and alignment with the work item. Use when asked to "review ACs", "check acceptance criteria", "are these ACs good", or "is this story sprint-ready".
di_signal: INTENT
maturity_required: early
status: approved
---

# Review Acceptance Criteria

## Overview
Evaluates the acceptance criteria on a work item against a four-dimension
quality rubric — Testable, Specific, Complete, and Consistent — and returns
an AC-by-AC assessment with a gap list and recommended additions.

The goal is not to rewrite the work item but to surface what is missing
before a sprint begins. A story that enters a sprint with untestable or
incomplete ACs will either be over-interpreted by the developer or returned
during code review — both outcomes are more expensive than fixing the AC now.

## When to Use
- Before sprint planning or story point estimation
- During backlog refinement when reviewing work items for readiness
- After generating stories with `/generate-user-stories` to validate quality
- When a PR reviewer raises "this doesn't match the ACs" and the ACs need
  to be reviewed rather than the code
- When a QA engineer reports that a story is untestable as written
- Any time the user says: "review these ACs", "check this story", "are these
  ACs good enough", "is this sprint-ready", "validate this work item"

## Instructions

### Step 1: Read the Work Item and ACs
**From a work item ID:**
- Read the title, description, and acceptance criteria section

**From a paste:**
- Accept the AC list directly
- Note the work item ID if present

Ask for (if not already provided):
- The work item ID for traceability
- The persona and goal of the story (needed to assess completeness)
- Any known edge cases the team agreed to handle (helps detect missing ACs)

### Step 2: Apply the AC Quality Rubric
Assess each AC against four dimensions:

**Testable**
Can this AC be verified by a test or a manual check with a clear pass/fail outcome?
- Pass: a specific, observable behavior is described with a trigger and an outcome
- Fail: the AC describes a feeling, a quality attribute without a threshold, or a
  developer implementation detail rather than a user-visible behavior

**Specific**
Does the AC use precise, unambiguous language?
- Fail triggers: "fast", "quickly", "easy", "intuitive", "seamless", "better",
  "improved", "acceptable", "appropriate", "standard"
- Each of these must be replaced with a measurable threshold or a concrete
  behavior before the AC can be verified

**Complete**
Does the AC set cover the full scope of the story?
- A complete AC set covers: the happy path (what works), at least one error
  case (what fails and how the system responds), and the most important edge
  case (boundary, empty state, concurrent access, etc.)
- Missing error cases are the most common gap — flag them explicitly

**Consistent**
Does each AC test exactly one condition, and does the set as a whole avoid
overlap between ACs?
- Two ACs that test the same condition under different names: merge them
- An AC that bundles two conditions in one statement: split it
- ACs that contradict each other (pass/fail for the same trigger): flag immediately

### Step 3: Rate Each AC
Assign a rating to each AC:

| Rating | Meaning |
|--------|---------|
| **Pass** | Meets all four dimensions — testable, specific, complete, consistent |
| **Weak** | Meets most dimensions but has one identified gap (typically specificity) |
| **Fail** | Cannot be verified as written — missing observable outcome, undefined term, or contradicts another AC |

A story is sprint-ready when: all ACs are Pass or Weak, all Weak ACs have
a clear recommended fix, and the set covers at least happy path + one error case.

### Step 4: Identify Missing ACs
After assessing existing ACs, check for gaps:
- Is there at least one error-case AC?
- Is there an AC for the most likely edge case (empty state, max input, timeout)?
- Are all personas mentioned in the story title covered?
- If the story involves an external integration, is there an AC for integration failure?

List each missing AC as a recommended addition with a draft AC text.

At **Early maturity**: include a coaching note for each Fail or missing AC,
explaining the production consequence if it goes unaddressed.

At **Mid/Higher maturity**: produce the assessment table and gap list only.

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Acceptance criteria | Work item ID, paste, or user description | Yes |
| Story persona and goal | Work item title/description | Required — ask if missing |
| Work item ID | User provides | Recommended |
| Known edge cases | User provides or inferred | Optional |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## AC Review — [Work Item ID or Story Title]
Work Item: [AB#XXXX | PROJ-XXX | #456 | "none provided"]
Assessed: [date]

---

### AC Assessment

| # | Acceptance Criterion | Testable | Specific | Complete | Consistent | Rating |
|---|---------------------|----------|----------|----------|------------|--------|
| 1 | [AC text] | ✓ | ✓ | ✓ | ✓ | Pass |
| 2 | [AC text] | ✓ | ✗ | ✓ | ✓ | Weak |
| 3 | [AC text] | ✗ | ✗ | — | — | Fail |

---

### Findings

**AC #2 — Weak (Specificity)**
- Issue: [what term is undefined or unmeasurable]
- Recommended fix: [rewritten AC text]

**AC #3 — Fail (Not Testable)**
- Issue: [why it cannot be verified]
- Recommended fix: [rewritten AC text]

---

### Missing ACs

**Missing: Error case for [trigger]**
- Why it matters: [consequence if this case is not handled and tested]
- Recommended AC: Given [context], when [error condition], then [behavior].

---

### Sprint-Readiness Verdict
[Ready | Not Ready — [reason]]

If not ready: [list of blockers — must be addressed before sprint commitment]
If ready: [brief confirmation + any advisory notes]

---

### INTENT Signal: [STRONG | WEAK | UNGRADED]
UNGRADED when: the work item cannot be accessed, no ACs were provided, or the story scope is undefined — not enough information to assess completeness.

@di-review-required
```

## Examples

### Example 1: Well-Formed ACs — All Pass

**User provides:** ACs for AB#1840 — "User can reset their password"

```
1. Given I request a password reset, then I receive an email within 2 minutes.
2. Given I click the reset link, when it is less than 30 minutes old, then I can set a new password.
3. Given I click the reset link, when it is more than 30 minutes old, then I see "This link has expired. Request a new one."
4. Given I have already used a reset link, when I click it again, then I see "This link has already been used."
5. Given I set a new password, when it is fewer than 8 characters, then the form shows "Password must be at least 8 characters."
```

**Result:**

```
## AC Review — AB#1840: User can reset their password
Work Item: AB#1840
Assessed: 2026-06-06

---

### AC Assessment

| # | Acceptance Criterion | Testable | Specific | Complete | Consistent | Rating |
|---|---------------------|----------|----------|----------|------------|--------|
| 1 | Email received within 2 minutes | ✓ | ✓ | ✓ | ✓ | Pass |
| 2 | Valid link allows password reset | ✓ | ✓ | ✓ | ✓ | Pass |
| 3 | Expired link shows error message | ✓ | ✓ | ✓ | ✓ | Pass |
| 4 | Already-used link shows error | ✓ | ✓ | ✓ | ✓ | Pass |
| 5 | Short password rejected with message | ✓ | ✓ | ✓ | ✓ | Pass |

---

### Missing ACs
None identified. Set covers happy path, expiry, reuse, and validation error.

Advisory: Consider adding an AC for what happens when the email address is not
found in the system (prevents username enumeration — users should see the same
"check your email" message regardless of whether the address exists).

---

### Sprint-Readiness Verdict
Ready. All five ACs are testable, specific, and cover the key error cases.

---

### INTENT Signal: STRONG

@di-review-required
```

---

### Example 2: ACs with Undefined Terms and Missing Error Case

**User provides:** ACs for AB#2015 — "User can search for products"

```
1. The search results should load quickly.
2. Users should see relevant results.
3. The search should handle special characters gracefully.
```

**Result:**

```
## AC Review — AB#2015: User can search for products
Work Item: AB#2015
Assessed: 2026-06-06

---

### AC Assessment

| # | Acceptance Criterion | Testable | Specific | Complete | Consistent | Rating |
|---|---------------------|----------|----------|----------|------------|--------|
| 1 | Results should load quickly | ✓ | ✗ | ✓ | ✓ | Weak |
| 2 | Users should see relevant results | ✗ | ✗ | — | — | Fail |
| 3 | Handle special characters gracefully | ✓ | ✗ | ✗ | ✓ | Weak |

---

### Findings

**AC #1 — Weak (Specificity)**
- Issue: "Quickly" is not measurable. No threshold is defined.
- Recommended fix: "Given I submit a search query, when results are returned,
  then the results page renders within 1.5 seconds for queries returning up
  to 100 results on a standard connection."

**AC #2 — Fail (Not Testable)**
- Issue: "Relevant results" cannot be verified — no ranking criterion, no
  expected output for a given input, no observable pass condition.
- Recommended fix: "Given I search for 'blue running shoes', then the first
  page of results contains only products in the Footwear category, ordered
  by relevance score descending."

**AC #3 — Weak (Specificity + missing error behavior)**
- Issue: "Gracefully" is undefined. No specific behavior described.
- Recommended fix: "Given I enter a search query containing special characters
  (e.g. `<script>`, `&`, `%`), then the characters are sanitized before the
  query executes and results are displayed without an error."

---

### Missing ACs

**Missing: No results case**
- Why it matters: if zero results return with no message, users assume the page broke.
- Recommended AC: Given I search for a term with no matching products, then I see
  "No results found for '[term]'. Try a different search."

**Missing: Empty query submitted**
- Recommended AC: Given I submit a search with an empty query, then the search
  does not execute and the input shows "Enter a search term."

---

### Sprint-Readiness Verdict
Not Ready. AC #2 cannot be verified as written and must be rewritten before
sprint commitment. ACs #1 and #3 require specificity fixes.

---

### INTENT Signal: WEAK

@di-review-required
```

---

### Example 3: Early Maturity — Coaching Note on Missing Error Case

```
### Missing ACs

**Missing: Error case for payment gateway timeout**
- Why it matters: the story covers the checkout happy path but has no AC
  for what happens when the payment gateway doesn't respond.
- Recommended AC: Given I submit payment and the gateway does not respond within
  10 seconds, then I see "Payment could not be processed. Please try again." and
  my cart is preserved.

**DI Coaching Note (Early maturity):** Missing error-case ACs are one of the most
common sources of production incidents. When the developer has no AC for "what
happens if the payment gateway times out", they will either not handle it (the
user sees a blank screen), or handle it inconsistently with the rest of the system.
An error-case AC makes the expected behavior explicit and gives the developer and
QA engineer the same target. Rule of thumb: for every external call in the happy-path
story, add one AC for "what if it fails."
```

---

## Governance
- STRONG may only be assigned when all ACs are rated Pass and the set covers at
  least happy path plus one error case — a story with only happy-path ACs is
  INTENT WEAK regardless of how well those ACs are written
- Undefined terms ("fast", "easy", "seamless", "graceful") are always flagged —
  the AC must be rewritten with a measurable threshold or observable behavior
  before the story is sprint-ready
- ACs must describe user-visible or system-observable behavior, not implementation
  details — an AC that says "the function must return a 200 status" tests the wrong
  layer; the AC should describe what the user sees or the system state that results
- All output carries `@di-review-required` — the assessment is a draft for team
  refinement, not a final sprint commitment
- At Early maturity, every Fail and every missing AC includes a coaching note
  explaining the production consequence, not just the recommended fix
- Never rewrite ACs without presenting the assessment first — the team owns the ACs
  and must approve any changes
- INTENT UNGRADED is distinct from INTENT WEAK — UNGRADED means there is insufficient data to assess; WEAK means the data exists but reveals a gap; UNGRADED produces a Not Ready verdict and blocks sprint commitment

## Related Skills
- `/generate-user-stories` — use to generate the initial stories, then run this
  skill to validate them before sprint commitment
- `/generate-traceability-matrix` — after implementation, verify that all ACs
  reviewed here are covered by code and tests
- `/review-pr-readiness` — references reviewed ACs when verifying that a PR
  addresses the stated acceptance criteria before merge
- `/explain-code` — if existing code needs to be checked against its original ACs,
  explain what the code actually does before comparing to the ACs
