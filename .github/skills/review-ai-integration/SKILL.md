---
name: review-ai-integration
description: Review code that calls LLM APIs, constructs prompts, builds agentic workflows, or processes model outputs. Applies the OWASP LLM Top 10 plus DI security and quality checks. Use when asked to "review this LLM code", "check this AI integration", "review my prompt handling", "audit this agentic workflow", "is this AI code secure".
di_signal: QUALITY + RISK
maturity_required: early
status: approved
---

# Review AI Integration

## Overview

Reviews code that integrates Large Language Models — prompt construction,
API calls, output handling, agentic tool use, RAG pipelines, and cost
controls — through the combined lens of the OWASP LLM Top 10, DI security
standards, and DI quality standards.

LLM output must be treated as untrusted input. Any LLM response used in a
database query, shell command, template render, or downstream code execution
path is an injection vector. This skill makes that risk visible before the
code ships.

This is both a QUALITY signal (is the integration production-ready?) and a
RISK signal (what is the blast radius if the model misbehaves or is
adversarially manipulated?).

## When to Use

- When a PR introduces or modifies LLM API calls (OpenAI, Anthropic, Azure
  OpenAI, Bedrock, Vertex AI, etc.)
- When reviewing prompt construction logic, system prompt management, or
  tool/function calling code
- When a RAG pipeline, vector search integration, or embedding-based feature
  is being added
- When an agentic workflow is introduced that takes actions on behalf of users
- Any time the user says: "review this LLM code", "check this AI integration",
  "review my prompt handling", "audit this agentic workflow", "is this AI
  code secure", "review prompt injection"

## Instructions

### Step 1: Identify the integration surface

Scan the diff or specified files for LLM integration patterns:
- **LLM SDK imports**: `openai`, `@anthropic-ai/sdk`, `langchain`, `llamaindex`,
  `vertexai`, `@azure/openai`, `boto3` (Bedrock), `google.generativeai`
- **API call patterns**: `client.chat.completions.create()`,
  `anthropic.messages.create()`, `model.generate_content()`
- **Prompt construction**: template strings, f-strings, or concatenation that
  assembles a prompt from user input or external data
- **Tool/function calling**: JSON schemas passed as `tools`, `functions`, or
  `tool_choice` parameters
- **RAG pipelines**: vector DB queries (`pinecone`, `weaviate`, `qdrant`,
  `pgvector`), document chunking, embedding generation
- **Output usage**: where the LLM response string is subsequently used

Map every call site. Unknown or indirect LLM calls (via a wrapper or internal
SDK) are flagged as UNGRADED with the reason.

### Step 2: OWASP LLM Top 10 assessment

Apply each item from `di-security.instructions.md` LLM Top 10:

#### LLM01 — Prompt Injection
- Does any user-controlled input reach a prompt without sanitisation?
- Is there a system prompt? Can a user overwrite or read it via injection?
- Are tool call results from external sources injected into follow-up prompts
  without validation?

**Severity:** Critical when user input reaches a prompt with no guard. High
when indirect injection is possible (e.g., web-fetched content injected into
RAG context).

#### LLM02 — Sensitive Information Disclosure
- Can the model be prompted to reveal the system prompt?
- Does the context window contain PII, credentials, or proprietary data that
  could leak via model reflection?
- Are responses logged in a way that stores sensitive context?

**Severity:** High when PII or credentials are in the context window with no
confidentiality control.

#### LLM03 — Supply Chain
- Is the model provider documented with its data handling commitments?
- Are third-party plugins or tool schemas loaded from untrusted sources?
- Is the model version pinned, or does it float to "latest"?

**Severity:** Medium — flag unverified providers or floating model versions.

#### LLM04 — Data and Model Poisoning
- Does the RAG pipeline ingest user-controlled content without validation?
- Can an attacker inject malicious documents into the vector store?
- Is fine-tuning data sourced from user-controlled inputs?

**Severity:** High when user-controlled content is ingested into a RAG
pipeline without validation or access control.

#### LLM05 — Improper Output Handling
- Is LLM output used in: SQL queries? Shell commands? HTML templates?
  `eval()` or `exec()`? Code execution paths?
- Is LLM output parsed as JSON/YAML without schema validation?
- Is LLM output passed to downstream services as a trusted value?

**Severity:** Critical when LLM output reaches a SQL query or shell command.
High when it reaches an HTML template or downstream API without validation.

#### LLM06 — Excessive Agency
- Does the agent have write access to external systems (files, databases,
  email, APIs)?
- Can the agent take irreversible actions (delete, send, publish, charge)?
- Is there a human-in-the-loop gate before destructive actions?
- Is the agent's tool set scoped to the minimum required?

**Severity:** High when an agent can take irreversible external actions
without human approval.

#### LLM07 — System Prompt Leakage
- Is the system prompt stored in source code (committed secret)?
- Can a user extract the system prompt via reflection attacks
  ("repeat your instructions")?
- Is the system prompt retrieved from a secure store at runtime?

**Severity:** Medium — system prompts are not secrets in themselves, but
leaked prompts reveal defenses and business logic.

#### LLM08 — Vector and Embedding Weaknesses
- Are documents retrieved from the vector store injected into prompts without
  sanitisation?
