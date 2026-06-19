---
name: generate-release-notes
description: Generate release notes from git history, merged PRs, and linked work items. Use when asked to "write release notes", "generate a changelog", "what shipped in this release", or "create the release summary".
di_signal: INTENT
maturity_required: early
status: approved
---

# Generate Release Notes

## Overview
Generates structured release notes from git history, merged PR descriptions,
and linked work items — categorized by change type, with INTENT signal applied
to verify that what shipped matches what was planned.

Commits and PRs with no linked work item are flagged as INTENT UNGRADED —
they represent untracked scope that cannot be measured, audited, or attributed
to a sprint. Release notes are not just communication; they are an audit trail.

## When to Use
- After a release candidate is cut and release notes need to be drafted
- When a sprint closes and the team needs a summary of what shipped
- When stakeholders need to know what changed in a version before upgrading
- When preparing a changelog for an API or library version bump
- When a hotfix is shipped and incident postmortems need a change record
- Any time the user says: "write release notes", "generate a changelog",
  "what shipped in this release", "create the release summary", "draft the release"

## Instructions

### Step 1: Determine the Release Range
Ask for (if not provided):
- The starting point: previous release tag (e.g. `v1.4.2`), a branch name,
  or a commit SHA
- The ending point: the current tag, `HEAD`, or the release branch
- The release version number or name

**From git log:**
- Run the equivalent of `git log v1.4.2..HEAD --oneline --merges` to get
  merged PRs and commits in the range
- If PR descriptions are available: read them for categorized change data
- If only commit messages are available: use the commit message text verbatim
  as the basis for the note — do not synthesise, interpret, or expand on it

**Read before generating:**
- Check for an existing `CHANGELOG.md` or `RELEASES.md` in the workspace root.
  Read the most recent entry to confirm the starting version boundary and avoid
  duplicating items from previous releases.

**Hallucination guardrail — uninformative commits:**
If a commit message is uninformative (e.g. "fix", "wip", "update", "misc",
"changes", "stuff"), do NOT synthesise what it might have fixed or changed.
Instead, list it as:
```
- [commit hash] — REQUIRES CLARIFICATION: commit message is uninformative.
  Developer must confirm what this commit contains before release notes are published.
```
Do not guess the content. Do not expand an uninformative message into a
plausible-sounding description. The commit author must clarify.

### Step 2: Group Changes by Category
Categorize each change into one of the following groups:

| Category | What belongs here |
|----------|------------------|
| **Features** | New user-visible capabilities |
| **Bug Fixes** | Corrections to existing behavior |
| **Performance** | Changes that improve speed, memory, or throughput without changing behavior |
| **Breaking Changes** | Changes that require consumer action to upgrade (API changes, schema changes, config changes) |
| **Deprecations** | Features marked for removal in a future release |
| **Security** | CVE fixes, auth improvements, dependency security upgrades |
| **Internal / Maintenance** | Refactoring, dependency updates, CI changes that do not affect the user |

**Breaking Changes must always be in their own section at the top, clearly
labeled, and must include migration notes.**

### Step 3: Map Changes to Work Items
For each change, identify the linked work item (ADO, Jira, GitHub Issues):
- PR description references a work item → link it
- Commit message contains an issue reference → link it
- No work item found → mark as INTENT UNGRADED and flag it

INTENT UNGRADED changes must be listed but clearly marked — they represent
untracked scope. Recommend that the team create a retroactive work item for
accountability.

### Step 4: Identify INTENT Gaps
Compare planned work items against shipped changes:

**Scope delivered but not planned:** changes in the log that have no
corresponding planned work item (INTENT UNGRADED)

**Scope planned but not delivered:** work items marked as in-sprint but
with no corresponding change in the log — either deferred, not yet merged,
or incorrectly planned (INTENT gap)

State both gaps explicitly in the release notes. Do not omit changes because
they are ungated — that would make the release notes inaccurate.

### Step 5: Generate Upgrade Notes
If there are breaking changes or deprecations:
- What action does a consumer need to take before or after upgrading?
- Is there a migration script, command, or documented procedure?
- Is there a fallback or backward-compatible mode?

At **Early maturity**: include a coaching note on the importance of tracking
INTENT UNGRADED commits.

