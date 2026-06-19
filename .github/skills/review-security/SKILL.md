---
name: review-security
description: Deep security-focused code review using OWASP Top 10 and DI QUALITY + RISK signals. Use when asked to "security review", "check for vulnerabilities", "is this secure", "auth review", or "review this for security issues".
di_signal: QUALITY + RISK
maturity_required: early
status: approved
---

# Review Security

## Overview
Runs a structured security assessment across the OWASP Top 10 and DI
QUALITY + RISK signal layers. Produces severity-rated findings, a security
signal verdict, and remediation guidance for every issue found.

Critical and High findings always block — no override, no exceptions,
regardless of maturity tier or delivery pressure. This skill is the
security gate in the Dev.IQ developer workflow.

## When to Use
- Before raising a PR for any auth, data handling, or API change
- When a code review surfaces a potential security concern
- When adding new dependencies or changing how credentials are handled
- When building or modifying: authentication, authorization, payments,
  PII storage, external API integrations, file upload/download
- Any time the user says: "security review", "check for vulnerabilities",
  "is this secure", "auth review", "OWASP check", "pentest this"

## Instructions

### Step 1: Resolve the Code
**From IDE selection or paste:**
- Accept the code block directly
- Note the stated purpose (auth handler, API endpoint, data service, etc.)
  to scope checklist coverage

**From file path:**
- Read the file at the specified path
- Infer purpose from file name, imports, and function signatures

Ask for:
- Work item ID (recommended for traceability — not blocking)
- Code purpose if not inferable (e.g. "this is the payment webhook handler")

Load context:
- `.dev-iq/config.yaml` → maturity tier, language
- `.github/instructions/di-security.instructions.md` → client-specific
  security standards and compliance posture

**Grounding guardrail:** Before issuing findings, read the actual file(s) from
the workspace (via file path, IDE selection, or paste). Do not review a verbal
description of code as if it were the code itself. Findings must reference
specific lines or functions observed in the code, not inferred from what code
in that category "typically" looks like.

### Step 2: Run QUALITY Security Checks
Assess code-level vulnerabilities:

**Injection**
- SQL injection: string concatenation in queries, no parameterization
- Command injection: unsanitized input passed to shell/exec calls
- Template injection: user input rendered in template strings
- LDAP / XPath injection where applicable

**Authentication & Authorization**
- Missing authentication check on protected routes
- Missing authorization check (authn ≠ authz — verify both)
- JWT: weak signing algorithm (none/HS256 with public key), missing
  expiry check, secret hardcoded or too short
- Session tokens: not invalidated on logout, not rotated on privilege change
- Password: plaintext storage, weak hashing (MD5/SHA1), no salt

**Sensitive Data Exposure**
- PII or secrets logged (request bodies, error messages, stack traces)
- Sensitive fields returned in API responses unnecessarily
- Stack traces or internal paths exposed to the caller
- Verbose error messages that reveal system internals

**Input Validation**
- Missing or insufficient input validation at system boundaries
- XSS: user input rendered in HTML/JS without encoding
- Path traversal: file paths constructed from user input
- Unvalidated redirects or forwards

**Cryptography**
- Hardcoded secrets, API keys, or passwords in source
- Weak or deprecated algorithms (DES, RC4, MD5, SHA1 for security)
- Insufficient key length
- Predictable random number generation for security-sensitive values

**Error Handling**
- Exceptions caught and silently swallowed — no logging, no rethrow
- Generic catch blocks that mask security-relevant failures
- Unhandled promise rejections in async security paths

### Step 3: Run RISK Security Checks
Assess contextual and structural security concerns:

**Secrets & Credentials**
- Hardcoded secrets anywhere in the diff (API keys, DB passwords,
  signing keys, tokens)
- Secrets committed to `.env` files that are not in `.gitignore`
- Credentials passed as URL parameters or query strings

**API Surface**
- Missing rate limiting on authentication or sensitive endpoints
- Overly permissive CORS (`*` origin on credentialed endpoints)
- Unsafe HTTP methods allowed where not needed (DELETE, PUT on public routes)
- Insecure direct object references (IDOR): ID in URL/body not verified
  against the authenticated user's ownership

**Dependencies**
- New packages introduced — note name and version for CVE check
- Flag if no lock file is present or if the version is unpinned (`^`, `~`, `*`)
- Flag packages with known active CVEs if identifiable from name/version

**CVE citation guardrail:**
Do NOT cite a specific CVE number (e.g. CVE-2021-44228) unless it is:
- Retrieved via an MCP tool call to a CVE database, OR
- Explicitly stated in the user's input, commit message, or linked work item

LLM training data contains CVE information that may be incorrect, misattributed,
or outdated. Citing an invented or misremembered CVE number is worse than not
citing one — it undermines the audit trail and may cause the team to apply the
wrong fix. Instead, describe the vulnerability class:
- ✅ "This version of [package] has a known prototype pollution vulnerability —
     verify against the npm advisory database before acting."