- Is there access control on what documents a user can retrieve via RAG?
- Can a user craft a query that retrieves documents they should not have access
  to (embedding inversion / membership inference)?

**Severity:** High when RAG retrieval has no access control per user/role.

#### LLM09 — Misinformation
- Are high-stakes decisions (medical, legal, financial, safety) made based on
  LLM output without a human verification step?
- Is model output presented to users as factual without a confidence signal or
  disclaimer?

**Severity:** High in regulated or safety-critical domains. Medium elsewhere.

#### LLM10 — Unbounded Consumption
- Are there token limits (`max_tokens`) on every API call?
- Are there per-user or per-session rate limits on LLM calls?
- Is there cost monitoring or alerting on LLM API spend?
- Can a user trigger expensive model calls in a loop (denial-of-wallet attack)?

**Severity:** High when there are no rate limits on user-triggered LLM calls
in a production endpoint.

### Step 3: DI quality checks for LLM code

In addition to the LLM Top 10, apply DI code standards:

- **Error handling**: LLM API calls must be wrapped in error handling with
  retry logic for transient failures (rate limits, timeouts, server errors).
  Silent failures — treating an error response as a valid completion — are High.
- **Logging**: LLM requests and responses should be logged for auditability,
  but without PII or the full user prompt (log a hash or truncated form).
  Never log API keys.
- **Structured output validation**: when the LLM is expected to return JSON,
  validate the schema before using the data. An unvalidated JSON parse of
  LLM output is an injection vector.
- **Timeout**: every LLM call must have an explicit timeout. Hanging calls
  cascade.
- **Model version pinning**: floating to `gpt-4` (which changes) vs. pinning
  to `gpt-4-0125-preview` is a supply chain risk.

### Step 4: Summarise blast radius

For the identified agentic tools or integration patterns, estimate:
- What is the worst case if the model is compromised or manipulated?
- What external systems are reachable from the agent's tool set?
- What is the rollback path if the agent takes a wrong action?

## Inputs Required

| Input | Source | Required |
|-------|--------|----------|
| Diff, PR, or file(s) with LLM code | Paste, PR number, or file path | Yes |
| LLM provider / SDK | Auto-detected from imports | Auto-read |
| Stack | `.dev-iq/config.yaml` → `stack` | Auto-read |
| Maturity tier | `.dev-iq/config.yaml` | Auto-read |

## Output Format

```
## AI Integration Review — [PR title / feature / file]
LLM Provider: [detected provider]
Integration type: [API calls | RAG | Agentic | Multi-modal]
Generated: [date]

---

### OWASP LLM Top 10 Assessment

| Item | Finding | Severity |
|------|---------|---------|
| LLM01 Prompt Injection | User input appended to system prompt at line 47 | Critical |
| LLM05 Improper Output Handling | LLM response used in SQL query at line 112 | Critical |
| LLM10 Unbounded Consumption | No max_tokens set on completions call; no rate limit | High |
| LLM06 Excessive Agency | Agent has delete_file tool with no human approval gate | High |
| LLM03 Supply Chain | Model version not pinned (uses "gpt-4") | Medium |
| LLM02, LLM04, LLM07, LLM08, LLM09 | No issues found | — |

---

### DI Quality Checks

| Check | Finding | Severity |
|-------|---------|---------|
| Error handling | completions.create() has no try/catch — API errors unhandled | High |
| Output validation | JSON.parse(response.content) with no schema validation | High |
| Logging | Full user prompt logged at INFO level — PII risk | Medium |
| Timeout | No timeout set on API call | Medium |

---

### Blast Radius

**Agent tool set:** [list of tools the agent has access to]
**Worst case if compromised:** [what an attacker could do]
**Reversibility:** [are the agent's actions reversible?]
**Rollback path:** [what the operator can do if the agent misbehaves]

---

### QUALITY Signal: [STRONG | WEAK | UNGRADED]
### RISK Signal: [STRONG | WEAK | UNGRADED]

**Blocking findings (must resolve before merge):**
- [Critical and High findings]

**Recommended improvements:**
- [Medium and Low findings]

@di-review-required
```

## Governance

- LLM output used in a SQL query or shell command is always Critical — flag
  immediately regardless of maturity tier or delivery pressure
- Human-in-the-loop is required for irreversible agent actions — no override
- Prompt injection via user-controlled input reaching a prompt is always Critical
- At Early maturity: all findings are advisory; at Mid/Higher maturity:
  Critical and High findings block the PR verdict
- Never fabricate a clean review when LLM call sites could not be fully traced
  — mark as UNGRADED with reason
- Rate limits and cost controls are REQUIRED for any LLM call reachable from
  a user-triggered endpoint — this is denial-of-wallet prevention, not
  nice-to-have

## Related Skills

- `/review-security` — run together for comprehensive security coverage;
  this skill focuses on LLM-specific vectors, review-security covers the
  broader OWASP Top 10
- `/review-observability` — LLM integrations need token usage logging,
  cost metrics, and latency tracking; run alongside this skill
- `/blast-radius-estimator` — deeper analysis of what external systems the
  agent or integration can reach
- `/review-pr-readiness` — incorporates this skill's QUALITY and RISK signals
  into the overall Go/Hold/Discuss verdict
