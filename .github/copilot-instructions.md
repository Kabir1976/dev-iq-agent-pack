# Dev.IQ — GitHub Copilot Chat entrypoint

This repository is governed by the Developer Intelligence (DI) operating model.
`.github/instructions/di-foundation.instructions.md` is the single source of
truth for DI principles, governance, maturity tiers, output standards, and
Assert.IQ boundaries — Copilot loads it automatically via `applyTo: "**"`.

## Scoped instructions (loaded automatically via applyTo)

- `di-foundation.instructions.md` — **always-on**: DI signal model, governance, maturity, output standards, Assert.IQ
- `di-code-standards.instructions.md` — code generation, review, refactoring
- `di-security.instructions.md` — security review, auth, data handling, OWASP
- `di-traceability.instructions.md` — work item linking, artifact tracing
- `di-signal-emission.instructions.md` — CI/CD configuration changes

## Copilot capabilities

- **Agents** — `Dev-IQ` (default, full tools) and `Dev-IQ-PLAN` (read-only planning → Start Implementation handoff to Dev-IQ)
- **Skills** — 22 DI skills invoked with `/skill-name` in Copilot Chat. Type `/` to see all available skills.
- **Per-client config** — `.dev-iq/config.yaml`, `.dev-iq/governance.md`, `.dev-iq/maturity-profile.md`

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
| `/code-review` | DESIGN + QUALITY | Code review through DI four-layer lens |
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

- `CLAUDE.md` — Claude Code entry. Same instruction files, Claude Code-specific wiring.
- `AGENTS.md` — generic agent-spec pointer for Codex CLI, Cursor, Aider.
