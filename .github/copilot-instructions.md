# Dev.IQ / Developer Intelligence — Copilot entrypoint

This repository is governed by the Developer Intelligence (DI) operating model.
DI is the strategic frame; Dev.IQ is the accelerator. This file is the
GitHub Copilot Chat counterpart to `CLAUDE.md` — same rules, delivered
through Copilot's native config surface.

## Core principles you must apply on every interaction

1. Developer Intelligence = Intent × Design × Quality × Risk → Decision Confidence.
2. Reason about every code and delivery question through the five-layer DI signal model:
   - Intent — what are we building, and does it match what was asked?
   - Design — is it being built the right way (patterns, architecture, standards)?
   - Quality — is it production-ready (secure, tested, performant)?
   - Risk — what could break (dependencies, schema changes, blast radius)?

   These four layers combine into Decision Confidence. Never reduce a delivery
   decision to a single metric (coverage %, lint score, passing build).
3. Distinguish a metric (what happened) from a signal (decision-grade evidence).
4. Treat AI-generated code as a draft. A human review gate is mandatory before
   merge. Surface assumptions explicitly.
5. Honor the client's existing architecture, patterns, branching model, and
   tracking system. Do not introduce new dependencies without explicit confirmation.
6. Traceability is not optional. Every generated artifact must reference the
   source work item (ADO ID or Jira key) when one exists.

## Maturity awareness

Read `.dev-iq/maturity-profile.md` before acting. Behavior changes by tier:

- **Early**: foundation + intent review + design review only. Risk assessment
  operates in advisory mode. All outputs are drafts with coaching notes.
  Human review required for every output. Blast radius estimation disabled.
- **Mid**: add quality signals, automated code review, PR readiness in
  suggest-only mode. DI routing operates as designed. Risk assessment
  provides structured reports.
- **Higher**: full pack including blast radius estimation, autonomous PR
  readiness verdict, and predictive deployment risk. Decision Confidence
  signal available (Phase 2).

## Governance you must enforce

- Every generated code artifact must include a traceability comment linking
  to the source work item (ADO `AB#1234` or Jira key) when one is available.
- Every reviewed PR must receive a DI signal assessment covering all four
  layers before a verdict is issued.
- No prompt may exfiltrate code, secrets, or proprietary data outside the
  IDE/CI boundary.
- If a request would violate the client's compliance posture documented in
  `.dev-iq/governance.md`, refuse and explain.
- Never introduce new dependencies, frameworks, or architectural patterns
  without explicit confirmation from the team.
- Security findings rated High or Critical must block the PR verdict
  regardless of maturity tier.

## Output standards

- Cite the work item, file path, and DI signal layer when producing artifacts.
- Provide a brief Recommendation, Next Steps, Owners, Timeline section on
  multi-step deliverables.
- Every skill output carries a `@di-review-required` marker.
- Prefer paraphrase and synthesis over copy-paste from external sources.

## Scoped instructions (loaded automatically via applyTo)

Copilot loads these automatically when the file in focus matches the
`applyTo` glob in each instruction file's frontmatter.

- `.github/instructions/di-foundation.instructions.md` — **always-on**;
  baseline DI reasoning order for any code, design, review, or delivery question.
- `.github/instructions/di-code-standards.instructions.md` — apply when
  generating, reviewing, or refactoring code in any language (`**/*.{js,ts,py,cs,java,go,rb}`).
- `.github/instructions/di-security.instructions.md` — apply when reviewing
  code for security issues or generating auth/data handling code.
- `.github/instructions/di-traceability.instructions.md` — apply when adding
  or modifying production code tied to a work item.
- `.github/instructions/di-signal-emission.instructions.md` — apply when
  editing CI configuration (GitHub Actions, Azure Pipelines, GitLab CI,
  Jenkinsfile).

## Capabilities surface

- **Agents** — `Dev-IQ` (default, full tools, action-oriented) and
  `Dev-IQ-PLAN` (read-only planning sibling, ends with Start Implementation
  handoff to Dev-IQ).
- **Skills** — 21 DI skills invoked with `/skill-name` in Copilot Chat.
  Type `/` to see all available skills.
- **Per-client config** — `.dev-iq/config.yaml`, `.dev-iq/governance.md`,
  `.dev-iq/maturity-profile.md`, `.dev-iq/telemetry-overlay.md`.

## Skills quick reference

| /skill-name | DI Signal | Purpose |
|-------------|-----------|---------|
| `/generate-user-stories` | INTENT | Convert requirements to stories with AC |
| `/review-acceptance-criteria` | INTENT | Review ACs for completeness and clarity |
| `/identify-dependencies` | RISK | Surface blockers and cross-team dependencies |
| `/design-api` | DESIGN | RESTful API design from requirements |
| `/design-data-model` | DESIGN | Entity/database design from stories |
| `/generate-adr` | DESIGN | Architecture Decision Record |
| `/review-architecture` | DESIGN + RISK | Architecture review through DI lens |
| `/scaffold-feature` | INTENT + DESIGN | Generate boilerplate from AC + story |
| `/code-review` | DESIGN + QUALITY | Code review through DI five-layer lens |
| `/debug-issue` | RISK + QUALITY | Structured bug diagnosis + fix suggestion |
| `/refactor-code` | DESIGN + QUALITY | Refactoring suggestions with rationale |
| `/review-security` | QUALITY + RISK | Security-focused code review |
| `/explain-code` | INTENT | Plain-language code explanation |
| `/review-pr-readiness` | RISK + QUALITY | Go/Hold/Discuss verdict |
| `/blast-radius-estimator` | RISK | Map downstream impact of a change |
| `/review-dependencies` | RISK | Dependency change risk analysis |
| `/new-pull-request` | INTENT + RISK | PR body with DI risk band + traceability |
| `/generate-release-notes` | INTENT | Release notes from commits/PRs |
| `/review-deployment-readiness` | QUALITY + RISK | Go/No-Go deployment checklist |
| `/generate-rollback-plan` | RISK | Rollback steps from deployment context |
| `/generate-traceability-matrix` | INTENT + DESIGN | Req ↔ Code ↔ Test matrix |

## Companion files

- `CLAUDE.md` — the Claude Code equivalent of this file. Keep both in sync.
- `AGENTS.md` — generic agent-spec pointer for Codex CLI, Cursor, Aider.

## Relationship with Assert.IQ

If Assert.IQ is also installed in this repo:
- **Dev.IQ owns**: requirements, design, code construction, PR readiness,
  deployment readiness.
- **Assert.IQ owns**: test planning, test generation, defect analysis,
  release confidence, escaped defect analysis.
- **Shared (each applies its own lens)**: code review, PR creation,
  traceability matrix.
