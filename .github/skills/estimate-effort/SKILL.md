---
name: estimate-effort
description: Estimate story points or t-shirt size for a user story, feature request, or diff. Produces a structured estimate with rationale, uncertainty band, and the specific factors driving complexity. Use when asked to "estimate this", "how big is this story", "story point this", "size this ticket", "how long will this take".
di_signal: INTENT + DESIGN
maturity_required: early
status: approved
---

# Estimate Effort

## Overview

Produces a calibrated effort estimate for a user story, feature request, or
change diff. The estimate is never a bare number — it always includes the
technical factors that drove it, an uncertainty band, and explicit flags for
scope that could not be assessed.

This skill applies two DI layers in sequence:
- **INTENT** — is the scope well-defined enough to estimate? Vague or expanding
  scope is flagged before numbers are produced, not hidden inside a wide range.
- **DESIGN** — what is the technical complexity, blast radius, and dependency
  footprint of the change?

A confident estimate requires both layers STRONG. When either is UNGRADED
(no story, no diff, no codebase context), the output includes the uncertainty
explicitly rather than padding the number to compensate.

## When to Use

- Before a sprint planning session to size a story or ticket
- When a team asks "is this a 3 or an 8?" and needs an evidence-based answer
- When sizing a new feature request for a roadmap conversation
- When reviewing a diff to estimate remaining work or rework cost
- Any time the user says: "estimate this", "how big is this?", "story point
  this", "size this ticket", "t-shirt size", "how long will this take"

## Instructions

### Step 1: Determine estimation unit

Read `.dev-iq/config.yaml` → `estimation.unit`. Default: Fibonacci story points
(`1, 2, 3, 5, 8, 13, 21`). If the config specifies `tshirt`, use
`XS / S / M / L / XL / XXL`. If the user specifies a unit in their request,
use that and note the override.

### Step 2: Gather scope input

Accept one or more of the following:
- **User story or ticket** — title, description, acceptance criteria (paste or
  pull via ADO/Jira MCP if a work item ID is provided)
- **Diff or PR** — staged changes or an open PR diff
- **Feature description** — natural-language description of what needs to be built
- **Work item ID** — fetch via ADO/Jira MCP; read title, description, ACs, and
  linked stories

If none is provided, ask: "What should I estimate? Paste the story, a work item
ID, or describe the feature."

### Step 3: INTENT assessment — is scope estimable?

Before producing a number, evaluate whether the scope is defined enough:

**Scope is estimable when:**
- The deliverable outcome is stated (not just the technical mechanism)
- Acceptance criteria exist, or the feature is bounded enough to infer them
- The system boundary is clear (what changes vs. stays the same)

**Scope is not estimable when:**
- The requirement is open-ended ("improve performance across the board")
- Multiple conflicting goals are described with no priority
- Critical unknowns exist that a spike would need to resolve first

For open-ended or spike-requiring scope: do not produce a number. State the
specific unknown and recommend a time-boxed spike (suggest 1–2 days). Document
the blocker in the INTENT assessment.

### Step 4: DESIGN assessment — technical complexity

Analyse the codebase context to assess implementation complexity:

| Factor | Signals |
|--------|---------|
| **Layers touched** | Read the relevant code paths; count how many distinct architectural layers change (controller, service, repository, schema, API contract) |
| **Blast radius** | Run the mental model of `/blast-radius-estimator` — how many callsites, consumers, or downstream systems are affected? |
| **New vs. existing patterns** | Does the implementation follow an existing pattern, or does it require a new abstraction? New abstractions cost more. |
| **External dependencies** | New third-party integrations, API calls, or MCP servers add uncertainty. |
| **Schema or migration changes** | Any DB schema change multiplies risk — add points. |
| **Test scope** | How many new test stubs are needed? More surface = more work. |
| **Security surface** | Auth, data handling, or API changes require security review; factor in that cost. |

For each factor, assign an effect: **small** (no change to estimate), **medium**
(+1–2 points), or **large** (double the base estimate or escalate to next size).

### Step 5: Produce the estimate

Construct the estimate in this format:

1. **Base estimate** from scope and pattern match (what is the simplest version
   of this story to implement given the existing codebase patterns?)
2. **Complexity modifiers** from Step 4
3. **Uncertainty band**: `±1 point` for well-understood work, `±3 points` for
   work with open design questions, `spike recommended` for unknowns that
   require discovery
4. **Point of confidence**: state what would need to be true for the estimate
   to hold (e.g., "assumes no changes to the auth middleware")

Never round up silently to compensate for uncertainty — make the uncertainty
visible instead.

### Step 6: Flag scope risk

If the story has patterns known to cause scope creep, call them out:
- "Also" stories (two features joined by "and" or "also")
- Stories where the AC list grew after initial writing
- New external integrations with no existing contract
- UI changes where design does not exist yet

## Inputs Required

| Input | Source | Required |
|-------|--------|----------|
| Story, feature description, or diff | Paste, work item ID, or PR | Yes |
| Estimation unit | `.dev-iq/config.yaml` → `estimation.unit` | Auto-read (default: Fibonacci) |
| Codebase context | Adjacent files, existing patterns | Used when available |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## Effort Estimate — [Story title or feature name]
Source: [work item ID / paste / PR #]
Unit: [Fibonacci points | T-shirt]
Generated: [date]

---

### INTENT Assessment
[Is scope estimable? State the outcome, AC coverage, and any blocking unknowns.
If WEAK, stop here and state the spike recommendation.]

INTENT: [STRONG | WEAK | UNGRADED]

---

### DESIGN Assessment

| Factor | Finding | Effect |
|--------|---------|--------|
| Layers touched | [e.g., controller + service + schema] | medium |
| Blast radius | [e.g., 3 downstream consumers identified] | small |
| New pattern required | [yes/no + which one] | large |
| External dependency | [yes/no + which] | medium |
| Schema/migration | [yes/no] | large |
| Test surface | [e.g., 4 new public functions] | small |

DESIGN: [STRONG | WEAK | UNGRADED]

---

### Estimate

**[X points | M t-shirt]** ± [uncertainty band]

**Base:** [Y points] — [reason: follows existing pattern / new service layer / etc.]
**Modifiers applied:** [+Z for schema change, +Z for new external integration]
**Confidence:** [high | medium | low]

**Holds if:**
- [Assumption 1 that must remain true]
- [Assumption 2]

**Scope risk flags:**
- [Any "also" or open-ended scope elements that could expand this]

---

### INTENT Signal: [STRONG | WEAK | UNGRADED]
### DESIGN Signal: [STRONG | WEAK | UNGRADED]

@di-review-required
```

## Governance

- Never produce an estimate without rationale — a bare number is not useful
- If scope is not estimable, say so and recommend a spike rather than padding
  the number to cover uncertainty
- Estimates are advisory inputs to team planning, not commitments — mark with
  `@di-review-required` and let the team refine
- Do not factor in individual velocity, holidays, or HR considerations — those
  are for the team to apply during planning

## Related Skills

- `/review-acceptance-criteria` — run first if ACs are missing or ambiguous;
  this skill requires testable ACs to estimate accurately
- `/identify-dependencies` — run after estimation to surface blockers that
  could invalidate the estimate
- `/blast-radius-estimator` — deeper blast radius analysis when the change
  touches shared infrastructure
- `/review-pr-readiness` — references AC coverage from the story this was
  estimated against
