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

### A10 — Server-Side Request Forgery (SSRF)
- Any endpoint that fetches a URL supplied or influenced by user input is an SSRF candidate. Flag it.
- Block requests to private IP ranges: `10.x`, `172.16–31.x`, `192.168.x`, `127.x`, `169.254.x`, `::1`, and cloud metadata endpoints (`169.254.169.254`).
- **TOCTOU caveat:** The pattern of resolving DNS, checking the resolved IP, then making the request has a time-of-check/time-of-use gap — the DNS record can change between the check and the fetch, resolving to a private IP on the second lookup. Fix: resolve DNS once, pin the IP, and make the HTTP request directly to that pinned IP with the original `Host` header. Or use a dedicated SSRF-safe HTTP client library instead of manual IP checks.
- Flag any code that makes an outbound HTTP request to a user-supplied URL without one of the above controls as High.

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

## AI and LLM Feature Security

When reviewing or generating code that calls an LLM API, uses prompt-based logic, or builds agentic workflows, apply the OWASP LLM Top 10 as a minimum baseline.

| Item | Vulnerability | What to check |
|------|--------------|---------------|
| LLM01 | Prompt Injection | User input reaching an LLM prompt without sanitization — attacker can hijack model behavior or extract the system prompt |
| LLM02 | Sensitive Information Disclosure | LLM outputs containing training data, system prompt contents, or PII from context windows |
| LLM03 | Supply Chain | Third-party model providers or plugins without documented provenance, SLAs, or data-handling commitments |
| LLM04 | Data and Model Poisoning | Fine-tuning or RAG pipelines that ingest user-controlled content that could corrupt model behavior |
| LLM05 | Improper Output Handling | LLM output used in SQL queries, shell commands, HTML templates, or code execution without treating it as untrusted input |
| LLM06 | Excessive Agency | Agents with write access to external systems that can take destructive actions without human-in-the-loop approval |
| LLM07 | System Prompt Leakage | System prompts exposed via user manipulation, reflection attacks, or model output |
| LLM08 | Vector and Embedding Weaknesses | RAG pipelines that retrieve and inject user-controlled documents without sanitization before prompt assembly |
| LLM09 | Misinformation | High-stakes decisions (medical, legal, financial) made on unverified LLM output without a human verification step |
| LLM10 | Unbounded Consumption | No rate limits, token caps, or cost controls on LLM API calls — risk of cost-exhaustion denial of service |

**Key rule:** LLM output is untrusted input. Any LLM response used in a database query, shell command, template render, or downstream code execution path must be validated and escaped as if it came from an external attacker.

## Three-Tier Security Boundary

When reviewing or generating security-sensitive code, apply this enforcement hierarchy before issuing any verdict.

### Always Do
- Validate all input at system boundaries before use
- Use parameterized queries for all database access
- Source secrets from environment variables or a secrets manager — never hardcode
- Verify both authentication and authorization on every protected route
- Use HTTPS for all external communication
- Log security-relevant events: auth failures, access denials, input rejections

### Ask First — requires explicit human approval before proceeding
- Disabling or weakening an existing security control for any reason
- Storing PII in a new location or new format
- Adding a new external service that receives user data
- Granting a new permission scope to an API key or service account
- Bypassing an existing rate limit or access check
- Introducing a new authentication or session management pattern

### Never Do
- Hardcode secrets, API keys, or credentials in source
- Log passwords, tokens, session IDs, or PII
- Trust user-supplied identity — derive from verified session token only
- Accept `algorithm: none` in JWT verification
- Return stack traces or internal error details to the caller in production
- Downgrade a Critical or High security finding due to delivery pressure or timeline

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
