# Changelog

All notable changes to the Dev.IQ Agent Pack are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [0.11.0] — 2026-06-25

### Added

- **`MANIFEST.md`** — complete file inventory with hidden-file browser warning for macOS Finder and Windows Explorer.
- **`handoffs:` frontmatter on `Dev-IQ-PLAN.agent.md`** — wires the clickable "Start Implementation" button in VS Code Copilot Chat, routing directly to Dev-IQ.
- **`argument-hint` and handoff buttons on `dev-iq-plan.md`** (Claude Code) — Start Implementation and Open in Editor buttons; argument-hint surfaces as a placeholder in the subagent UI.
- **`hooks/hooks.template.json`** — Windows PowerShell variants (`osx`/`linux`/`windows` keys per hook entry).
- **`config.yaml`** — `traceability.marker_style` (6 options + config-driven code/test globs), `pr.risk_thresholds` (`lines_amber`, `lines_red`, `sensitive_paths`), `code_review` block (`disabled_categories`, `severity_floor`, `default_output_format`, depth thresholds), `mcp.servers` (per-skill server allowlist).

### Changed

- **`hooks/hooks.template.json`** — fixed incorrect Claude Code event names: `session.start` → `SessionStart`, `tool.use` → `PostToolUse`, `session.end` → `Stop`. This was a silent failure — hooks were not firing.
- **`hooks/config/skill-improve.config.json`** — expanded from 6 fields to full schema: weighted correction signatures (20 patterns, strong/weak), proactive insights detection, tool behavioral signals, thresholds, retention policy, full customization roots (`.github/instructions`, `.github/skills`, `.github/agents`, `.claude/skills`, `.claude/agents`, `.dev-iq`).
- **`.dev-iq/governance.md`** — rewritten as a fillable client template: compliance posture table (HIPAA/PCI-DSS/SOX/GDPR/CCPA/FedRAMP/ISO 27001), human review gates, escalation paths, AI tool boundary, approval signatures. Existing Data Boundary and AI Output Controls content preserved.
- **`.dev-iq/maturity-profile.md`** — expanded with 15-indicator checklist (Foundation/Signals/Quality/Governance), 7 re-evaluation triggers, approval table.
- **`review-code` skill** — added PR Context Gathering Protocol (diff + thread fetch + iteration timeline + reconciliation), Recurring Anti-Patterns Pre-flight (6 checks), review depth calibration (<20/20-200/>200 lines), Post-Review Follow-Up section, PR Comment Reconciliation table in output.
- **`create-pull-request` skill** — added credential pre-flight scan (7 patterns: AWS, Azure, GCP, GitHub, Slack, GitLab, PEM), PR template merge logic, per-host CLI routing table (GitHub/ADO/GitLab/Bitbucket).
- **`validate-acceptance-criteria` skill** — config-backed `ac_review.preferred_format`, `ac_review.gating_policy`, `ac_review.nfr_checklist`.
- **`generate-traceability` skill** — 6 marker styles from `traceability.marker_style` in config; reads `code_globs`/`test_globs` from config instead of always prompting the user.
- **`scripts/bootstrap.sh` + `bootstrap.ps1`** — `--dry-run` flag (shows what would change without applying), `--yes` / `-y` flag (skips interactive confirmation), uninstall snapshot/restore (saves `.di.pre-install` before overwriting, restores on `--uninstall`).

### Added (skills)

- **`estimate-effort`** — INTENT + DESIGN signal. Calibrated story-point and t-shirt sizing with rationale, uncertainty band, and scope-risk flags.
- **`review-observability`** — QUALITY signal. Logging, metrics, distributed tracing, health endpoints, and alerting coverage review with severity-rated anti-patterns.
- **`generate-openapi`** — DESIGN signal. Generates OpenAPI 3.x YAML from controller/router code across Express, NestJS, FastAPI, Spring, ASP.NET, Rails, and Go — with gap report.
- **`onboard-codebase`** — INTENT signal. New developer guide generated from repo structure: architecture map, one key data flow, local dev setup, and 10 conventions to know before touching code.
- **`review-ai-integration`** — QUALITY + RISK signal. Full OWASP LLM Top 10 review for LLM/agentic code with blast radius summary.

### Changed (skill renames — resolves Assert.IQ name collision, aligns with `review-*` convention)

- `code-review` → **`review-code`** — fixes naming convention (only skill not following `review-*` pattern).
- `new-pull-request` → **`create-pull-request`** — clearer verb.
- `review-acceptance-criteria` → **`validate-acceptance-criteria`** — stronger verb, avoids exact Assert.IQ collision.
- `generate-traceability-matrix` → **`generate-traceability`** — shorter name, avoids exact Assert.IQ collision.

### Removed (skills)

- **`generate-user-stories`** — BA/PO territory, not developer territory. Replaced in starter recommendations by `/onboard-codebase` ("Joining a new codebase") and `/estimate-effort` ("Starting a new feature").

---

## [0.10.0] — 2026-06-22

### Added

- **Visual Studio 2022 support** — `.mcp.json` at repo root (VS 2022 reads this; VS Code reads `.vscode/mcp.json`).
  `docs/trial-install-guide.md` and `docs/colleague-welcome.md` updated with VS 2022 prerequisites,
  one-time "Enable repository custom instructions" setup step, and IDE comparison table.