- ❌ "CVE-2019-10744 applies here" (do not write this unless confirmed via tool)

**Data Handling**
- PII stored without encryption at rest
- PII transmitted without TLS
- No retention / deletion policy enforced
- Third-party data sharing not documented

### Step 4: Rate Findings
Assign each finding:

| Severity | Meaning |
|----------|---------|
| 🔴 Critical | Exploitable as written — data breach, auth bypass, RCE possible |
| 🟠 High | Likely exploitable under realistic conditions |
| 🟡 Medium | Security weakness — exploitable with additional preconditions |
| ⚪ Low | Hardening improvement — defense in depth, not an active risk |

Include the OWASP Top 10 category where applicable (e.g. A01:2021 Broken
Access Control, A03:2021 Injection).

### Step 5: Issue Security Verdict

| Verdict | Condition |
|---------|-----------|
| 🔴 Block | Any Critical finding |
| 🟠 High Risk | One or more High findings |
| 🟡 Review | Medium findings only, no Critical or High |
| 🟢 Clear | No findings above Low severity |

**Maturity adjustment:**
- **Early:** High Risk verdict is advisory — append coaching note,
  developer decides. Critical always blocks at every tier.
- **Mid:** High Risk blocks PR verdict. Coaching notes included.
- **Higher:** Verdict posted to PR via MCP. Auto-assigns security
  reviewer on Block or High Risk.

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Code to review | IDE selection, paste, or file path | Yes |
| Code purpose | User states or inferred from file | Recommended |
| Work item ID | User provides or linked PR | Recommended |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |
| Client security standards | `di-security.instructions.md` | Auto-read |

## Output Format

```
## Security Review — [file name or endpoint name]
Work Item: [AB#XXXX or PROJ-XXX, or "none provided"]
Scope: [auth | API | data handling | general]
Assessed: [date]

---

### QUALITY Signal — Code-Level Findings
[findings or "No code-level security issues found"]

### RISK Signal — Contextual Findings
[findings or "No contextual security concerns found"]

---

### Findings

**[Severity] Finding N**
- OWASP: [category, or "N/A"]
- DI Layer: [QUALITY | RISK]
- Location: [file/line or function]
- Issue: [description of the vulnerability]
- Attack vector: [how an attacker would exploit this]
- Remediation: [specific fix with code example where helpful]

[repeat for each finding]

---

### Security Signal Scorecard
| Check Area | Status | Notes |
|------------|--------|-------|
| Injection | | |
| Auth & Authz | | |
| Sensitive Data | | |
| Input Validation | | |
| Cryptography | | |
| Error Handling | | |
| Secrets & Credentials | | |
| API Surface | | |
| Dependencies | | |
| Data Handling | | |

---

### Verdict
[🔴 Block / 🟠 High Risk / 🟡 Review / 🟢 Clear]
[One sentence rationale]

@di-review-required
```

## Examples

### Example 1: Auth Endpoint — Block Verdict

**User says:**
```
/review-security
```
*(Selects `auth.service.ts` — JWT sign + login handler)*

**Result:**

```
## Security Review — auth.service.ts
Work Item: AB#4612
Scope: authentication
Assessed: 2026-05-26

---

### QUALITY Signal — Code-Level Findings

**🔴 Critical — Finding 1**
- OWASP: A02:2021 Cryptographic Failures
- DI Layer: QUALITY
- Location: auth.service.ts, line 12
- Issue: JWT signing secret hardcoded as string literal `"supersecret123"`
- Attack vector: Any developer with repo access (or a leaked git history)
  can forge valid JWTs and impersonate any user including admins
- Remediation: Move to environment variable — `process.env.JWT_SECRET`.
  Require minimum 32-character random value. Rotate immediately if
  this value has ever been committed.

**🟠 High — Finding 2**
- OWASP: A01:2021 Broken Access Control
- DI Layer: QUALITY
- Location: auth.service.ts, getUserData()
- Issue: User ID taken directly from request body — not verified against
  the authenticated session. Any authenticated user can request any
  user's data by supplying a different ID.
- Attack vector: IDOR — attacker changes `userId` in request body to
  access another user's profile, orders, or PII
- Remediation: Derive user ID from the verified JWT claims, not the
  request body. `const userId = req.user.id` (from auth middleware).

### RISK Signal — Contextual Findings

**🟡 Medium — Finding 3**
- OWASP: A09:2021 Security Logging and Monitoring Failures
- DI Layer: RISK
- Location: auth.service.ts, catch block line 48
- Issue: Authentication failures caught and silently swallowed — no log,
  no metric. Failed login attempts are invisible to monitoring.
- Attack vector: Enables undetected brute-force attacks
- Remediation: Log failed auth attempts with timestamp, IP, and username
  (not password). Emit a security event metric.

---

### Security Signal Scorecard
| Check Area | Status | Notes |
|------------|--------|-------|
| Injection | 🟢 | No injection vectors found |
| Auth & Authz | 🔴 | IDOR on getUserData — Critical |
| Sensitive Data | 🟢 | No PII in logs |
| Input Validation | 🟢 | Inputs validated |
| Cryptography | 🔴 | JWT secret hardcoded |
| Error Handling | 🟡 | Failed auth not logged |
| Secrets & Credentials | 🔴 | Hardcoded secret in source |
| API Surface | 🟢 | No CORS or rate-limit concerns |
| Dependencies | 🟢 | No new dependencies |
| Data Handling | 🟢 | No PII storage concerns |

---

### Verdict
🔴 Block — Two Critical findings: hardcoded JWT secret and IDOR vulnerability.
This PR must not be merged until both are resolved.

@di-review-required
```

