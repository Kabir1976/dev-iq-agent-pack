---
name: generate-openapi
description: Generate an OpenAPI 3.x specification from controller, router, or handler code. Extracts endpoints, parameters, request/response shapes, authentication schemes, and error responses. Use when asked to "generate API spec", "create OpenAPI", "document this API", "generate swagger", "write the API contract".
di_signal: DESIGN
maturity_required: early
status: approved
---

# Generate OpenAPI

## Overview

Generates an OpenAPI 3.x (formerly Swagger) YAML specification by reading
the actual controller, router, or handler code in the repository. The output
is a machine-readable API contract that documents every endpoint, its
parameters, request/response shapes, authentication requirements, and error
responses.

This is a DESIGN signal skill: an API that exists in code but not in a
contract is undesigned from the integration perspective. Partners, mobile
clients, and QA teams cannot consume or test an undocumented API correctly.

The skill reads code — it does not invent endpoints. Every route in the output
must map to actual code. Missing error responses and undocumented endpoints
are flagged rather than silently omitted.

## When to Use

- When a new API or set of endpoints has been built without a spec
- When an existing spec is out of sync with the code and needs regeneration
- When a partner, mobile team, or QA team needs a contract to work from
- Before deploying a new API version — the spec is the breaking-change record
- Any time the user says: "generate API spec", "create OpenAPI", "document
  this API", "generate swagger", "write the API contract", "openapi.yaml"

## Instructions

### Step 1: Detect framework and router pattern

Read `.dev-iq/config.yaml` → `stack.languages` and `stack.frameworks`.
Then scan the codebase for framework-specific routing patterns:

| Framework | Signal files | Route pattern |
|-----------|-------------|---------------|
| Express / NestJS | `*.router.ts`, `*.controller.ts`, `app.ts` | `router.get/post/put/delete`, `@Get()`, `@Post()` decorators |
| FastAPI | `*.py` with `@app.get`, `@router.post` | Python type hints → request/response models |
| Spring Boot | `*Controller.java`, `*RestController.java` | `@GetMapping`, `@PostMapping`, `@RequestMapping` |
| ASP.NET | `*Controller.cs`, `Program.cs` | `[HttpGet]`, `[HttpPost]`, `app.Map*()` |
| Rails | `routes.rb`, `*_controller.rb` | `resources :`, `get`, `post` |
| Go (net/http / Chi / Gin) | `*.go` with `HandleFunc`, `router.GET` | Route registration patterns |

If the framework cannot be detected, ask the user to specify it or point to
the router/controller files.

### Step 2: Extract endpoints

For each detected route, extract:
- **HTTP method** (GET, POST, PUT, PATCH, DELETE)
- **Path** including path parameters (`/users/{id}`)
- **Handler function** name (used to find request/response types)
- **Route groupings** (prefixes, versioning: `/api/v1/...`)
- **Authentication middleware** applied at route or group level

Build a flat list of all endpoints before proceeding. Flag any routes that
have no corresponding handler (dead routes) or handlers with no routes
(orphaned handlers).

### Step 3: Infer request shapes

For each endpoint, read the handler function to determine:
- **Path parameters** — extract from route pattern and handler signature
- **Query parameters** — scan for `req.query.*`, `@Query()`, `request.args`, etc.
- **Request body** — find the DTO, schema, model, or type the handler
  deserialises from the body
- **Required vs. optional fields** — infer from type annotations, validation
  decorators, or schema definitions
- **Validation rules** — min/max, pattern, enum values from validators
  (class-validator, Zod, Pydantic, Joi, etc.)

For each request body type, generate an OpenAPI `schema` object. Reuse
`$ref` to `components/schemas/` for types used in more than one endpoint.

### Step 4: Infer response shapes

For each handler, find the response type(s):
- **Success response** — the DTO or type returned on the happy path; HTTP
  status code (200, 201, 204, etc.)
