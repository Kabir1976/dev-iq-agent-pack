# Changelog

All notable changes to the Dev.IQ Agent Pack are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [0.9.0] — 2026-06-06

Initial pre-release of the Dev.IQ Agent Pack.

### Added

**Skills (21 total)**
- `explain-code` — INTENT signal, plain-language code explanation with intent gap detection
- `generate-user-stories` — INTENT signal, user stories with ACs from requirements
- `review-acceptance-criteria` — INTENT signal, AC quality review (testable, specific, complete)
- `identify-dependencies` — INTENT + RISK, blocker and dependency mapping before work begins
- `design-api` — DESIGN signal, REST/GraphQL API design from requirements
- `design-data-model` — DESIGN signal, entity schema and relationship design
- `generate-adr` — DESIGN signal, Architecture Decision Records (MADR format)
- `review-architecture` — DESIGN signal, architecture review with Go/Hold verdict
- `refactor-code` — DESIGN + QUALITY, propose-before-build refactoring with change rationale table
- `code-review` — QUALITY signal, line-level code review with DI findings
- `review-security` — QUALITY + RISK, OWASP-grounded security review with Block/Clear verdict
- `debug-issue` — QUALITY + RISK, root-cause diagnosis with fix risk assessment
- `scaffold-feature` — DESIGN + QUALITY, new feature scaffolding from work item
- `blast-radius-estimator` — RISK signal, change impact analysis across consumers
- `review-dependencies` — RISK signal, CVE and license review on package changes
- `review-pr-readiness` — four-layer PR readiness assessment with Go/Hold verdict
- `new-pull-request` — delivery, PR description generation with DI signal summary
- `generate-release-notes` — INTENT, release notes from git history + work items
- `review-deployment-readiness` — QUALITY + RISK, go/no-go deployment assessment
- `generate-rollback-plan` — RISK, step-by-step rollback plan with trigger criteria
- `generate-traceability-matrix` — INTENT, requirements → code → tests traceability map
- `dev-iq-bootstrap` — setup, guided pack installation and configuration

**Agents**
- `Dev-IQ` (Copilot Chat) — full tool set, intent-to-skill routing for all 21 skills
- `Dev-IQ-PLAN` (Copilot Chat) — read-only planning agent, structured plan + Start Implementation handoff
- `dev-iq` (Claude Code) — full tool set, same routing table
- `dev-iq-plan` (Claude Code) — read-only planning agent

**Instruction files**
- `di-foundation.instructions.md` — always-on DI signal model, maturity, governance
- `di-code-standards.instructions.md` — generation, review, and refactoring rules
- `di-security.instructions.md` — OWASP-grounded security review rules
- `di-traceability.instructions.md` — work item linking and artifact tracing
- `di-signal-emission.instructions.md` — CI/CD signal wiring rules

**Bootstrap**
- `scripts/bootstrap.sh` — bash installer with trial/committed modes, graduate, uninstall, presets
- `scripts/bootstrap.ps1` — PowerShell mirror
- `INSTALL.md` — client-facing installation guide

**Presets** (`--preset` flag)
- `pod` — team pod install: committed mode + hooks
- `solo` — individual developer: trial mode, no hooks
- `portable` — client handoff: committed mode, no hooks

**Configuration**
- `.dev-iq/config.yaml` — client-specific stack, maturity, and governance config
- `.dev-iq/governance.md` — compliance posture stub
- `.dev-iq/maturity-profile.md` — maturity tier behavior definition
- `.dev-iq/telemetry-overlay.md` — signal sink configuration

---

## Planned

### [0.10.0] — Signal emission infrastructure

- `generate-maturity-report` skill — auto-computed maturity scorecard from observed DI signals
- DI signal schema (`schema_version: 1`) — JSONL format written to `.dev-iq/signals/`
- Signal emission wired into 3 existing skills: `review-pr-readiness`, `review-security`, `refactor-code`
- Telemetry sink API spec (Approach B foundation)

*Blocked on: Assert.IQ team alignment on shared signal directory path.*
