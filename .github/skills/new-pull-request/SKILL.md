---
name: new-pull-request
description: Generate a complete pull request description from the current diff, with DI signal assessment and traceability. Use when asked to "create a PR", "write the PR description", "generate PR notes", or "open a pull request".
di_signal: DESIGN + QUALITY + RISK
maturity_required: early
status: approved
---

# New Pull Request

## Overview
Generates a complete, ready-to-paste pull request description from the current
diff and linked work item, including a DI signal summary that surfaces any WEAK
or UNGRADED layers before the PR is opened.

The goal is not just to document the change — it is to give the reviewer
everything they need to assess the PR without reading the code blind: what
changed, why, what was tested, what to watch for in deployment, and where
the signal gaps are.

## When to Use
- When a branch is ready to review and needs a PR description
- When an existing PR description is incomplete and needs to be regenerated
- When the team's PR template requires fields that are tedious to fill out manually
- When a PR description needs a DI signal summary added before requesting review
- Any time the user says: "create a PR", "write the PR description", "generate
  PR notes", "open a pull request", "write the PR body"

## Instructions

### Pre-Flight: Credential Scan
Before any other step, scan the diff for hardcoded secrets using the patterns below.
If any pattern matches: **stop, report as a Critical security finding, and do NOT open the PR.**
The developer must remove the credential, rotate it (treat it as compromised), and re-run this skill.

| Pattern | Regex |
|---------|-------|
| AWS access key | `AKIA[0-9A-Z]{16}` |
| Azure storage key | `AccountKey=[A-Za-z0-9+/=]{88}` |
| GCP OAuth token | `ya29\.[A-Za-z0-9_-]{60,}` |
| GitHub tokens | `(ghp\|gho\|ghs\|ghu\|github_pat)_[A-Za-z0-9_]{36,}` |
| Slack tokens | `xox[abprs]-[0-9A-Za-z-]{10,}` |
| GitLab PAT | `glpat-[A-Za-z0-9_-]{20}` |
| PEM private key | `-----BEGIN (RSA \|EC \|OPENSSH )?PRIVATE KEY-----` |

Additional patterns may be appended via `vcs.credential_patterns_extras` in `.dev-iq/config.yaml` (array of regexes).

### Step 1: Read the Diff
**From git diff:**
- Run `git diff main...HEAD` (or the equivalent base branch) to read all changes
- Identify the categories of change: feature code, tests, configuration,
  documentation, migrations, dependency updates

**Ask for (if not provided):**
- The linked work item ID (ADO, Jira, or GitHub Issues)
- Which ACs from the work item are addressed by this PR
- Whether any ACs are intentionally deferred (and why)
- The target branch (main, develop, release/x.y, etc.)

### Step 2: Read the Work Item (if provided)
- Read the work item title, description, and ACs
- Map the diff to the ACs: which ACs does this PR implement?
- Identify ACs in the work item that are NOT implemented: these are either
  deferred or out of scope — make the distinction explicit

### Step 3: Conduct a Quick Pre-PR DI Signal Check
Run a fast four-layer assessment on the diff before generating the PR description:

**INTENT:** Does the diff implement what the work item requires? Any AC
addressed that is not in the work item (scope creep)? Any work item AC
missing from the diff (scope gap)?

**DESIGN:** Are there obvious layer violations, circular dependencies, or
new patterns introduced without an ADR?

**QUALITY:** Are new public functions covered by test stubs? Are external
calls wrapped in error handling? Any hardcoded secrets or credentials visible?

**RISK:** Are there schema changes (migration included?), breaking API changes
(backward-compatible?), or dependency additions (reviewed?)?

Flag any WEAK or UNGRADED layer in the PR description so reviewers know where
to focus.

### Step 3b: PR Template Merge
Before generating the PR description, check whether the target repository contains a PR template:
- Auto-detect at: `.github/PULL_REQUEST_TEMPLATE.md`, `.azuredevops/pull_request_template.md`,
  `.gitlab/merge_request_templates/*.md`, or `docs/pull_request_template.md`.
- Override the search path via `vcs.pr_template_path` in `.dev-iq/config.yaml`.

**If a template exists:**
1. Populate every existing template section — do not leave placeholder text unfilled.
2. For sections that overlap with DI content (Summary, Testing, Checklist, Risk): embed DI
   content *inside* the template's section rather than duplicating it alongside.
3. DI-specific sections with no template equivalent (Work Item Coverage, DI Signal Summary,
   Deployment Notes): append them after the last template section under `<!-- DI additions -->`.
4. Never remove template checkboxes or required fields. Preserve all checkboxes exactly as
   written, adding check marks only for items the developer has confirmed.
5. Insert the DI content — work item reference, signal table, and `@di-review-required` marker
   — inside the template structure, not appended loosely after it.

**If no template exists:** generate the standalone body defined in Step 4.

### Step 4: Generate the PR Description
Produce a complete markdown PR description:

- **Summary:** What changed and why (2–4 sentences)
- **Work Item + ACs:** Which ACs are addressed, which are deferred
- **Changes by Category:** Grouped list of changes
- **Testing:** How was this tested? (what the developer verified)
- **Deployment Notes:** Any env vars, migrations, feature flags, or runbook
  steps needed
