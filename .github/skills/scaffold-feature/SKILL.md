---
name: scaffold-feature
description: Generates boilerplate code structure from a user story and acceptance criteria. Use when asked to "scaffold this feature", "generate boilerplate", "create code structure", "implement this story", or "set up the files for this ticket".
di_signal: INTENT + DESIGN
maturity_required: early
status: approved
---

# Scaffold Feature

## Overview
Generates a production-ready code scaffold from a user story and acceptance
criteria. Outputs file structure, interfaces, placeholder implementations with
per-AC TODOs, and test stubs — all traced back to the source work item.

The agent does not implement business logic. It creates the skeleton so the
developer can focus on the "what" rather than the "where and how to start."

## When to Use
- Developer receives a new user story and wants a starting structure
- Team wants consistent file/class/function layout across features
- Story has multiple ACs that need to be mapped to discrete code units
- Onboarding a new developer who needs a pattern to follow
- Any time the user says: "scaffold", "boilerplate", "create structure", "set up files for"

## Instructions

### Step 1: Read Intent
Resolve the work item from the provided ID or URL.

**If MCP is connected (ADO or Jira):**
- Pull the work item directly using the configured tracker
- Extract: title, description, acceptance criteria, assigned developer, story points
- Note any linked dependencies or parent epics

**If MCP is not connected:**
- Ask the user to paste the story title, description, and AC list
- Confirm the list before proceeding: "I have [N] acceptance criteria — does this look complete?"

**Flag and stop if:**
- No acceptance criteria exist → "This story has no ACs. Scaffolding without ACs produces untraceable code. Please add ACs to the work item or provide them here before continuing."
- ACs are ambiguous (e.g. "handle errors") → list each ambiguous AC and ask for clarification before generating

### Step 2: Assess Design
Before generating any code, read the design context:

1. Read `.dev-iq/config.yaml` → identify language, framework, package manager
2. Read `.dev-iq/telemetry-overlay.md` → identify architecture style and pattern library path
3. Read `.github/instructions/di-code-standards.instructions.md` → apply naming conventions, file structure rules, and import patterns
4. Read `.github/instructions/di-traceability.instructions.md` → apply traceability header format

Identify:
- How many files are needed (one class per file, or grouped?)
- What interfaces or contracts are required
- Whether a repository, service, controller, or other layer pattern applies
- Any existing similar files in the codebase to use as reference

**Flag before generating:**
- Any new dependency the scaffold would introduce → "This scaffold requires [package]. Confirm before I proceed."
- Any deviation from the established pattern → "The standard pattern for services is X. This story seems to need Y. Shall I follow the standard or adapt?"

### Step 3: Map Acceptance Criteria to Code Units
For each AC:

1. Identify the method, function, or behaviour it maps to
2. Assign it to a file and class
3. Write a one-line TODO capturing the AC text exactly
4. Flag any AC that maps to multiple units (split or consolidate?)

Output this mapping as a brief plan before generating code:
```
AC Mapping Plan:
- AC1 → NotificationService.notifyOrderShipped()
- AC2 → NotificationService.notifyOrderDelivered()
- AC3 → IEmailProvider.send() interface contract
- AC4 → Error handling in both methods
Proceed with this mapping? (yes / adjust)
```
Wait for confirmation before generating code.

### Step 4: Generate the Scaffold
Generate output in this order:

**1. Traceability header (every file)**
```
// @di-trace [WORK_ITEM_ID] — [Story Title]
// @di-review-required
// Scaffolded by Dev.IQ scaffold-feature | [DATE]
```

**2. Interface / contract (if applicable)**
Define the public contract before the implementation.

**3. Placeholder implementation**
- Class and method signatures matching the AC mapping
- Each method body: `throw new Error('Not implemented — AC[N]: [AC text]')`
- One TODO comment per AC, quoting the AC text exactly

**4. Test stub file**
- Mirror the implementation structure
- One empty test block per AC
- Import the implementation file
- No test logic — structure only (full tests belong to Assert.IQ)

**5. DI Signal Assessment**
After generating, provide:
```
## DI Signal Assessment

INTENT  ✅ [N] ACs mapped | ⚠️ [N] gaps flagged
DESIGN  ✅ Pattern followed: [pattern name] | ⚠️ [any deviations]
```

### Step 5: Summarise and Hand Off
Close with:
- List of files generated
- List of TODOs (one per AC)
- Any flagged items requiring developer attention
- Reminder: `@di-review-required` — review before applying to codebase

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Work item ID or URL | ADO/Jira via MCP, or user paste | Yes |
| Acceptance criteria | From work item or user input | Yes |
| Target file path | User specifies or inferred from story title | Recommended |
| Language / framework | `.dev-iq/config.yaml` | Auto-read |
| Architecture style | `.dev-iq/telemetry-overlay.md` | Auto-read |
| Code standards | `di-code-standards.instructions.md` | Auto-read |

## Output Format