---

### Example 2: Clean Handler — Clear Verdict

```
## Security Review — orderWebhook.handler.ts
Work Item: AB#4633
Scope: API handler
Assessed: 2026-05-26

### QUALITY Signal — Code-Level Findings
No code-level security issues found.

### RISK Signal — Contextual Findings
No contextual security concerns found.

### Security Signal Scorecard
| Check Area | Status | Notes |
|------------|--------|-------|
| Injection | 🟢 | Parameterized queries used |
| Auth & Authz | 🟢 | HMAC signature verified before processing |
| Sensitive Data | 🟢 | No PII logged |
| Input Validation | 🟢 | Schema validated on entry |
| Cryptography | 🟢 | HMAC-SHA256, key from env |
| Error Handling | 🟢 | Errors logged, not exposed |
| Secrets & Credentials | 🟢 | No hardcoded values |
| API Surface | 🟢 | POST only, idempotency key enforced |
| Dependencies | 🟢 | No new dependencies |
| Data Handling | 🟢 | No PII stored |

### Verdict
🟢 Clear — No security findings above Low severity. Handler is secure
as written.

@di-review-required
```

---

### Example 3: Early Maturity — Coaching Mode

At Early maturity, every High or Critical finding includes an OWASP-grounded
coaching note explaining the attack vector in plain terms:

```
**🔴 Critical — Finding 1**
- OWASP: A02:2021 Cryptographic Failures
- Location: auth.service.ts, line 12
- Issue: JWT signing secret hardcoded as `"supersecret123"`
- Remediation: Move to `process.env.JWT_SECRET`

**DI Security Coaching Note:** A JWT is only as trustworthy as its
signing secret. The secret proves that *your server* issued the token —
if an attacker knows the secret, they can sign their own tokens and
claim to be any user, including admins, without ever logging in.
Hardcoding it in source means anyone with repo access (or access to
git history, a leaked PR, or a public fork) can do this. The fix is
always the same: secrets belong in environment variables, rotated
regularly, and never in version control. See OWASP A02:2021 for the
full class of failures this belongs to.
```

Every Critical or High finding at Early maturity follows this pattern:
finding → remediation → coaching note explaining the real-world attack
and why the principle matters, not just the fix.

## Common Rationalizations

These are the statements that get security findings dismissed. Rebut them.

| Rationalization | Reality |
|----------------|---------|
| "This is an internal tool, security doesn't matter" | Internal tools get compromised. Attackers target the weakest link in the chain. |
| "We'll add security later" | Security retrofitting is 10× harder than building it in. The attack surface is already live. |
| "It's just LLM output, it's only text" | That "text" can be a SQL statement, a script tag, or a shell command. Treat all output as untrusted input. |
| "No one knows this endpoint exists" | Security through obscurity is not security. Crawlers, leaked docs, and disgruntled insiders find hidden endpoints. |
| "The finding is Low severity, not worth fixing" | Low findings cluster. Three Low issues in the same function often compose into a High exploit path. |
| "It passed the SAST scan" | SAST tools miss logic flaws, IDOR, and business-rule violations. Green scanner ≠ secure code. |

## Governance
- Critical findings always block PR verdict — no override at any maturity tier
- High findings block at Mid and Higher maturity — advisory at Early
- Security findings are never downgraded for delivery pressure or timeline
- A security professional should review Critical/High findings before the
  team acts on remediation — `@di-review-required` is mandatory
- Never suppress or omit a finding because the fix seems complex
- Secrets found in code must be treated as compromised immediately —
  rotation is required even after the code is fixed
- **Do not cite specific CVE numbers from LLM training knowledge.** CVE data
  in training is frequently misattributed, version-mismatched, or stale.
  Describe the vulnerability class and flag for verification against a live
  CVE database (nvd.nist.gov, osv.dev, or the package registry advisory page).
  Only cite a CVE when confirmed via MCP tool call or explicit user input.

## Related Skills
- `/code-review` — general line-level review; use for non-security concerns
- `/review-pr-readiness` — security verdict feeds directly into the RISK
  signal of PR readiness; Critical/High here always produces Hold there
- `/blast-radius-estimator` — assess downstream impact of a security fix
- `/review-dependencies` — deeper dependency CVE analysis
- Assert.IQ `/review-security-tests` — verify security test coverage for
  the findings raised here