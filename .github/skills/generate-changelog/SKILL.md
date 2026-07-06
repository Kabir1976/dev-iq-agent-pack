---
name: generate-changelog
description: Generate a structured changelog from git log for a release or version range. Use when asked to "generate the changelog", "write the release notes from commits", "what changed since the last release", or "update CHANGELOG.md".
di_signal: INTENT
maturity_required: early
status: approved
---

# Generate Changelog

## Overview

Generates a structured changelog from `git log` for a specified version range,
applying the INTENT signal layer to each commit: does it map to a work item,
and does the change it describes align with what the work item required?

Output follows the [Keep a Changelog](https://keepachangelog.com/) format,
grouped into standard sections (Added, Changed, Fixed, Removed, Security,
Deprecated), with work item references where available. Commits without a
linked work item are flagged as INTENT UNGRADED — they are included in the
output and labeled, not silently omitted.

## When to Use

- Before tagging a release and updating CHANGELOG.md
- When a stakeholder asks "what changed in this version?"
- When generating release notes from a diff or commit range
- When the team's commit history needs to be organized for a sprint review
- Any time the user says: "generate the changelog", "write the release notes
  from commits", "what changed since [version/tag]", "update CHANGELOG.md",
  "summarize this release"

## Instructions

### Step 1: Determine the Version Range

Read the range from one of:
1. **User-specified:** `from v1.2.0 to v1.3.0`, `since last tag`, `HEAD since [date]`
2. **Auto-detect:** run `git tag --sort=-version:refname` to find the last tag;
   range is `[last tag]..HEAD`
3. **Work item milestone:** if a sprint or milestone ID is provided, filter
   commits by date range of the sprint

Ask if the version range is ambiguous and cannot be inferred.

Read the target version number from the user, from a `VERSION` file, or from
`package.json` / `pyproject.toml` / `go.mod` if the version is tracked there.

### Step 2: Read the Git Log

```
git log [from]..[to] --pretty=format:"%H|%s|%b" --no-merges
```

For each commit, extract:
- **Subject line** — the one-line summary
- **Body** — optional multi-line detail
- **Work item reference** — scan for `AB#\d+`, `PROJ-\d+`, `#\d+`,
  `Closes #\d+`, `Fixes #\d+` in both subject and body

If a work item reference exists: note it. If not: the commit is INTENT UNGRADED.

### Step 3: Classify Each Commit

Map each commit to a changelog section using the subject line and conventional
commit prefix where present:

| Prefix / Pattern | Section |
|-----------------|---------|
| `feat:` / `feature:` | Added |
| `fix:` / `bugfix:` | Fixed |
| `refactor:` | Changed |
| `perf:` | Changed |
| `docs:` | Changed (or omit if internal-only) |
| `security:` / `sec:` | Security |
| `deprecated:` | Deprecated |
| `remove:` / `removed:` | Removed |
| `chore:` / `ci:` / `build:` | Internal (included with note) |
| Breaking change marker (`BREAKING CHANGE:` in body) | Breaking Changes (own section, always first) |
| No prefix / no convention | Classify by reading the subject; flag UNGRADED if unclear |

### Step 4: Apply INTENT Assessment

For each commit with a work item reference:
- Fetch the work item title (via MCP if available; otherwise use the reference
  only and note that the title was not verified)
- Confirm the commit subject aligns with the work item — an obvious mismatch
  (e.g., commit says "fix login bug" but work item AB#1234 is "add wishlist sharing")
  is an INTENT finding worth flagging

For commits without a work item reference: mark `(untracked)` in the output.
Do not silently omit untracked commits — they represent invisible scope.

### Step 5: Group and Format

Group entries under Keep a Changelog sections in this order:
1. **Breaking Changes** (if any — always first and prominently marked)
2. **Added**
3. **Changed**
4. **Deprecated**
5. **Removed**
6. **Fixed**
7. **Security**
8. **Internal / Maintenance** (chore, ci, build — include at bottom, briefly)

Within each section: most significant change first (breaking > new API surface >
implementation detail).

**Entry format:**
```
- [What changed and why — user-facing language, not implementation detail] ([AB#1234])
```

Do not write entries from the developer's perspective ("I added X") — write
from the user/consumer's perspective ("Users can now X", "The Y endpoint now Z").

### Step 6: Flag Coverage Gaps

At the end of the output, summarize:
- Total commits in range
- Commits with work item references (INTENT assessable)
- Commits without work item references (INTENT UNGRADED)
- Any INTENT mismatches found

## Inputs Required

| Input | Source | Required |
|-------|--------|----------|
| Version range | User states, git tags, or auto-detected | Required |
| Target version number | User states, VERSION file, or package manifest | Required |
| Git history | `git log` in the repo | Required |
| Work item system | `.dev-iq/config.yaml` → `vcs.work_item_system` | Auto-read |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## Changelog — [version] ([date])

---

### ⚠️ Breaking Changes
[Only present if breaking changes exist — always first]

- [Breaking change description] ([AB#XXXX])

---

### Added
- [New feature or capability — user-facing language] ([AB#XXXX])
- [Another addition] ([untracked] ⚠️)

### Changed
- [Behavior change or improvement] ([AB#XXXX])

### Deprecated
- [What is deprecated and what to use instead] ([AB#XXXX])

### Removed
- [What was removed and migration path] ([AB#XXXX])

### Fixed
- [What was fixed — describe the symptom, not the implementation] ([AB#XXXX])

### Security
- [Security improvement — do not include detail that aids exploitation] ([AB#XXXX])

### Internal / Maintenance
- [Chore, CI, build change — brief] ([AB#XXXX])

---

### INTENT Coverage

| Metric | Count |
|--------|-------|
| Total commits in range | [N] |
| Work-item-linked (INTENT assessable) | [N] |
| Untracked commits (INTENT UNGRADED ⚠️) | [N] |
| INTENT mismatches flagged | [N] |

**INTENT Signal: [STRONG | WEAK | UNGRADED]**

STRONG: all commits linked to work items; subjects align with work item titles
WEAK: untracked commits present, or INTENT mismatches found
UNGRADED: git log not accessible, or version range cannot be determined

@di-review-required
```

## Examples

### Example 1: v0.11.0 Release with Mixed Traceability

```
## Changelog — v0.11.0 (2026-07-05)

---

### Added
- Five new developer-focused skills: `review-observability`, `review-ai-integration`,
  `review-deployment-readiness`, `onboard-codebase`, `blast-radius-estimator` (AB#4401)
- Common Rationalizations tables added to all 27 SKILL.md files for in-context
  guidance on when to invoke each skill (AB#4412)

### Changed
- Four skills renamed to eliminate naming conflicts with Assert.IQ:
  `code-review` → `review-code`, `new-pull-request` → `create-pull-request`,
  `review-acceptance-criteria` → `validate-acceptance-criteria`,
  `generate-traceability-matrix` → `generate-traceability` (AB#4398)

### Removed
- `generate-user-stories` removed — test planning and story generation belong
  to Assert.IQ; use Assert.IQ's `/generate-user-stories` instead (AB#4399)

### Internal / Maintenance
- Bootstrap script updated to sync hooks.json from hooks/ directory (untracked ⚠️)

---

### INTENT Coverage

| Metric | Count |
|--------|-------|
| Total commits in range | 8 |
| Work-item-linked | 7 |
| Untracked | 1 |
| INTENT mismatches | 0 |

**INTENT Signal: WEAK** — 1 untracked commit. Create a work item for the
bootstrap script change and link it retroactively.

@di-review-required
```

---

### Example 2: Breaking Change — Always First

```
## Changelog — v2.0.0 (2026-07-05)

---

### ⚠️ Breaking Changes

- `OrderService.processOrder()` now requires an explicit `currency` parameter.
  Callers omitting `currency` will receive a `VALIDATION_ERROR`. Update all
  call sites before upgrading. (AB#5001)

### Added
- Multi-currency support for all order processing flows (AB#5001)
- ...
```

---

### Example 3: No Conventional Commits — Classification by Reading

```
Commit: "Updated the payment thing to handle edge case"
Work item: none

Classification: Fixed (probable) — subject describes a correction to existing
behavior. Flagged as UNGRADED because the work item is missing and "edge case"
is too vague to confirm the classification.

Entry: - [UNGRADED] Payment processing edge case handling updated (untracked ⚠️)
```

---

## Common Rationalizations

These are the statements that get changelog generation skipped. Rebut them.

| Rationalization | Reality |
|----------------|---------|
| "The git log is the changelog" | Git log is for developers who can interpret commit subjects. A changelog is for everyone who needs to understand what changed and why — in user-facing language, grouped by impact type. |
| "We'll write the changelog before the next release" | The context for what changed and why is freshest at the time of the commit. Generating the changelog at release time requires reconstructing intent from subject lines — which degrades into bullet-point archaeology. |
| "We don't have consistent commit messages, so it won't work" | Inconsistent commit messages produce a lower-confidence changelog with UNGRADED markers — which is still more useful than no changelog. The UNGRADED markers also surface the teams' commit discipline gaps. |
| "No one reads changelogs in internal tools" | Changelogs are most read when something breaks and someone needs to know what changed between the working version and the broken one. They are not read until they are critical. |

## Governance

- Untracked commits (no work item reference) are always included in the output
  and marked `(untracked) ⚠️` — they are never silently omitted
- Breaking changes always appear in their own section at the top — never buried
  in Changed or Fixed regardless of how the commit was classified
- INTENT signal STRONG may only be assigned when all commits have work item
  references and no mismatches were found — partial traceability is WEAK
- Do not use implementation language in changelog entries ("refactored X to use Y");
  use user/consumer language ("X now behaves as Z")
- Security section entries must not include exploitation detail — describe the
  class of issue fixed (e.g., "Fixed IDOR vulnerability in order access") without
  providing a reproduction path
- All output carries `@di-review-required` — the changelog is a draft; the
  developer must verify entries before publishing

## Related Skills

- `/generate-release-notes` — generates stakeholder-facing release notes from
  the same commit range; changelog is the technical record, release notes are
  the communication artifact
- `/review-pr-readiness` — PR descriptions include a "changes by category" section
  that feeds directly into the changelog grouping
- `/generate-traceability` — maps commits to work items and ACs; use alongside
  changelog generation for a full INTENT audit of the release
- `/create-pull-request` — PR descriptions created with this skill include work
  item references that make changelog generation more accurate
