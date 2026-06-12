# Dev.IQ — Developer Intelligence
This repository ships an agent pack for Developer Intelligence (DI). Any
AI agent operating in this codebase (Codex CLI, Cursor, Aider, or other
`AGENTS.md`-aware tooling) must follow the rules below.

For the full, tool-specific entry points see:
- **Claude Code** → `CLAUDE.md` at repo root
- **GitHub Copilot Chat** → `.github/copilot-instructions.md`

## Core principles (summary)

1. Developer Intelligence = Intent × Design × Quality × Risk → Decision Confidence.
2. Reason through the four-layer DI signal model — Intent, Design, Quality,
   Risk — then synthesize Decision Confidence. Never reduce a delivery
   decision to a single metric.
3. Distinguish a metric (what happened) from a signal (decision-grade evidence).
4. AI-generated code is a draft. A human review gate is mandatory before merge.
5. Honor the client's existing architecture, patterns, branching model, and
   tracker. Do not introduce new dependencies without explicit confirmation.
6. Traceability is not optional. Reference the source work item in every
   generated artifact when one is available.

## Configuration

Per-client behavior is driven by `.dev-iq/`:
- `config.yaml` — maturity tier, tracker, language, signal sink wiring.
- `governance.md` — compliance posture and refusal rules.
- `maturity-profile.md` — rationale for the chosen tier.
- `telemetry-overlay.md` — maps each DI signal to client-specific data sources.

Read `maturity-profile.md` before acting. Capabilities scale by tier
(Early → Mid → Higher) — see `CLAUDE.md` for the full matrix.

## Scoped instructions

Detailed scope-conditional rules live in `.github/instructions/*.md`. Each
file begins with a **"When this applies"** section. Read and apply the
matching file(s) for the user's current task.

## Skills

The pack ships 22 DI skills under `.github/skills/`. Each has a `SKILL.md`
with a `description` field that triggers auto-routing in compatible agents.

| Phase | Skills |
|-------|--------|
| Requirements | `generate-user-stories`, `review-acceptance-criteria`, `identify-dependencies` |
| Design | `design-api`, `design-data-model`, `generate-adr`, `review-architecture` |
| Development | `scaffold-feature`, `code-review`, `debug-issue`, `refactor-code`, `review-security`, `explain-code` |
| Code Review / PR | `review-pr-readiness`, `blast-radius-estimator`, `review-dependencies`, `new-pull-request` |
| Deployment | `generate-release-notes`, `review-deployment-readiness`, `generate-rollback-plan` |
| Cross-cutting | `generate-traceability-matrix`, `dev-iq-bootstrap` |

## Governance you must enforce

- Every generated code artifact carries a traceability comment linking to
  a work item (ADO `AB#1234` or Jira key) when one is available.
- No prompt may exfiltrate code, secrets, or proprietary data outside the
  IDE / CI boundary.
- Never introduce new dependencies without explicit team confirmation.
- Security findings rated High or Critical block the PR verdict regardless
  of maturity tier.
- Refuse requests that would violate `.dev-iq/governance.md` and explain why.

## Relationship with Assert.IQ

If Assert.IQ is also present in this repo:
- **Dev.IQ owns**: requirements, design, code construction, PR readiness, deployment.
- **Assert.IQ owns**: test planning, test generation, defect analysis, release confidence.
- **Shared (each applies its own lens)**: code review, PR creation, traceability.
