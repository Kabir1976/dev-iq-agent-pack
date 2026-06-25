# Dev.IQ Agent Pack — File Manifest

> **HIDDEN FILES NOTE:** On macOS Finder, folders starting with `.` are hidden. The most important
> Dev.IQ directories (`.github/`, `.dev-iq/`, `.vscode/`, `.claude/`) are all hidden by default.
> To see them: press **Cmd+Shift+.** in Finder. On Windows: **View > Show > Hidden items**.
> In VS Code they are always visible in the Explorer panel.

---

## Pack root

| File | Purpose |
|------|---------|
| `README.md` | Project overview and quick-start entry point for the Dev.IQ Agent Pack v0.10.0. |
| `CHANGELOG.md` | Release history for the pack following the Keep a Changelog format. |
| `MANIFEST.md` | This file — a complete inventory of every tracked file with purpose descriptions. |
| `AGENTS.md` | Agent-spec pointer for AGENTS.md-aware tooling (Codex CLI, Cursor, Aider) — sets DI governance rules for all AI agents operating in the codebase. |
| `VERSION` | Single-line plain-text file recording the current pack version number. |
| `.gitignore` | Git ignore rules, including the generated `hooks/hooks.json` and the install manifest. |
| `.mcp.json` | MCP server configuration for Visual Studio 2022 — kept in sync with `.vscode/mcp.json`. |

---

## .github/

| File | Purpose |
|------|---------|
| `.github/copilot-instructions.md` | GitHub Copilot Chat entrypoint — mirrors `CLAUDE.md` for the Copilot side, pointing to the same DI instruction files. |
| `.github/vscode-readme.md` | Placeholder for VS Code–specific guidance to be added in a future session. |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR template enforcing DI traceability: work item link, AC coverage, and DI signal summary. |

### .github/instructions/

| File | Purpose |
|------|---------|
| `di-foundation.instructions.md` | Always-on baseline: the four DI signal layers (INTENT, DESIGN, QUALITY, RISK), maturity tier behavior, governance rules, and agent autonomy model. |
| `di-code-standards.instructions.md` | Code generation, review, and refactoring rules covering layer separation, naming, error handling, null safety, and test stubs. |
| `di-security.instructions.md` | Security review and generation rules operationalizing OWASP Top 10 and OWASP LLM Top 10 within the DI signal model. |
| `di-traceability.instructions.md` | Work item linking and artifact tracing rules — format, scope, traceability matrix structure, and PR requirements. |
| `di-signal-emission.instructions.md` | CI/CD configuration rules ensuring that coverage, SAST, lint, and dependency scan signals flow into every PR assessment. |

### .github/skills/

| Skill | DI Signal | What it does |
|-------|-----------|-------------|
| `blast-radius-estimator` | RISK | Maps the downstream impact of a proposed change — consumers, services, schemas, teams — and produces a deployment sequencing recommendation. |
| `code-review` | DESIGN + QUALITY | Reviews a code change through all four DI signal layers and produces a severity-rated findings report with a merge verdict. |
| `debug-issue` | QUALITY + RISK | Diagnoses the root cause of a bug or unexpected behavior, distinguishing root causes from symptoms and assessing fix risk. |
| `design-api` | DESIGN | Designs a REST or GraphQL API from requirements, producing endpoint definitions, request/response schemas, and an error contract. |
| `design-data-model` | DESIGN | Designs a relational or document data model from requirements, producing entity definitions, relationships, index recommendations, and migration impact notes. |
| `dev-iq-bootstrap` | — | Guides installation and configuration of the Dev.IQ Agent Pack into a new workspace, calling the bootstrap script with auto-detected project settings. |
| `explain-code` | INTENT | Explains code in plain language through the INTENT lens — what it does, whether it matches its stated purpose, and what assumptions it makes. |
| `generate-adr` | DESIGN | Generates a MADR-style Architecture Decision Record capturing context, the decision made, alternatives considered, and consequences. |
| `generate-release-notes` | INTENT | Generates structured release notes from git history, merged PRs, and linked work items, flagging untracked scope as INTENT UNGRADED. |
| `generate-rollback-plan` | RISK | Generates a rollback plan for a deployment — trigger criteria, step-by-step reversal procedure, and explicit documentation of what cannot be rolled back. |
| `generate-traceability-matrix` | INTENT | Generates a traceability matrix mapping work items to acceptance criteria to code to tests, surfacing gaps at each link in the chain. |
| `generate-user-stories` | INTENT | Converts requirements or stakeholder descriptions into well-formed user stories with acceptance criteria and a shared Definition of Done. |
| `identify-dependencies` | INTENT + RISK | Surfaces blockers, external dependencies, and delivery risks for a work item before work begins, rated by severity with a resolution order. |
| `new-pull-request` | DESIGN + QUALITY + RISK | Generates a complete, ready-to-paste PR description from the current diff and linked work item, including a DI signal summary. |
| `refactor-code` | DESIGN + QUALITY | Analyzes code through DESIGN and QUALITY lenses, proposes a plan for developer approval, then delivers refactored code with per-change rationale. |
| `review-acceptance-criteria` | INTENT | Evaluates acceptance criteria on a work item for testability, specificity, completeness, and consistency — returns an AC-by-AC assessment with gaps. |
| `review-architecture` | DESIGN + RISK | Reviews an architecture or design proposal for layer separation, coupling, scalability, and single points of failure — issues a Go / Go with recommendations / Hold verdict. |
| `review-dependencies` | RISK | Reviews package dependencies for security vulnerabilities, license risk, maintenance status, and pinning hygiene — produces severity-rated findings per dependency. |
| `review-deployment-readiness` | QUALITY + RISK | Runs all four DI signal layers against a release and issues a Go / Go with conditions / No-Go deployment readiness verdict. |
| `review-pr-readiness` | RISK + QUALITY | Runs a structured pre-merge assessment across all four DI signal layers and produces a signal scorecard, findings, and a Go / Go with comments / Hold verdict. |
| `review-security` | QUALITY + RISK | Runs a structured security assessment across OWASP Top 10 and DI signal layers — Critical and High findings always block regardless of delivery pressure. |
| `scaffold-feature` | INTENT + DESIGN | Generates a production-ready code scaffold from a user story and ACs — file structure, interfaces, placeholder implementations with TODOs, and test stubs. |