- **Reviewer Checklist:** What the reviewer should specifically check
- **DI Signal Summary:** Layer-by-layer signal state with any WEAK/UNGRADED
  layers called out

At **Early maturity**: include coaching notes in the DI signal summary for
any WEAK or UNGRADED finding.

At **Mid/Higher maturity**: structured output only.

### Step 5: Open the PR via the Correct CLI
Read `vcs.host` from `.dev-iq/config.yaml` to select the appropriate command.

| Host | Detection | CLI command |
|------|-----------|-------------|
| GitHub.com / GitHub Enterprise | `vcs.host: github` | `gh pr create` |
| Azure DevOps | `vcs.host: ado` | `az repos pr create` |
| GitLab | `vcs.host: gitlab` | `glab mr create` |
| Bitbucket | `vcs.host: bitbucket` | `bb pr create` (Bitbucket CLI) or POST to the Bitbucket REST API |
| Other / unset | `vcs.host` not set | Prompt the user for the PR URL and output a paste-ready body |

When the CLI or MCP is unavailable or fails: output the complete PR body as formatted markdown
and include the exact CLI command the developer should run, substituting the actual values for
branch, title, and base.

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Git diff or change description | `git diff`, file paths, or paste | Yes |
| Work item ID | User provides | Recommended |
| ACs addressed | User states or inferred from work item | Recommended |
| Target branch | User states or inferred from git | Auto-inferred |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## PR: [Short, imperative title — 70 chars max]