```
## Scaffold: [Story Title] — [WORK_ITEM_ID]

### DI Signal Assessment
- INTENT: [N] ACs mapped | [gaps if any]
- DESIGN: [pattern used] | [deviations if any]

### File Structure
[list of files to be created with paths]

### [filename]
```[language]
// @di-trace [WORK_ITEM_ID] — [Story Title]
// @di-review-required
// Scaffolded by Dev.IQ scaffold-feature | [DATE]

[interface or type definitions]

[class/function scaffold with per-AC TODOs]
```

### Test Stubs — [test filename]
```[language]
[test file structure mirroring implementation]
[one empty test block per AC]
```

### TODOs
- [ ] AC1: [exact AC text]
- [ ] AC2: [exact AC text]
...

### Flagged Items
- [Any ambiguities, new dependencies, or pattern deviations]

@di-review-required
```

## Examples

### Example 1: TypeScript Service (ADO via MCP)

**User says:**
```
/scaffold-feature AB#4521
```

**Agent does:**
1. Pulls AB#4521 → "Add email notification for order status change"
2. Finds 4 ACs in ADO
3. Reads config.yaml → TypeScript, existing service pattern under `src/services/`
4. Presents AC mapping plan, waits for confirmation
5. Generates scaffold

**Result:**
```typescript
// @di-trace AB#4521 — Add email notification for order status change
// @di-review-required
// Scaffolded by Dev.IQ scaffold-feature | 2026-05-26

export interface IEmailProvider {
  send(to: string, subject: string, body: string): Promise<void>;
}

export class NotificationService {
  constructor(private readonly emailProvider: IEmailProvider) {}

  // TODO AC1: Send notification when order status changes to SHIPPED
  async notifyOrderShipped(orderId: string, email: string): Promise<void> {
    throw new Error('Not implemented — AC1: Notify customer when order ships');
  }

  // TODO AC2: Send notification when order status changes to DELIVERED
  async notifyOrderDelivered(orderId: string, email: string): Promise<void> {
    throw new Error('Not implemented — AC2: Notify customer when order delivered');
  }

  // TODO AC3: Retry on provider failure (max 3 attempts)
  private async sendWithRetry(
    to: string,
    subject: string,
    body: string,
    retries = 3
  ): Promise<void> {
    throw new Error('Not implemented — AC3: Retry logic on send failure');
  }

  // TODO AC4: Log all notification attempts with orderId and outcome
  private logAttempt(orderId: string, outcome: 'sent' | 'failed'): void {
    throw new Error('Not implemented — AC4: Audit logging for notifications');
  }
}
```

Test stub:
```typescript
// @di-trace AB#4521 — Test stubs only | Full tests: use Assert.IQ
import { NotificationService } from './notification.service';

describe('NotificationService', () => {
  describe('notifyOrderShipped', () => {
    it('should send notification when order status changes to SHIPPED', () => {
      // TODO AC1 — implement with Assert.IQ /generate-automated-unit-test
    });
  });

  describe('notifyOrderDelivered', () => {
    it('should send notification when order status changes to DELIVERED', () => {
      // TODO AC2 — implement with Assert.IQ /generate-automated-unit-test
    });
  });
});
```

---

### Example 2: No MCP — User Pastes Story

**User says:**
```
/scaffold-feature

Story: Validate user address on checkout
ACs:
1. Reject empty address fields with descriptive error
2. Validate postcode format against regex
3. Return structured error object with field-level messages
```

**Agent does:**
1. Confirms AC mapping plan
2. Identifies: AddressValidator class, validateAddress() method, AddressValidationError type
3. Generates scaffold in configured language

---

### Example 3: Ambiguous AC — Agent Stops and Asks

**User says:**
```
/scaffold-feature PROJ-88
```

**Agent pulls story with AC:** "Handle errors gracefully"

**Agent responds:**
```
⚠️ AC3 is ambiguous: "Handle errors gracefully"

This AC cannot be mapped to a specific method without clarification. Please specify:
- Which operation should handle errors? (e.g. the API call, the DB write)
- What does "gracefully" mean here? (e.g. return null, throw typed exception, retry)

I'll proceed with ACs 1, 2, and 4 and leave a flagged TODO for AC3.
```

## Governance
- Every output carries `@di-review-required` — do not apply scaffold to codebase without human review
- Never write files directly — output only; developer applies manually or via paste
- Never introduce a new dependency without explicit confirmation from the developer
- Always link to the work item in the traceability header — if no work item exists, warn before proceeding
- Honor established patterns from `di-code-standards.instructions.md` — flag deviations, never silently bypass
- Test stubs are structure only — direct developer to Assert.IQ `/generate-automated-unit-test` for full test generation
- If operating at Early maturity tier, append a coaching note explaining each design decision made

## Related Skills
- `/review-acceptance-criteria` — review ACs before scaffolding to catch ambiguities early
- `/code-review` — review the completed implementation against the scaffold
- `/review-pr-readiness` — assess the PR once implementation is done
- Assert.IQ `/generate-automated-unit-test` — generate full unit tests from the stubs