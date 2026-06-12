# Changelog

All notable changes to the Dev.IQ Agent Pack are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [Unreleased] — post-0.9.0 maintenance (2026-06-12)

### Changed

- `docs/reference.md` — renamed from `README.dev-iq.md`; fixed stale content:
  Sparq branding removed, private GitHub URL replaced with zip-extract instructions,
  python3 prerequisite removed, `--preset=solo` description corrected,
  `pwsh` → `powershell` throughout, `MANIFEST.md` references removed
- `.dev-iq/telemetry-overlay.md` — written from 3-line placeholder to full
  signal-mapping template with tables for INTENT, DESIGN, QUALITY, RISK, and
  Signal Sink sections
- `scripts/bootstrap.sh` — `prefill_config` now only emits "Config pre-filled"
  when at least one value was actually written; uninstall now prints "Your code,
  tests, and configs were not touched"
- `README.md` — fixed stale `README.dev-iq.md` header link → `docs/reference.md`
- `AGENTS.md` — corrected "five-layer DI signal model" → "four-layer"
- `docs/trial-install-guide.md` — fixed `your-ups-repo` placeholder → `your-repo`
- `docs/demo-script.md` — fixed broken `INSTALL.md` reference

### Removed

- `install.sh`, `install.ps1` — 3-line placeholders; real scripts are in `scripts/`
- `MANIFEST.md` — 3-line placeholder with no content
- `ONE-PAGER.md` — executive/sales artifact, wrong audience for a developer repo
- `INSTALL.md` — stale: listed Python 3.8+ as a prerequisite, referenced a private
  GitHub URL; functionality covered by `docs/trial-install-guide.md` and `README.md`

---

## [0.9.0] — 2026-06-06

Initial pre-release of the Dev.IQ Agent Pack.

### Added

**Skills (22 total)**
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
- `Dev-IQ` (Copilot Chat) — full tool set, intent-to-skill routing for all 22 skills
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
- `docs/trial-install-guide.md` — Windows-first personal trial install guide
- `docs/reference.md` — full reference (skill registry, workflows, customization, troubleshooting)

**Presets** (`--preset` flag)
- `pod` — team pod install: committed mode + hooks
- `solo` — individual developer: trial mode, no hooks
- `portable` — client handoff: committed mode, no hooks

**Configuration**
- `.dev-iq/config.yaml` — client-specific stack, maturity, and governance config
- `.dev-iq/governance.md` — compliance posture document (data boundary, access controls, AI output controls)
- `.dev-iq/maturity-profile.md` — maturity tier behavior definition
- `.dev-iq/telemetry-overlay.md` — signal sink configuration

---

## Planned

### [0.10.0] — Signal emission infrastructure

- `generate-maturity-report` skill — auto-computed maturity scorecard from observed DI signals
- DI signal schema (`schema_version: 1`) — JSONL format written to `.dev-iq/signals/`
- Signal emission wired into 3 existing skills: `review-pr-readiness`, `review-security`, `refactor-code`
- Telemetry sink API spec (Approach B foundation)

Signal directory: `.dev-iq/signals/` (Dev.IQ-owned namespace). Assert.IQ integration is complementary and deferred — both packs operate independently.