### .github/agents/

| File | Purpose |
|------|---------|
| `Dev-IQ.agent.md` | VS Code Copilot Chat agent definition for Dev-IQ — full read/edit/run authority, routes intent to the right DI skill. |
| `Dev-IQ-PLAN.agent.md` | VS Code Copilot Chat agent definition for Dev-IQ-PLAN — read-only, plan-first mode that ends with a Start Implementation handoff to Dev-IQ. |

### .github/workflows/

| File | Purpose |
|------|---------|
| `copilot-setup-steps.yml` | GitHub Actions workflow that pre-installs dependencies so the environment is ready before any Copilot coding session or CI skill run. |

---

## .claude/

| File | Purpose |
|------|---------|
| `.claude/claude-readme.md` | Placeholder for Claude Code–specific guidance to be added in a future session. |
| `.claude/settings.json` | Claude Code hook configuration — wires PostToolUse and Stop hooks to the Hindsight Hook scripts. |
| `.claude/skills.md` | Documents that the `.claude/skills/` directory is a symlink to `.github/skills/` created by the bootstrap script. |

### .claude/agents/

| File | Purpose |
|------|---------|
| `dev-iq.md` | Claude Code subagent definition for dev-iq — full-tool Developer Intelligence agent for code review, refactoring, security, PR readiness, and all DI four-layer assessments. |
| `dev-iq-plan.md` | Claude Code subagent definition for dev-iq-plan — read-only planning agent that produces a structured DI four-layer plan before any files are touched. |

---

## .claude-plugin/

| File | Purpose |
|------|---------|
| `.claude-plugin/plugin.json` | Claude plugin manifest declaring the pack name, version, and description for the Dev.IQ plugin. |
| `.claude-plugin/marketplace.json` | Marketplace metadata identifying the plugin publisher (sparq) for distribution. |

---

## .dev-iq/

| File | Purpose |
|------|---------|
| `.dev-iq/config.yaml` | Per-client configuration controlling workspace role, stack, tracker, signal thresholds, and all Dev.IQ behavioral overrides. |
| `.dev-iq/governance.md` | Client governance posture template — compliance requirements, restricted operations, and escalation paths. |
| `.dev-iq/maturity-profile.md` | Maturity tier declaration (Early / Mid / Higher) that controls verdict authority, blast radius, and advisory vs. autonomous behavior. |
| `.dev-iq/telemetry-overlay.md` | Telemetry configuration — signal sink URL, event filtering, and local vs. remote emission mode. |
| `.dev-iq/CHANGELOG.md` | Pack-level changelog tracking version history from the `.dev-iq/` perspective (currently records the v0.10.0 initial release). |
| `.dev-iq/artifacts/README.md` | Documents that `.dev-iq/artifacts/` is a local, gitignored store for session artifacts generated by Dev.IQ skills. |
| `.dev-iq/artifacts/.gitignore` | Ensures all generated skill artifacts (ADRs, rollback plans, PR reviews, user stories) are never committed to source control. |

---

## .vscode/

| File | Purpose |
|------|---------|
| `.vscode/mcp.json` | VS Code MCP server configuration — defines the IDE-resident MCP servers used by Dev.IQ; credentials stored in the OS keychain. |
| `.vscode/settings.json` | VS Code workspace settings pointing Copilot Chat at `.github/skills/` for prompt files and `hooks/hooks.json` for hook files. |
| `.vscode/MCP.md` | MCP server setup guide — security boundary explanation, credential storage policy, and server configuration instructions. |