At **Mid/Higher maturity**: structured output only.

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Release range (from tag/commit to tag/commit) | User provides | Yes |
| Version number | User provides | Required |
| Git log or PR list for the range | `git log`, paste, or CI artifact | Yes |
| Planned work item list (optional) | Sprint/milestone data | Optional — enables gap analysis |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
# Release Notes — v[version]
**Release date:** [date]
**Range:** [from tag/commit] → [to tag/commit]

---

## ⚠️ Breaking Changes

> These changes require action before or after upgrading.

- **[Change title]** — [what changed and what action is required]
  Work Item: [AB#XXXX]
  Migration: [what to do]

[If none: "No breaking changes in this release."]

---

## Features

- **[Feature title]** — [1–2 sentences describing the user-visible capability]
  Work Item: [AB#XXXX]

[Repeat per feature]

---

## Bug Fixes

- **[Fix title]** — [what was broken and what was fixed]
  Work Item: [AB#XXXX]

---

## Security

- **[Security improvement]** — [what was addressed]
  Work Item: [AB#XXXX]
  CVE: [include only if a specific CVE number appears in the commit message,
  PR description, or linked work item — never infer or cite a CVE number from
  LLM training knowledge; if uncertain write "CVE reference: REQUIRES VERIFICATION"]

---

## Performance

- **[Performance improvement]** — [what improved and by how much if measurable]
  Work Item: [AB#XXXX]

---

## Deprecations

- **[Deprecated feature]** — [what is deprecated, when it will be removed,
  and what to use instead]
  Work Item: [AB#XXXX]

---

## Internal / Maintenance

- [brief list of infra, dependency, and CI changes — no work item required]

---

## Upgrade Notes

[Step-by-step instructions for upgrading from the previous version.
If no action required: "No upgrade steps required for this release."]

---

## INTENT Assessment

| Status | Count | Notes |
|--------|-------|-------|
| Linked to work item | [N] | Tracked changes |
| INTENT UNGRADED | [N] | No work item found — listed below |
| Planned but not shipped | [N] | Deferred — listed below |

**INTENT UNGRADED commits (shipped with no work item):**
- [commit hash] — [commit message] — recommended action: create retroactive bug/task

**Planned work items not found in this release:**
- [AB#XXXX] — [title] — status: [deferred to vX.Y / status unknown]

---

@di-review-required
```

## Examples

### Example 1: Minor Release with 3 Features and 2 Bug Fixes

**User says:** `/generate-release-notes` — from v1.4.2 to v1.5.0

**Result:**

```
# Release Notes — v1.5.0
**Release date:** 2026-06-06
**Range:** v1.4.2 → v1.5.0

---

## ⚠️ Breaking Changes

No breaking changes in this release.

---

## Features

- **Wishlist sharing** — Users can now generate a shareable link for their
  wishlist that recipients can view without logging in. Links expire after
  30 days of inactivity.
  Work Item: AB#2202

- **Subscription tier display** — The user profile page now shows the active
  subscription tier (Free, Pro, Enterprise) with an upgrade prompt for Free
  tier users.
  Work Item: AB#2401

- **Order delivery ETA** — Order detail pages now display the estimated
  delivery date when available from the shipping integration.
  Work Item: AB#2530

---

## Bug Fixes

- **Payment status not refreshing** — Fixed an issue where the payment status
  on the order page would show "pending" after a successful payment until a
  manual page refresh.
  Work Item: AB#2612

- **Profile image upload failing for PNG files > 4MB** — Resolved a file size
  validation error that was incorrectly rejecting PNG files between 4MB and
  the 10MB allowed maximum.
  Work Item: AB#2688

---

## Internal / Maintenance

- Updated `jsonwebtoken` from 8.5.1 to 9.0.2 (resolves CVE-2022-23539,
  CVE-2022-23541, CVE-2022-23540)
- PostgreSQL connection pool size increased from 10 to 20 (staging and production)
- GitHub Actions CI runner updated to ubuntu-22.04

---

## Upgrade Notes

No upgrade steps required for this release. No schema migrations or environment
variable changes in v1.5.0.

---

## INTENT Assessment

| Status | Count | Notes |
|--------|-------|-------|
| Linked to work item | 5 | All feature and bug fix changes tracked |
| INTENT UNGRADED | 0 | No untracked commits |
| Planned but not shipped | 1 | AB#2719 deferred (see below) |

**Planned work items not found in this release:**
- AB#2719 — "Add CSV export to order history" — status: deferred to v1.5.1
  (dependency on reporting service v2 not yet deployed)

---

@di-review-required
```

---

### Example 2: Release with a Breaking Change — Migration Notes Required

**User says:** `/generate-release-notes` — from v2.0.0 to v2.1.0

**Result (breaking change section):**

```
# Release Notes — v2.1.0

---

## ⚠️ Breaking Changes

> These changes require action before or after upgrading.

- **`legacyId` field removed from GET /orders response** — The `legacyId`
  field has been removed from all order API responses. Consumers that read
  this field will receive `undefined` after upgrading.
  Work Item: AB#4102
  Migration: Remove all references to `legacyId` in consuming services
  before deploying this release. A migration guide is available at
  docs/migrations/v2.1-legacy-id-removal.md.
  Affected consumers: web-client (updated in this release), reporting-service
  (update required before deploying).

---

## Upgrade Notes

1. Before deploying v2.1.0 to any environment:
   - Update `reporting-service` to v1.8.0+ which removes the `legacyId` dependency.
   - Confirm no other internal services read `legacyId` from the order API.
2. Deploy `reporting-service` update first.
3. Deploy this release.
4. Verify GET /orders responses in staging before promoting to production.

---

@di-review-required
```

---

### Example 3: Release with Untracked Commits — INTENT Gaps Noted

**Result (INTENT section excerpt):**

```
## INTENT Assessment

| Status | Count | Notes |
|--------|-------|-------|
| Linked to work item | 8 | Tracked changes |
| INTENT UNGRADED | 3 | No work item found |
| Planned but not shipped | 0 | All planned items shipped |

**INTENT UNGRADED commits (shipped with no work item):**
- a3f8d12 — "fix typo in error message" — minor; create a tech-debt task
- b92cd45 — "increase timeout to 30s" — unknown rationale; create retroactive
  task and document why timeout was increased
- f1a3c78 — "remove debug logging from auth flow" — should be linked to a
  security hygiene task; logging PII in debug mode is a security concern
  regardless of whether it is removed

**Recommended action:** Create retroactive work items for the three untracked
commits before closing the sprint. The timeout change in particular warrants
documentation — undocumented configuration changes accumulate as invisible debt.
```

---

## Governance
- INTENT UNGRADED commits must never be omitted from release notes — they are
  reported even if unpleasant; the team decides how to handle them
- Breaking changes must always appear in their own prominently labeled section
  with migration notes — a breaking change buried in "Internal / Maintenance"
  is an INTENT gap
- Planned work items not found in the release must be listed as deferred, not
  silently omitted — stakeholders must know what did not ship
- All output carries `@di-review-required` — release notes are a draft;
  the team must verify accuracy before publishing
- Never generate a "No breaking changes" statement without having confirmed that
  the change set was checked for API contract changes, schema changes, and
  config changes — state UNGRADED if the check was not performed
- Release notes are a public-facing artifact — do not include internal team
  notes, developer names, or implementation details that belong in commit messages
- **Do not synthesise commit messages.** Use commit text verbatim. If a commit
  message does not describe its change clearly, mark it REQUIRES CLARIFICATION
  and ask the developer to provide the description. A plausible-sounding release
  note generated from a vague commit is worse than an honest "REQUIRES CLARIFICATION"
  because it will be published as fact.
- **Do not cite CVE numbers** from LLM training knowledge. Only include a CVE
  reference when it appears explicitly in the commit message, PR description,
  or linked work item. Fabricated CVE citations undermine audit integrity.

## Related Skills
- `/review-deployment-readiness` — run before cutting a release; if there are
  unresolved findings, they should appear in the release notes as known issues
- `/generate-traceability-matrix` — verify that all shipped work items have
  code and test coverage before generating release notes
- `/blast-radius-estimator` — for releases with breaking changes, the blast
  radius assessment should inform the upgrade notes
- `/generate-rollback-plan` — for releases with breaking changes or schema
  migrations, reference the rollback plan in the deployment notes section
