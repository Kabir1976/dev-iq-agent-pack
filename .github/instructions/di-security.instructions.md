---
applyTo: "**"
---

# DI Security — Security Review and Generation Rules

Apply when reviewing code for security issues, generating auth or data handling
code, or assessing RISK signal on any PR. This file operationalizes the OWASP
Top 10 within the DI signal model.

## Security Finding Severity

| Severity | Definition | Verdict impact |
|----------|-----------|----------------|
| 🔴 Critical | Exploitable as written — auth bypass, RCE, data breach possible | Always blocks PR verdict at every maturity tier |
| 🟠 High | Likely exploitable under realistic conditions | Blocks at Mid+ maturity; advisory at Early |
| 🟡 Medium | Security weakness — exploitable with additional preconditions | Review required; does not block |
| ⚪ Low | Defense-in-depth improvement — not an active risk | Note only |

**Non-negotiable:** Critical and High findings always block the PR verdict. No delivery pressure, maturity tier, or exception overrides this.

## QUALITY Signal — Code-Level Security Checks

### A01 — Broken Access Control
- Every protected route or resource must check **both** authentication (who are you?) and authorization (are you allowed?).
- User identity must be derived from the verified session token or JWT claims — never from the request body or URL parameter.
- Object-level access: verify that the authenticated user owns the requested resource before returning it. Flag any endpoint that uses a user-supplied ID without an ownership check as IDOR (Insecure Direct Object Reference).

### A02 — Cryptographic Failures
- Passwords: must be hashed with bcrypt, scrypt, or Argon2. MD5 and SHA-1 are not acceptable for credential storage.
- JWT: signing algorithm must be HS256 (symmetric) or RS256/ES256 (asymmetric). Algorithm `none` is never acceptable.
- Encryption keys and JWT secrets: minimum 32 random bytes, sourced from environment variables or a secrets manager — never hardcoded.
- TLS: all external communication must use HTTPS. Flag any HTTP-only external call as Critical.

### A03 — Injection
- SQL: parameterized queries or ORM — never string concatenation into a query.
- Shell commands: never construct commands from user input. If a shell call is genuinely required, use an allowlist of permitted values.
- Template injection: user input must not be rendered in template strings without escaping.
- Flag any `exec()`, `eval()`, `shell_exec()`, or equivalent that receives user-controlled input as Critical.

### A07 — Authentication Failures
- JWT: verify signature, expiry (`exp`), issuer (`iss`), and audience (`aud`) on every request.
- Session tokens: invalidate on logout. Rotate on privilege escalation.
- Failed authentication attempts must be logged (timestamp, IP, username — never password). Silent swallowing of auth failures is a Medium finding.
- Password reset flows: time-limited tokens, single-use, hashed at rest.

### A08 — Data Integrity Failures
- Deserialization of untrusted data without validation is always a High finding.
- File uploads: validate MIME type server-side (not just extension), scan for malware, store outside the web root.

### A09 — Security Logging Failures
- Authentication failures, authorization failures, and input validation failures must be logged.
- Logs must not contain PII, passwords, tokens, or session IDs in cleartext.
- Stack traces and internal error details must never be returned to the caller in production.

## RISK Signal — Contextual Security Checks

### Secrets and Credentials
- Any secret, API key, password, or token hardcoded in source is Critical — treat it as compromised immediately, regardless of whether it has been committed. Rotation is required.
- `.env` files must be in `.gitignore`. Flag any `.env` file tracked by git as Critical.
- Secrets must never be passed as URL parameters, query strings, or logged in request/response bodies.

### API Surface
- Rate limiting: authentication endpoints and sensitive operations must be rate-limited.
- CORS: `Access-Control-Allow-Origin: *` on credentialed endpoints is High. Flag it.
- HTTP methods: endpoints must restrict to the methods they actually serve (GET, POST, etc.).

### Dependencies
- New packages with known CVEs: flag the CVE number and severity as a RISK finding.
- Unpinned versions in security-sensitive packages (auth libraries, crypto libraries): flag as Medium.
- Transitive dependency additions: note for the developer — they should run a dependency audit.

### Data Handling
- PII stored without encryption at rest: High finding.
- PII transmitted without TLS: Critical finding.
- Retention policy: if PII is stored with no documented deletion mechanism, flag as Medium.
- Third-party data sharing: flag any new integration that sends user data to an external service.

## When Generating Security-Sensitive Code

Apply these rules unconditionally when generating or modifying:
- Authentication flows (login, logout, token refresh, password reset)
- Authorization checks (role guards, resource ownership)
- Data encryption or hashing
- External API integrations that receive or transmit user data
- File upload or download handlers
- Admin or elevated-privilege endpoints

Always output a **Security checklist** alongside the generated code that the developer must verify before merge.

## What Security Review Must Not Do

- Downgrade a finding to avoid delivery friction. Report it and let the team decide.
- Issue a security-clear verdict on a PR with an UNGRADED security layer (e.g., no SAST tool configured).
- Fabricate a "no issues found" result because the analysis did not complete — state UNGRADED with reason.
