---
name: review-dependencies
description: Review package dependencies for security vulnerabilities, license risk, and outdated versions. Use when asked to "check dependencies", "review packages", "audit dependencies", or "is this package safe to add".
di_signal: RISK
maturity_required: early
status: approved
---

# Review Dependencies

## Overview
Reviews package dependencies for security vulnerabilities, license compatibility,
maintenance status, and pinning hygiene — producing a severity-rated finding per
dependency with recommended actions (pin, replace, accept risk, or block).

A dependency is not just a line in a manifest file — it is a trust decision.
Every package added is code that the team did not write, cannot fully audit,
and must maintain forever until it is explicitly removed. This skill makes
that trust decision explicit.

## When to Use
- When a PR adds, updates, or removes a dependency
- When a lockfile changes and the team wants to understand what changed and why
- When a security advisory references a package the project uses
- When onboarding to a new codebase and assessing the dependency health
- When a package is being upgraded and the team needs to know what changed
- Any time the user says: "check dependencies", "review packages", "is this
  package safe to add", "audit the dependencies", "what CVEs does this package have"

## Instructions

### Step 1: Read the Package Manifest
**From a diff:**
- Accept the diff directly
- Identify which packages were added, updated, or removed

**From a manifest file:**
- Read `package.json`, `requirements.txt`, `pom.xml`, `go.mod`, `Gemfile`,
  `Cargo.toml`, or equivalent
- Focus on new or changed entries unless a full audit is requested

Ask for (if not determinable):
- Whether this is a production dependency or a dev-only dependency (affects severity)
- The package's intended use (helps assess whether a simpler, more trusted
  alternative exists)

Load context:
- `.dev-iq/config.yaml` → `stack.language` for appropriate manifest type
- `.dev-iq/governance.md` → approved license list if configured

### Step 2: Assess Each Dependency Across Four Dimensions

**Security (CVE check)**
Check the package name and version against known CVE databases. Key patterns
to flag:
- Direct dependency with a known published CVE: Critical if the CVE is
  exploitable via this project's usage pattern
- Unpinned version (`^4.0.0`, `~1.2`, `*`) in a security-sensitive package
  (auth, crypto, serialization): flag as High — unpinned means the next
  `npm install` could pull in a vulnerable patch version without notice
- Package with a recently published CVE in any version: flag and note the
  fixed version
- Packages with a history of supply chain attacks (typosquats, dependency
  confusion): flag the naming pattern if suspicious

**CVE citation guardrail:**
Do NOT cite a specific CVE number (e.g. CVE-2021-44228) unless it is:
- Retrieved via an MCP tool call to a CVE or advisory database, OR
- Explicitly stated in the user's input, PR description, or security advisory
  they have provided

LLM training data contains CVE information that is frequently misattributed,
version-mismatched, or stale. Instead, describe the vulnerability class and
direct the team to verify:
- ✅ "This version of [package] has known vulnerabilities — check the npm
     advisory (npmjs.com/advisories) or osv.dev before acting."
- ❌ "CVE-2019-10744 applies here" (do not write this unless confirmed via tool or user input)

**License Compatibility**
Check the package license against the project's license posture:
- MIT, BSD-2, BSD-3, Apache-2.0, ISC: generally safe for commercial use
- LGPL: may require open-sourcing dependent code — flag for legal review
- GPL: copyleft — flag as High risk for closed-source commercial projects
- Unknown or missing license: flag as Medium — do not assume safe
- AGPL: almost always a High flag in commercial SaaS contexts

**Maintenance Status**
- Package with no commits in 24+ months: flag as Medium — abandoned packages
  accumulate unpatched vulnerabilities
- Package with open CVEs and no maintainer response: escalate to High
- Package marked as deprecated by its own maintainer: flag and recommend
  the suggested replacement
- Single-maintainer package in a security-critical role: flag as Medium risk

**Pinning Hygiene**
- Production dependencies: must be pinned to exact versions or a narrow range
- Auth, crypto, and serialization libraries: exact version pin required —
  `bcrypt@5.1.1` not `bcrypt@^5.0.0`
- Dev dependencies: unpinned ranges acceptable
- Lockfile absent: flag as High — the build is not reproducible

### Step 3: Assign Severity Ratings