---

## scripts/

| File | Purpose |
|------|---------|
| `scripts/bootstrap.sh` | Bash bootstrap installer — creates the hooks, symlinks, and config files for `trial`, `committed`, or preset modes; supports `--graduate` and `--uninstall`. |
| `scripts/bootstrap.ps1` | PowerShell bootstrap installer — identical behavior to `bootstrap.sh` for Windows environments. |
| `scripts/validate-skills.sh` | Validates YAML frontmatter in all `SKILL.md` and agent `.md` files; dependency-free (bash + awk); exits 0 on success, 1 on failures. |

---

## hooks/

| File | Purpose |
|------|---------|
| `hooks/hooks.template.json` | Source template for `hooks/hooks.json` — bootstrap replaces `{{PACK_ROOT}}` with the absolute pack root path when rendering. |
| `hooks/config/README.md` | Placeholder for hooks config documentation to be added in a future session. |
| `hooks/config/skill-improve.config.json` | Hindsight Hooks configuration — enables/disables the retrospective refinement system and lists the customization roots to scan. |
| `hooks/state/dismissed-lessons.json` | Runtime state file tracking correction lessons that have been dismissed so they are not re-surfaced each session. |
| `hooks/state/edit-frequency.json` | Runtime state file tracking how often each file is edited, used by the Hindsight system to weight correction patterns. |
| `hooks/state/.gitignore` | Ensures runtime hook state files are not committed (the state files themselves are gitignored). |
| `hooks/logs/.gitkeep` | Empty placeholder keeping the `hooks/logs/` directory tracked so the log directory exists on fresh installs. |

### hooks/scripts/

| File | Purpose |
|------|---------|
| `skill-improve-detect.sh` | PostToolUse hook (bash) — detects correction edits by comparing tool output against session history heuristics. |
| `skill-improve-detect.ps1` | PostToolUse hook (PowerShell) — Windows equivalent of `skill-improve-detect.sh`. |
| `skill-improve-apply.sh` | Bash script that outputs dismissed correction lessons as agent context on demand, callable mid-session. |
| `skill-improve-apply.ps1` | PowerShell equivalent of `skill-improve-apply.sh`. |
| `skill-improve-reflect.sh` | Bash script that analyses a session log file and outputs a human-readable summary of detected corrections. |
| `skill-improve-reflect.ps1` | PowerShell equivalent of `skill-improve-reflect.sh`. |
| `skill-improve-session-start.sh` | Session-start hook (bash) — loads past correction lessons and outputs them as context for the agent at the beginning of each session. |
| `skill-improve-session-start.ps1` | PowerShell equivalent of `skill-improve-session-start.sh`. |
| `skill-improve-session-end.sh` | Stop hook (bash) — consolidates the session log, promotes repeated correction patterns, and updates `edit-frequency.json`. |
| `skill-improve-session-end.ps1` | PowerShell equivalent of `skill-improve-session-end.sh`. |
| `track-telemetry.sh` | Bash script that writes DI Hindsight events to a local log file or an external webhook endpoint. |
| `track-telemetry.ps1` | PowerShell equivalent of `track-telemetry.sh`. |

### hooks/scripts/lib/

| File | Purpose |
|------|---------|
| `correction-signatures.sh` | Bash library sourced by detect and session-end scripts — heuristics for identifying whether a tool edit is a correction to prior AI output. |
| `correction-signatures.ps1` | PowerShell equivalent of `correction-signatures.sh`. |
| `json-utils.sh` | Bash JSON helper library for Hindsight Hooks — uses `jq` when available, falls back to portable bash parsing; all functions exit 0 on error. |
| `json-utils.ps1` | PowerShell JSON helper library using `ConvertFrom-Json` / `ConvertTo-Json` — all functions return `$null` on error. |

---

## docs/

| File | Purpose |
|------|---------|
| `docs/reference.md` | Full technical reference documentation for the Dev.IQ Agent Pack — skills, configuration, maturity tiers, and architecture. |
| `docs/trial-install-guide.md` | Step-by-step personal trial install guide covering both VS Code and Visual Studio 2022 in under 20 minutes, invisible to the team until graduated. |
| `docs/colleague-welcome.md` | Getting-started guide written for a new team member joining a workspace where Dev.IQ is already installed (UPS trial audience). |
| `docs/demo-script.md` | Facilitated 30–40 minute live demo script for presenting Dev.IQ to a tech lead and developer team inside the IDE. |
| `docs/pitch-developers.md` | Four-minute developer-facing pitch document explaining Dev.IQ's value without requiring an install. |

---

## tests/

| File | Purpose |
|------|---------|
| `tests/.gitignore` | Keeps the `tests/` directory tracked in git while allowing test output and generated fixtures to be excluded. |