- **`docs/colleague-welcome.md`** — self-contained onboarding doc for trial participants.
  Covers install, IDE-specific verification, 22-skill reference table, and a tiered validation
  checklist (Tier 1 Day 1 / Tier 2 Day 1-2 / Tier 3 Day 2-3) with explicit pass/fail criteria.
- **`.github/PULL_REQUEST_TEMPLATE.md`** — PR template with DI four-layer signal table,
  AI-generated artifact checkbox, and standard delivery checklist.
- **`.dev-iq/artifacts/`** — gitignored local artifact store for generated ADRs, rollback plans,
  user stories, and PR reviews. Bootstrap creates five subdirectories; `.gitignore` inside is
  self-managing regardless of install mode.
- **`scripts/validate-skills.sh`** — frontmatter validator for all 22 skills and 2 agents.
  Bash + awk only — no Node.js or external runtime required. CI workflow updated to call it directly.
- **`.github/workflows/copilot-setup-steps.yml`** — CI skill validator runs on every PR push.
  Checks frontmatter on all SKILL.md and agent files; checks for both MCP config files.
- **`docs/reference.md`** — "Market Context: Why This Pack Exists" section with verified
  research stats (IBM 2025 CODB, Stack Overflow 2025, SSRN RCT). "Enterprise Governance:
  Agent Autonomy Classification" section maps all 22 skills to Gartner autonomy tiers.
  "Distributing to Colleagues" section with `git archive` and GitHub collaborator options.
- **`README.md`** — "Why structured governance matters now" section with trust/adoption data
  grounding the pack's governance rationale.

### Changed

- `docs/trial-install-guide.md` — fixed bootstrap command (`-Preset solo`), consistent path
  placeholder, structured feedback template, VS 2022 prerequisites in pre-flight checklist.
- `docs/reference.md` — renamed from `README.dev-iq.md`; fixed stale content:
  Sparq branding removed, private GitHub URL replaced with zip-extract instructions,
  python3 prerequisite removed, `--preset=solo` description corrected,
  `pwsh` → `powershell` throughout, `MANIFEST.md` references removed.
- `.dev-iq/telemetry-overlay.md` — written from 3-line placeholder to full
  signal-mapping template with tables for INTENT, DESIGN, QUALITY, RISK, and Signal Sink.
- `scripts/bootstrap.sh` / `bootstrap.ps1` — artifact store directories created on install;
  `prefill_config` only emits "Config pre-filled" when at least one value was actually written.
- `.github/instructions/di-foundation.instructions.md` — Artifact Persistence section added:
  save-offer pattern for Claude Code and Copilot Chat, filename format, never-overwrite rule.
- `README.md` — fixed stale `README.dev-iq.md` header link → `docs/reference.md`.
- `AGENTS.md` — corrected "five-layer DI signal model" → "four-layer".

### Removed

- `scripts/validate-skills.js` — replaced by `scripts/validate-skills.sh` (no Node.js dependency).
- `install.sh`, `install.ps1` — 3-line placeholders; real scripts are in `scripts/`.
- `MANIFEST.md` — 3-line placeholder with no content.
- `ONE-PAGER.md` — executive/sales artifact, wrong audience for a developer repo.
- `INSTALL.md` — stale; functionality covered by `docs/trial-install-guide.md` and `README.md`.

---

## [0.9.0] — 2026-06-06

Initial pre-release of the Dev.IQ Agent Pack.

### Added

**Skills (22 total)**
- `explain-code` — INTENT signal, plain-language code explanation with intent gap detection
- `generate-user-stories` — INTENT signal, user stories with ACs from requirements
- `validate-acceptance-criteria` — INTENT signal, AC quality review (testable, specific, complete)
- `identify-dependencies` — INTENT + RISK, blocker and dependency mapping before work begins
- `design-api` — DESIGN signal, REST/GraphQL API design from requirements
- `design-data-model` — DESIGN signal, entity schema and relationship design
- `generate-adr` — DESIGN signal, Architecture Decision Records (MADR format)
- `review-architecture` — DESIGN signal, architecture review with Go/Hold verdict
- `refactor-code` — DESIGN + QUALITY, propose-before-build refactoring with change rationale table
- `review-code` — QUALITY signal, line-level code review with DI findings
- `review-security` — QUALITY + RISK, OWASP-grounded security review with Block/Clear verdict
- `debug-issue` — QUALITY + RISK, root-cause diagnosis with fix risk assessment
- `scaffold-feature` — DESIGN + QUALITY, new feature scaffolding from work item
- `blast-radius-estimator` — RISK signal, change impact analysis across consumers
- `review-dependencies` — RISK signal, CVE and license review on package changes
- `review-pr-readiness` — four-layer PR readiness assessment with Go/Hold verdict
- `create-pull-request` — delivery, PR description generation with DI signal summary
- `generate-release-notes` — INTENT, release notes from git history + work items
- `review-deployment-readiness` — QUALITY + RISK, go/no-go deployment assessment
- `generate-rollback-plan` — RISK, step-by-step rollback plan with trigger criteria
- `generate-traceability` — INTENT, requirements → code → tests traceability map
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