- **Error responses** — find every `throw`, error return, or exception type
  in the handler and map to HTTP status codes:
  - 400 Bad Request — validation failure
  - 401 Unauthorized — authentication failure
  - 403 Forbidden — authorization failure
  - 404 Not Found — resource missing
  - 409 Conflict — duplicate or constraint violation
  - 422 Unprocessable Entity — business rule failure
  - 500 Internal Server Error — unhandled exception
- **Pagination** — detect pagination patterns and document `page`, `limit`,
  `total` in the response schema

Flag endpoints with only a 200 response documented and no error responses —
these are incomplete contracts.

### Step 5: Extract authentication scheme

Scan for auth middleware applied globally or per-route:
- JWT bearer (`Authorization: Bearer <token>`) → `securitySchemes.bearerAuth`
- API key in header → `securitySchemes.apiKey`
- OAuth 2.0 → `securitySchemes.oauth2`
- Cookie-based session → `securitySchemes.cookieAuth`

Apply the detected scheme as the default security requirement. Routes with no
auth applied are documented with `security: []` (explicitly public) — do not
silently omit security.

### Step 6: Generate the OpenAPI YAML

Assemble the complete spec:

```yaml
openapi: "3.1.0"
info:
  title: "[project name from config.yaml or inferred]"
  version: "[version from package.json / pom.xml / inferred]"
  description: "[one-line description of the API]"
servers:
  - url: "[base URL from config or environment variable pattern]"
paths:
  /resource/{id}:
    get:
      summary: "[inferred from handler name]"
      operationId: "[handlerName]"
      tags: ["[controller/router group]"]
      parameters: [...]
      responses:
        "200": ...
        "404": ...
components:
  schemas:
    [all shared DTOs/models]
  securitySchemes:
    [detected auth scheme]
```

### Step 7: Gap report

After the spec, produce a findings table listing:
- Endpoints with no error responses documented
- Request bodies with no schema (handler accepts `any` or `object`)
- Parameters with no type or description
- Endpoints with no auth applied (confirm intentionally public)
- Dead routes or orphaned handlers

## Inputs Required

| Input | Source | Required |
|-------|--------|----------|
| Router / controller files | Codebase scan or explicit file path | Yes |
| Framework | `.dev-iq/config.yaml` → `stack.frameworks` | Auto-detected |
| Project name / version | `package.json`, `pom.xml`, or `config.yaml` | Auto-read |
| Base URL | Environment config or user input | Optional |
| Auth scheme | Middleware scan | Auto-detected |

## Output Format

````
## OpenAPI Specification — [Project name]
Framework: [detected framework]
Endpoints found: [N]
Generated: [date]

---

### DESIGN Assessment

[Summary: is the API well-structured? Findings on versioning, naming,
consistency of error response shapes, auth coverage.]

DESIGN: [STRONG | WEAK | UNGRADED]

---

### Specification

```yaml
openapi: "3.1.0"
[full spec]
```

---

### Gap Report

| Endpoint | Gap | Severity |
|----------|-----|---------|
| GET /users/{id} | No 404 error response documented | Medium |
| POST /orders | Request body schema missing (handler accepts `any`) | High |
| DELETE /admin/users | No auth scheme applied — confirm intentionally public | High |

---

DESIGN Signal: [STRONG | WEAK | UNGRADED]

@di-review-required
````

## Governance

- Never invent endpoints — every path in the output must map to actual code
- Undocumented endpoints are flagged, not silently omitted
- Endpoints with no error responses are a DESIGN finding — a contract without
  failure modes is not a contract
- Public endpoints (no auth) must be explicitly confirmed, not silently left
- The generated spec is a draft — mark with `@di-review-required`; the team
  must verify field descriptions, examples, and deprecation markers

## Related Skills

- `/design-api` — run this first when designing a new API before code is
  written; this skill generates a spec from existing code
- `/review-pr-readiness` — when the PR includes API changes, the spec diff
  is the breaking-change evidence for the RISK layer
- `/review-security` — after generating the spec, check auth coverage and
  IDOR risk on parameterised endpoints
- `/review-architecture` — when the API shape raises structural design questions