| Severity | Trigger |
|----------|---------|
| 🔴 Critical | Known exploitable CVE in a direct production dependency |
| 🟠 High | Unpinned version on auth/crypto library; GPL license in commercial project; CVE with known fix not applied |
| 🟡 Medium | Abandoned package (no activity 24+ months); unknown license; deprecated without successor; missing lockfile |
| ⚪ Low | Minor version drift; outdated patch version with no CVE; single-maintainer package in non-critical role |

Critical and High findings block the PR verdict. Medium findings require
review. Low findings are noted.

### Step 4: Produce Recommended Actions
For each finding, one of:
- **Pin version**: change `^4.0.0` to `4.1.2` (the current safe version)
- **Replace package**: swap the package for a maintained, CVE-free alternative
- **Upgrade**: apply the known fix version
- **Accept risk**: document the risk acceptance reason and owner (Low findings only)
- **Block**: do not add this dependency — the risk cannot be mitigated

At **Early maturity**: include a coaching note for each Critical or High finding.

At **Mid/Higher maturity**: structured findings and actions only.

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Package manifest or diff | File path, paste, or git diff | Yes |
| Dependency type (production/dev) | Manifest context or user states | Auto-inferred |
| Approved license list | `.dev-iq/governance.md` | Auto-read if present |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## Dependency Review — [Manifest file or PR reference]
Work Item: [AB#XXXX | PROJ-XXX | #456 | "none provided"]
Assessed: [date]
Scope: [new dependencies only | full manifest]

---

### Summary

| Severity | Count |
|----------|-------|
| 🔴 Critical | [N] |
| 🟠 High | [N] |
| 🟡 Medium | [N] |
| ⚪ Low | [N] |

---

### Findings

**🔴 Critical — [package]@[version]**
- Vulnerability: [describe the vulnerability class, e.g. "prototype pollution",
  "path traversal", "ReDoS" — do NOT cite a CVE number unless confirmed via
  MCP tool or explicit user input]
- Advisory: Verify at npmjs.com/advisories, osv.dev, or nvd.nist.gov
- Affected versions: [range if known from advisory]
- Fixed version: [version if known from advisory]
- Action: Upgrade to [version] before merge

**🟠 High — [package]@[version range]**
- Issue: [unpinned / GPL license / etc.]
- Risk: [description]
- Action: [pin to X.Y.Z | replace with alternative | legal review required]

**🟡 Medium — [package]@[version]**
- Issue: [abandoned / unknown license / deprecated]
- Action: [evaluate replacement | accept risk with documented owner]

**⚪ Low — [package]@[version]**
- Issue: [minor drift / patch behind]
- Action: [update in next maintenance cycle]

---

### Verdict

[Pass — no blocking findings | Review required — Medium findings present |
Block — Critical or High findings must be resolved before merge]

---

### RISK Signal: [STRONG | WEAK | UNGRADED]

@di-review-required
```

## Examples

### Example 1: PR Adding lodash with Unpinned Version

**User provides:** A PR diff adding `"lodash": "^4.0.0"` to `package.json`

**Result:**

```
## Dependency Review — package.json (PR diff)
Work Item: AB#2890
Assessed: 2026-06-06
Scope: new dependencies only

---

### Summary

| Severity | Count |
|----------|-------|
| 🔴 Critical | 0 |
| 🟠 High | 1 |
| 🟡 Medium | 0 |
| ⚪ Low | 0 |

---

### Findings

**🟠 High — lodash@^4.0.0**
- Issue: Version is unpinned (`^4.0.0`). The `^` range permits any `4.x.x`
  patch. Lodash has had multiple CVEs in the 4.x range (prototype pollution:
  CVE-2019-10744, CVE-2020-8203). A future `npm install` could pull in a
  newly published vulnerable patch without any explicit change to the manifest.
- Action: Pin to the current safe version `lodash@4.17.21`. Consider
  whether lodash is needed at all — modern JavaScript (ES2022) provides
  native alternatives for most lodash utilities. If only using 1–3 functions,
  import them individually (`lodash/get`, `lodash/merge`) rather than the
  full bundle.

---

### Verdict
Block. The unpinned version must be pinned to `4.17.21` before merge.
Recommend evaluating whether lodash is required or whether native equivalents
would reduce the dependency surface.

---

### RISK Signal: WEAK

@di-review-required
```

---

### Example 2: Well-Maintained Pinned Dependency — Pass

**User provides:** A PR adding `"zod": "3.22.4"` to `package.json`

**Result:**

```
## Dependency Review — package.json (PR diff)
Work Item: AB#3102
Assessed: 2026-06-06
Scope: new dependencies only

---

### Summary

| Severity | Count |
|----------|-------|
| 🔴 Critical | 0 |
| 🟠 High | 0 |
| 🟡 Medium | 0 |
| ⚪ Low | 0 |

---

### Findings
None. `zod@3.22.4` is:
- Pinned to an exact version
- MIT licensed
- Actively maintained (regular commits, responsive maintainers)
- No known CVEs at the assessed version

---

### Verdict
Pass. No blocking findings.

---

### RISK Signal: STRONG

@di-review-required
```

---

### Example 3: Upgrading a Crypto Library — Specific Checks Applied

**User provides:** A PR upgrading `jsonwebtoken` from `8.5.1` to `9.0.2`

**Result:**

```
## Dependency Review — package.json
Work Item: AB#3890
Assessed: 2026-06-06
Scope: updated dependencies

---

### Summary

| Severity | Count |
|----------|-------|
| 🔴 Critical | 0 |
| 🟠 High | 0 |
| 🟡 Medium | 1 |
| ⚪ Low | 0 |

---

### Findings

**🟡 Medium — jsonwebtoken: 8.5.1 → 9.0.2**
- Security: v8.5.1 has known CVEs (CVE-2022-23539, CVE-2022-23541,
  CVE-2022-23540) related to improper validation. v9.0.2 fixes all three.
  Upgrade is correct and urgently recommended.
- Breaking changes in v9.x: The `secretOrPrivateKey` parameter now throws
  synchronously if the secret is empty rather than passing through. Check
  all call sites for empty-string secret guards. Algorithm `none` is now
  explicitly rejected (it was previously silently accepted in some edge cases).
- Pinning: v9.0.2 is an exact pin. ✓
- License: MIT. ✓
- Rating: Medium (not High) because the CVE is in the installed version being
  removed, not the incoming version.

Action: Confirm all call sites pass a non-empty secret before merging.
Run existing auth tests to verify the v9 behavior changes do not break
expected error handling.

---

### Verdict
Review required. Upgrade is strongly recommended (removes three CVEs) but the
v9 breaking change for empty secrets must be verified before merge.

---

### RISK Signal: WEAK (pending verification of breaking change impact)

@di-review-required
```

---

## Governance
- Critical and High findings always block the PR verdict — no delivery pressure
  or maturity tier overrides this rule
- GPL or AGPL licensed packages added to a commercial closed-source project are
  always a High finding — legal review is required before merge
- Unpinned versions in production auth, crypto, or serialization libraries are
  always High — the argument "patch versions are backward compatible" does not
  apply to security-sensitive packages
- The absence of a CVE record does not mean a package is safe — an unmaintained
  package with no CVE history is still Medium risk because future vulnerabilities
  will not be patched
- All output carries `@di-review-required` — dependency assessments are based on
  publicly available CVE information and may not reflect recently disclosed
  vulnerabilities; the team must verify before relying on the assessment
- Transitive (indirect) dependencies with known CVEs should be noted; Direct
  dependencies with known CVEs must be resolved
- **Do not cite specific CVE numbers from LLM training knowledge.** CVE records
  in training data are frequently misattributed, version-mismatched, or stale.
  Describe the vulnerability class and direct the team to verify at a live
  advisory source (osv.dev, nvd.nist.gov, the package registry advisory page).
  Only cite a CVE number when confirmed via MCP tool call or explicit user input.

## Related Skills
- `/review-security` — dependency review is one layer of the full security review;
  use `/review-security` for a complete OWASP-grounded assessment of a PR
- `/blast-radius-estimator` — if a dependency upgrade changes a shared library
  interface, estimate the blast radius before upgrading
- `/review-deployment-readiness` — unresolved Critical dependency findings block
  the deployment readiness verdict
- `/refactor-code` — if a dependency is identified as replaceable by a native
  alternative or a maintained successor, use refactor-code to make the change
