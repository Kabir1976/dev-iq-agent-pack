---
applyTo: "**"
---

# DI Traceability — Work Item Linking and Artifact Tracing Rules

Apply when adding or modifying production code tied to a work item, or generating
traceability artifacts. Traceability is not optional — it is the evidence layer that
connects delivery decisions to stated requirements.

## Work Item Reference Format

Every generated code artifact must reference its source work item when one is available.

**Azure DevOps:**
```
// AB#1234
```

**Jira:**
```
// PROJ-123
```

**GitHub Issues:**
```
// #456
```

Place the reference in the file header or immediately above the function/class being added. One reference per work item. When a single artifact spans multiple work items, list each one.

If no work item exists: note the absence in the DI assessment (INTENT layer) but do not block generation. Flag it as a Medium finding — untracked work accumulates as invisible debt.

## What Requires a Traceability Comment

| Artifact | Traceability required |
|----------|----------------------|
| New production function or method | Yes — above the function |
| New production class or module | Yes — at the top of the file |
| Modified business logic in an existing function | Yes — alongside the change |
| Configuration change | Yes — in the config file header or PR description |
| Database migration | Yes — in the migration file header |
| Generated test stubs | Yes — inherited from the work item that triggered the code |
| Documentation | Recommended, not required |
| Pure refactoring (no behavior change) | Recommended — cite the refactoring task if one exists |

## Traceability Matrix Structure

When generating a traceability matrix (via `/generate-traceability-matrix`), produce a table mapping requirements to code to tests:

```markdown
| Work Item | AC | File / Function | Test File / Test Name | Status |
|-----------|----|-----------------|-----------------------|--------|
| AB#1234   | AC1: [description] | src/orders/OrderService.ts: processOrder() | tests/orders/OrderService.test.ts: should process valid order | Covered |
| AB#1234   | AC2: [description] | src/orders/OrderService.ts: cancelOrder() | — | NOT COVERED |
```

**Status values:**
- `Covered` — AC maps to code, and code has a corresponding test
- `Code only` — AC maps to code, but no test found
- `NOT COVERED` — AC not found in code
- `UNGRADED` — insufficient data to assess (test files not locatable, work item unreadable)

Never fabricate coverage. If test files cannot be located, mark `UNGRADED` and state why.

## PR Traceability Requirements

A PR description must contain:
1. The linked work item ID (ADO, Jira, or GitHub Issues)
2. Which ACs are addressed by the changes in this PR
3. Which ACs (if any) are intentionally deferred to a future PR, and why

A PR with no linked work item is a RISK finding at Medium severity (untracked scope). A PR where the diff does not map to the linked work item's ACs is an INTENT finding.

## Traceability in Generated Artifacts

All Dev.IQ skill outputs that produce code or structured artifacts must include:

```
<!-- DI Artifact: [skill-name] | Work Item: [ID or "none"] | Generated: [date] -->
@di-review-required
```

This marker:
- Identifies AI-generated content so reviewers know to verify it
- Links the artifact to its origin work item for audit purposes
- Signals that human review is required before the artifact is used

## What Good Traceability Enables

- **Audit trails:** regulators and auditors can trace a deployed feature back to its approval
- **Regression root cause:** when a defect escapes, traceability shows which AC was not covered
- **Change impact:** before modifying a function, trace it forward to tests and backward to requirements
- **Scope control:** PRs without work item links are invisible to delivery tracking — they cannot be measured, planned, or reported

## What Traceability Is Not

- Not a substitute for a code comment explaining *why* something was done a particular way
- Not required for exploratory or spike branches that will not be merged
- Not a guarantee of quality — a traced artifact that is wrong is still wrong
