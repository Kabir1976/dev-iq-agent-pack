---
name: generate-user-stories
description: Convert requirements, feature requests, or stakeholder descriptions into well-formed user stories with acceptance criteria. Use when asked to "write user stories", "break this into stories", "generate ACs", or "turn this into a backlog item".
di_signal: INTENT
maturity_required: early
status: approved
---

# Generate User Stories

## Overview
Converts requirements, feature descriptions, or stakeholder notes into
well-formed user stories using the standard `As a / I want / So that` format,
with acceptance criteria for each story and a shared Definition of Done.

This skill applies the INTENT signal layer before generating: if the
requirement is too ambiguous to write testable ACs, it surfaces the gap and
asks for clarification rather than generating stories that cannot be verified.
An untestable story is not a backlog item — it is deferred scope.

## When to Use
- When a feature request or stakeholder email needs to be structured into
  sprint-ready stories
- When a PRD or design brief needs to be decomposed into deliverable units
- When a work item is too large and needs to be split into testable slices
- When ACs are missing from existing stories and need to be generated
- When a spike or discovery yields requirements that need to be captured
- Any time the user says: "write user stories", "break this down", "generate ACs",
  "turn this into stories", "create backlog items from this", "split this feature"

## Instructions

### Step 1: Gather Requirements Context
**From a work item ID:**
- Read the work item title, description, and any attached notes

**From a feature description or paste:**
- Accept the text directly
- Identify the personas mentioned (or infer them from context)
- Identify the outcomes or goals described

Ask for (if not determinable from the input):
- Primary persona(s) — who is the user?
- The system boundary — what is in scope vs. out of scope?
- Priority or delivery constraint — must-have vs. nice-to-have

Load context:
- `.dev-iq/config.yaml` → maturity tier, tracking system (ADO / Jira / GitHub)
- Any existing stories in the work item for style consistency

### Step 2: Assess INTENT Clarity
Before generating stories, evaluate whether the requirement is grounded enough:

**INTENT is clear enough when:**
- The goal is stated (what outcome the user needs)
- At least one persona is identifiable
- The boundary of the feature is reasonably scoped (not "improve the entire checkout")

**INTENT is too weak to generate when:**
- The requirement contains only technical instructions with no user goal
- The outcome is purely subjective ("make it better", "make it faster")
- Conflicting goals are present with no priority signal

If INTENT is too weak: surface the specific gap, ask the clarifying question,
and wait for an answer before generating. Do not generate stories with placeholder
ACs or "TBD" acceptance criteria.

### Step 3: Generate Stories
For each distinct user goal identified in the requirement:

1. Write the story in standard format:
   `As a [persona], I want [specific action or capability], so that [outcome or benefit].`

2. Keep each story independently deliverable — a story that requires another
   story to make sense is an epic, not a story. Split it.

3. Limit scope: one story = one user capability. If the story requires
   a developer to touch more than two layers of the stack to implement,
   consider splitting.

**Story splitting signals:** technical constraint stories, error handling
stories, and performance stories each belong in their own story unless
trivially small.

### Step 4: Generate Acceptance Criteria
For each story, write ACs using the Gherkin-style format or a numbered list,
depending on the team's established convention (read existing stories first):

**AC quality rules (from `di-foundation.instructions.md`):**
- **Testable** — can be verified by a test or a manual check with a clear pass/fail
- **Specific** — no ambiguous terms: "fast", "easy", "seamless", "intuitive"
  must be replaced with measurable thresholds or observable behaviors
- **Complete** — covers happy path + at least one error case + the most
  important edge case
- **Non-overlapping** — each AC tests one condition; two ACs that test the
  same thing should be merged

**Minimum ACs per story:** happy path + one error case. Stories with only
a happy path AC will be flagged as INTENT WEAK.

### Step 5: Generate Definition of Done
Produce a shared Definition of Done for the story set that covers:
- Code reviewed and approved
- Unit test stubs created (Assert.IQ generates the full tests)
- Traceability comment added (`// AB#XXXX` or `// PROJ-XXX`)
- Work item linked in PR description
- No new High or Critical security findings unresolved

At **Early maturity**: add coaching notes on any AC that is borderline —
explain what makes it testable (or not) and how to improve it.

At **Mid/Higher maturity**: output the structured table only.

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Requirement or feature description | Paste, work item ID, or PRD excerpt | Yes |
| Persona(s) | Stated in requirement or provided by user | Required (ask if missing) |
| Tracking system | `.dev-iq/config.yaml` → `tracking.system` | Auto-read |
| Existing story style | Adjacent work items in the backlog | Optional — used for style consistency |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## User Stories — [Feature Name or Work Item ID]
Source: [work item ID or "requirement description"]
Generated: [date]

---

### INTENT Assessment
[1–2 sentences: is the requirement clear enough to generate testable stories?
If WEAK, state the gap and the clarifying question asked.]

---

