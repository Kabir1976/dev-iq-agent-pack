---
applyTo: "**/*.{ts,tsx,js,jsx,py,cs,java,go,rs,rb,kt,swift,cpp,c,h,php}"
---

# DI Code Standards — Generation, Review, and Refactoring Rules

Apply when generating, reviewing, or refactoring code in any language.
Read `.dev-iq/config.yaml` → `stack` for client-specific language, framework,
and tooling overrides. These rules are defaults — client config takes precedence.

## DESIGN Signal — Structural Standards

### Layer Separation
- Business logic lives in services, not controllers or repositories.
- Data access lives in repositories, injected via interface — never called directly from services or controllers.
- Controllers/handlers: receive request, delegate to service, return response. No business logic.
- Cross-cutting concerns (logging, auth, caching) belong in middleware or interceptors, not in individual services.

### Dependency Direction
- Depend on abstractions (interfaces, abstract classes), not concrete implementations.
- New external dependencies require explicit developer confirmation before introduction.
- Circular dependencies are always a DESIGN finding — flag immediately.

### Naming
- Names must communicate intent: `getUserById` not `getUser`, `OrderNotificationError` not `Error`.
- Boolean variables and parameters: prefix with `is`, `has`, `can`, `should`.
- Collections: plural nouns. Single items: singular nouns.
- **Naming conventions must follow the established standards for each language:**
  - **Constants:** `UPPER_SNAKE_CASE` (all languages)
  - **Classes/Types:** `PascalCase` (all languages)
  - **Functions/methods and properties:**
    - `camelCase`: JavaScript, TypeScript, Java, Go, Kotlin, Swift
    - `snake_case`: Python, Ruby
    - `PascalCase`: C# (public methods and properties)
  - **Internal/private members:**
    - Prefix with `_` (underscore): C# private fields (`_camelCase`), Kotlin backing properties
    - Prefix with `__` (dunder): Python private members
    - Use access modifiers: Java (`private`), Go (unexported by lowercase), C# (`private`)
- Follow the client's established naming conventions over these defaults — read existing code before generating new code.

### Abstraction
- Extract when: the same logic appears three or more times, or a function exceeds one clear responsibility.
- Do not extract prematurely: two similar lines is not duplication that warrants abstraction.
- New abstractions introduced without an ADR are a DESIGN finding at Medium severity.

### Magic Values
- No magic numbers or hardcoded string literals in logic paths — extract to named constants or configuration.
- Exception: well-known values with universal meaning (e.g., `0`, `1`, `""`) used in obviously correct context.

## QUALITY Signal — Production-Readiness Standards

### Error Handling
- Every call to an external system (database, HTTP, filesystem, message queue, email) must be wrapped in error handling.
- Errors must propagate as typed domain errors, not generic exceptions — the caller must know what failed and why.
- Never swallow errors silently — at minimum, log and rethrow.
- Log failures before throwing: the error log must be actionable without a debugger.

### Null and Undefined Safety
- Never access a property on a value that could be null/undefined without a guard.
- Use guard utilities (e.g., `findOrThrow`) over inline null checks scattered across the codebase.
- Prefer early returns and guard clauses over deeply nested if-else trees.

### Logging
- Log at the entry and exit of key business operations (order placed, payment processed, user authenticated).
- Never log PII, credentials, or secrets.
- Log level discipline: ERROR for unexpected failures, WARN for recoverable issues, INFO for key state changes, DEBUG for internal detail (stripped in production).

### Test Stubs
- Every new public function introduced must have a corresponding test stub.
- Test stubs are empty function signatures + a comment marking what scenario to cover — not full tests (Assert.IQ generates those).
- Format:
  ```
  // TEST STUB — AB#1234
  // Scenario: [description of what to test]
  ```

### TODOs and Commented-Out Code
- TODO comments left in production paths are a QUALITY finding at Medium severity.
- Commented-out code must be deleted, not left in place — source control preserves history.

## RISK Signal — Code-Level Risk Indicators

### Change Size
- ~100 lines changed: well-scoped, reviewable in a single sitting — preferred.
- ~300 lines changed: acceptable for a complex feature — ensure each logical change is independently understandable.
- ~1,000 lines changed: must be split into smaller PRs unless it is a single atomic operation (e.g., a codebase-wide rename) that cannot be meaningfully divided. Flag as a RISK finding.
- Mixing refactoring and feature work in the same PR is always a DESIGN finding — separate commits at minimum, separate PRs if the refactor is substantial.

### Breaking Changes
- Any change to a public method signature, interface contract, or API response shape is a breaking change.
- Breaking changes must be flagged explicitly in the PR description and DI assessment.
- Prefer additive changes (new optional parameter, new field) over breaking ones.

### Dependency Changes
- Adding a new package: flag for review — check license, check for known CVEs, confirm with the team.
- Unpinned versions (`^`, `~`, `*`) in production dependencies: flag as RISK finding.
- Removing or downgrading a dependency: blast radius analysis required.

### Schema and Migration
- Every database schema change requires a migration file.
- Migrations must be reversible unless the change is explicitly additive-only.
- Data migrations that touch existing rows require a rollback plan.

## Reading Existing Code First

Before generating new code:
1. Read the file(s) adjacent to where the change will go.
2. Identify the naming conventions, error handling patterns, and abstraction style already in use.
3. Match them — even if they differ from these defaults.

Consistency with the existing codebase is always more important than textbook correctness.