**Branch:** [feature/branch-name] → [main | develop | release/x.y]
**Work Item:** [AB#XXXX | PROJ-XXX | #456 | none — untracked work]
**Type:** [Feature | Bug Fix | Refactor | Config | Migration | Hotfix]

---

### Summary

[2–4 sentences describing what changed and why. Domain language.
No implementation detail that belongs in a code comment.]

---

### Work Item Coverage

**ACs addressed in this PR:**
- [AC 1]: [brief description of how it was implemented]
- [AC 2]: [brief description]

**ACs deferred to a future PR:**
- [AC 3]: [why deferred and what future PR will address it]

---

### Changes

**Feature code:**
- [file/module] — [what changed and why]

**Tests:**
- [test file] — [what is covered]

**Configuration / Environment:**
- [config change] — [env var, feature flag, migration]

**Dependencies:**
- [package] — [added/updated/removed, why]

---

### Testing

[How was this verified? Be specific:]
- Ran unit tests: [pass/fail/N/A]
- Ran integration tests: [pass/fail/N/A]
- Manually verified: [what was checked in what environment]
- Edge cases tested: [what edge cases were covered]

---

### Deployment Notes

[Anything the person deploying this needs to know:]
- [ ] Environment variable: [NAME] must be set to [description]
- [ ] Migration: `[migration file name]` must run before deploy
- [ ] Feature flag: [flag name] controls [behavior]
- [ ] Runbook: [link or "no runbook required"]

---

### Reviewer Checklist

- [ ] [Specific thing to check — not generic "review the code"]
- [ ] [Specific area of risk to verify]
- [ ] [Known assumption to validate]

---

### DI Signal Summary

| Layer | Signal | Notes |
|-------|--------|-------|
| INTENT | [STRONG/WEAK/UNGRADED] | [finding or "aligned with work item ACs"] |
| DESIGN | [STRONG/WEAK/UNGRADED] | [finding or "no structural issues found"] |
| QUALITY | [STRONG/WEAK/UNGRADED] | [finding or "error handling present, test stubs added"] |
| RISK | [STRONG/WEAK/UNGRADED] | [finding or "no schema changes, no breaking API changes"] |

@di-review-required
```

## Examples

### Example 1: Feature PR with Linked ADO Work Item

**User says:** `/new-pull-request` — branch `feature/wishlist-share`, work item AB#2202

**Result:**

```
## PR: Add wishlist sharing via shareable URL

**Branch:** feature/wishlist-share → main
**Work Item:** AB#2202
**Type:** Feature

---

### Summary

Implements wishlist sharing: authenticated users can generate a shareable URL
for their wishlist that recipients can view without logging in. The shared
view is read-only and the URL expires after 30 days of inactivity.

---

### Work Item Coverage

**ACs addressed:**
- AC 1 (share link generated): ShareableLink.generate() creates a signed URL
  and copies it to the clipboard via the browser Clipboard API.
- AC 2 (recipient read-only view): GET /v1/wishlists/shared/:token resolves
  the token and returns the wishlist in read-only shape with no write endpoints exposed.
- AC 3 (invalid/expired link): Token validation returns 404 with "This list is
  no longer available" for expired or revoked tokens.

**ACs deferred:**
- None. All ACs for AB#2202 are implemented in this PR.

---

### Changes

**Feature code:**
- `src/wishlists/ShareableLink.ts` — new service: generates, stores, and
  validates share tokens (HMAC-signed, 30-day TTL)
- `src/api/routes/sharedWishlist.ts` — new GET /v1/wishlists/shared/:token
  route (public, read-only)
- `src/wishlists/WishlistService.ts` — `shareWishlist()` method added

**Tests:**
- `tests/wishlists/ShareableLink.test.ts` — unit tests for token generation,
  validation, and expiry
- `tests/api/sharedWishlist.test.ts` — integration tests for GET route:
  valid token, expired token, revoked token

**Database:**
- `migrations/20260606_add_wishlist_share_tokens.sql` — new `wishlist_share_tokens`
  table (id, wishlist_id, token_hash, expires_at, revoked_at)

---

### Testing

- Ran unit tests: pass (12 new tests, 0 failures)
- Ran integration tests: pass
- Manually verified in staging: generated a share link, opened in a private
  browser window (logged out), confirmed read-only view renders correctly
- Edge case: expired token tested by setting `expires_at` to a past timestamp
  in the test database — confirmed 404 response

---

### Deployment Notes

- [ ] Migration: `20260606_add_wishlist_share_tokens.sql` must run before deploy
- [ ] No new environment variables required
- [ ] Feature flag: `WISHLIST_SHARING_ENABLED` (existing flag) controls
  the "Share wishlist" button — currently enabled in staging, disabled in prod.
  Enable in prod after smoke test.

---

### Reviewer Checklist

- [ ] Verify token is HMAC-signed with a secret from env, not hardcoded
- [ ] Confirm GET /v1/wishlists/shared/:token returns 404 (not 401) for
  invalid tokens — revealing "unauthorized" leaks the existence of the resource
- [ ] Confirm the share route is excluded from auth middleware
- [ ] Verify migration is reversible (down migration present)

---

### DI Signal Summary

| Layer | Signal | Notes |
|-------|--------|-------|
| INTENT | STRONG | All three ACs implemented and verified |
| DESIGN | STRONG | Token service follows existing service/repository pattern |
| QUALITY | STRONG | Error handling on external calls; test stubs for all new public methods |
| RISK | STRONG | Migration included; new table only (no existing tables modified) |

@di-review-required
```

---

### Example 2: Hotfix PR with No Work Item — INTENT UNGRADED

**User says:** `/new-pull-request` — branch `hotfix/null-payment-crash`, no work item

**Result (DI Signal Summary excerpt):**

```
## PR: Fix null dereference crash in payment status check

**Branch:** hotfix/null-payment-crash → main
**Work Item:** none — untracked work ⚠️
**Type:** Bug Fix

---

[...changes, testing, deployment notes...]

---

### DI Signal Summary

| Layer | Signal | Notes |
|-------|--------|-------|
| INTENT | UNGRADED | No work item linked — the defect is not traceable to a requirement or known issue. Create a bug work item and link it to this PR. |
| DESIGN | STRONG | Fix is localized to null guard in existing function |
| QUALITY | STRONG | Test case for null payment object added |
| RISK | STRONG | No schema changes; single-function change with narrow blast radius |

**Note:** INTENT is UNGRADED because no work item was provided. Untracked
hotfixes cannot be measured, planned, or audited. Create a bug ticket and
update this PR description before merge.

@di-review-required
```

---

### Example 3: PR with Missing Tests — QUALITY WEAK

**DI Signal Summary excerpt:**

```
### DI Signal Summary

| Layer | Signal | Notes |
|-------|--------|-------|
| INTENT | STRONG | Implements AB#3301 ACs 1 and 2 |
| DESIGN | STRONG | No structural issues |
| QUALITY | WEAK | No tests added for StripeWebhookHandler.handleEvent() — new public method with no test stub |
| RISK | STRONG | No breaking changes |

**Reviewer note:** The QUALITY signal is WEAK. The reviewer should verify
that StripeWebhookHandler.handleEvent() has a test stub before approving,
or confirm that a follow-up Assert.IQ test generation task is tracked.

@di-review-required
```

---

## Governance
- INTENT must always reference the work item or explicitly state that no work
  item exists — a PR with no work item reference carries an INTENT UNGRADED
  signal that must be surfaced, not omitted
- ACs deferred to future PRs must be explicitly documented — a PR description
  that implies all ACs are covered when some are not is an INTENT gap
- Reviewer checklists must contain specific, actionable items — "review the
  code for quality" is not a reviewer checklist item
- Deployment notes must be explicit about every migration, environment variable,
  and feature flag change — omitting them is a RISK WEAK finding
- All output carries `@di-review-required` — the PR description is a draft;
  the developer must review it for accuracy before opening the PR
- At Early maturity, every WEAK or UNGRADED DI signal layer includes a coaching
  note explaining what information is missing and how to provide it

## Related Skills
- `/review-pr-readiness` — for a full four-layer PR readiness assessment before
  opening the PR; use before `/new-pull-request` when confidence is low
- `/generate-traceability-matrix` — to verify AC coverage before writing the
  PR description
- `/review-dependencies` — if the PR adds or updates dependencies, run a
  dependency review before generating the PR description
- `/generate-rollback-plan` — if the PR includes a schema migration or breaking
  API change, generate a rollback plan to include in deployment notes