### Story 1: [Short title]
**Work Item:** [AB#XXXX | PROJ-XXX | #456 | "none — create new"]

As a [persona],
I want [specific action or capability],
so that [outcome or benefit].

**Acceptance Criteria:**
1. Given [context], when [action], then [observable outcome].
2. Given [context], when [action fails], then [error behavior observed].
3. [Additional AC for edge case if applicable]

---

### Story 2: [Short title]
[same structure]

---

### Definition of Done (all stories)
- [ ] Code reviewed and approved by at least one team member
- [ ] Test stubs created for all new public functions (Assert.IQ generates full tests)
- [ ] Traceability comment added to each changed file (`// [work item ID]`)
- [ ] Work item ID linked in the PR description
- [ ] No new High or Critical security findings unresolved
- [ ] AC verification steps documented or automated

---

### INTENT Signal: [STRONG | WEAK | UNGRADED]
[Summary: did the requirement yield fully testable, well-scoped stories?
Any gaps noted here.]

@di-review-required
```

## Examples

### Example 1: Feature Request → 3 Well-Formed Stories

**User provides:** "We need users to be able to save items to a wishlist and
share it with friends. Also send an email when a shared wishlist is updated."

**Result:**

```
## User Stories — Wishlist Feature
Source: requirement description
Generated: 2026-06-06

---

### INTENT Assessment
STRONG — the requirement identifies two personas (the wishlist owner and the
friend/recipient), two primary capabilities (save + share), and one
notification behavior. Scope is bounded. Generating three stories.

---

### Story 1: Save item to wishlist
**Work Item:** AB#2201 (create)

As a registered shopper,
I want to add a product to my wishlist,
so that I can find it again later without losing my place in browsing.

**Acceptance Criteria:**
1. Given I am logged in and viewing a product, when I click "Add to wishlist",
   then the product appears in my wishlist and a confirmation message is shown.
2. Given the product is already in my wishlist, when I click "Add to wishlist"
   again, then no duplicate is added and the button state reflects "In wishlist".
3. Given I am not logged in, when I click "Add to wishlist", then I am
   prompted to log in before the action completes.

---

### Story 2: Share wishlist with a friend
**Work Item:** AB#2202 (create)

As a registered shopper,
I want to share my wishlist via a link,
so that friends can see what I want without needing an account.

**Acceptance Criteria:**
1. Given I have items in my wishlist, when I click "Share wishlist", then
   a shareable URL is generated and copied to my clipboard.
2. Given a recipient opens the shared URL, then they can view the wishlist
   items without logging in (read-only).
3. Given the share link is expired or invalid, when a recipient opens it,
   then a clear "this list is no longer available" message is shown.

---

### Story 3: Email notification on shared wishlist update
**Work Item:** AB#2203 (create)

As a recipient who has viewed a shared wishlist,
I want to receive an email when the owner adds or removes items,
so that I know the list has changed before purchasing.

**Acceptance Criteria:**
1. Given I have opened a shared wishlist and provided my email, when the
   owner adds or removes an item, then I receive an email within 5 minutes.
2. Given I have opted out of notifications, when the wishlist changes,
   then no email is sent to me.
3. Given the notification email fails to send, then the failure is logged
   and retried once; the owner's wishlist operation is not affected.

---

### Definition of Done (all stories)
- [ ] Code reviewed and approved by at least one team member
- [ ] Test stubs created for all new public functions
- [ ] Traceability comment added (`// AB#2201`, `// AB#2202`, `// AB#2203`)
- [ ] Work item ID linked in each PR description
- [ ] No new High or Critical security findings unresolved
- [ ] Shared URL generation tested for expiry and access control

---

### INTENT Signal: STRONG
All three stories are independently deliverable, have testable ACs covering
happy path and error cases, and map directly to stated requirements.

@di-review-required
```

---

### Example 2: Ambiguous Requirement — INTENT Gap Raised Before Generating

**User provides:** "Improve the dashboard so it's faster and easier to use."

**Result:**

```
## User Stories — Dashboard Improvement
Source: requirement description
Generated: 2026-06-06

---

### INTENT Assessment
WEAK — the requirement cannot produce testable stories as written.
Two gaps identified:

**Gap 1 — "faster":** No threshold defined. "Faster" is not a testable AC.
Clarifying question: What is the specific interaction that is slow, and what
load time (in seconds) is the target? For example: "Dashboard initial load
should complete in under 2 seconds on a standard connection."

**Gap 2 — "easier to use":** No measurable behavior described. "Easier" is
a subjective outcome, not a functional requirement.
Clarifying question: Which specific tasks are users currently struggling to
complete? Is this based on user research, support tickets, or a design change?

Stories will be generated once these questions are answered.

### INTENT Signal: WEAK
@di-review-required
```

---

### Example 3: Early Maturity — Coaching Note on AC Quality

At Early maturity, borderline ACs include a coaching note:

```
**Acceptance Criteria:**
1. Given I am logged in, when I save a wishlist item, then it appears in
   my wishlist. ✓
2. Given the wishlist save fails, then an error is shown. ← borderline

**DI Coaching Note (Early maturity):** AC 2 is borderline — "an error is
shown" is observable but not specific. What error? To whom? Does the system
retry? A stronger AC would read: "Given the save fails, then a toast message
'Could not save item — please try again' is displayed and the item is not
added to the list." The more specific the AC, the cheaper the test is to
write and the harder it is to accidentally break in a future change.
```

---

## Governance
- Stories with only a happy-path AC are flagged as INTENT WEAK — at minimum
  one error case AC is required before a story is considered sprint-ready
- Acceptance criteria must not contain undefined terms: "fast", "seamless",
  "intuitive", "easy" — flag each instance and request a measurable alternative
- Test generation belongs to Assert.IQ — this skill produces story-level test
  stubs only (empty function signatures pointing to ACs, not full test code)
- If the requirement yields more than five stories, ask whether an epic-level
  work item should be created to group them — do not silently generate a large
  flat list
- All output carries `@di-review-required` — stories are drafts for team
  refinement, not final sprint commitments
- Never generate a story for work that was not described in the input — do not
  infer scope beyond what was stated

## Related Skills
- `/review-acceptance-criteria` — after generating stories, validate the ACs
  for completeness and testability before committing to the sprint
- `/identify-dependencies` — run after story generation to surface blockers
  before sprint planning
- `/generate-traceability-matrix` — once code is written, verify all ACs are
  covered by tracing work item → code → tests
- `/review-pr-readiness` — references the ACs generated here when verifying
  that a PR addresses the stated acceptance criteria
