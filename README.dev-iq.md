# Dev.IQ

> The capability layer for developer delivery intelligence. DI-grounded skills,
> instructions, modes, and tools that turn GitHub Copilot Chat **and**
> Claude Code into a delivery-aware engineering partner inside the IDE.

**Version**: v0.1.0
**Status**: Internal Sparq asset — Intelligence Studio
**Owner**: [Owner Name]
**Repo**: [repo link]

---

## What This Is

This pack drops into a client codebase and gives the development team an
opinionated, DI-grounded layer over **GitHub Copilot Chat and Claude Code**
in VS Code (and any other `AGENTS.md`-aware tooling: Codex CLI, Cursor,
Aider). It is *not* a SaaS product. It is *not* a runtime. It is a
versioned set of files — markdown, YAML, JSON — that lives in the repo
and is owned by the team.

The pack operationalizes Sparq's **Developer Intelligence (DI)** framework:

- The five-layer signal model (Intent → Design → Quality → Risk → Confidence)
  is loaded as the AI's reasoning lens on every interaction.
- 21 skills cover the developer lifecycle: requirements, design, development,
  code review, and deployment readiness.
- A Dev.IQ agent provides delivery-aware coaching and execution.
- MCP wiring connects to ADO or Jira and to GitHub for first-class
  bidirectional context.

DI is the operating model. Dev.IQ is how teams *act* on it —
without ever becoming a tooling pitch.

> **Relationship to Assert.IQ:**
> Dev.IQ and Assert.IQ are complementary products within Sparq's Intelligence
> Studio. Assert.IQ owns the QE lifecycle (testing, defects, quality signals).
> Dev.IQ owns the developer lifecycle (requirements, design, code, deployment).
> They share the same pack architecture and can be installed independently or
> together for full SDLC coverage.

---

## Dual-Target: Copilot and Claude Code

The pack ships one canonical copy of every asset and exposes it through both
tools' native config surfaces. There is no duplicated content — only thin
entry-point files (`CLAUDE.md`, `AGENTS.md`, `.claude/agents/*`) plus a
short installer that wires `.claude/settings.json` and the skills symlink.

| Asset | Canonical location | Copilot reads | Claude reads |
|---|---|---|---|
| Always-on guidance | `.github/copilot-instructions.md` + mirrored body in `CLAUDE.md` | `.github/copilot-instructions.md` | `CLAUDE.md` |
| Scoped instructions | `.github/instructions/*.instructions.md` | same (auto via `applyTo`) | same (via `@`-imports in `CLAUDE.md`) |
| Skills | `.github/skills/*/SKILL.md` | `.github/skills/` directly | `.claude/skills/` (symlink → `.github/skills/`) |
| Agents | `.github/agents/Dev-IQ.agent.md` + `Dev-IQ-PLAN.agent.md` (Copilot) + `.claude/agents/dev-iq.md` + `dev-iq-plan.md` (Claude) | agent files | subagent files |
| Hooks | `hooks/hooks.json` + `hooks/scripts/` | yes | `.claude/settings.json` (hooks block) |
| MCP wiring | `.vscode/mcp.json` | yes | yes |
| Per-client config | `.dev-iq/*` | yes | yes |
| Generic agent pointer | `AGENTS.md` | n/a | read by Codex CLI / Cursor / Aider |

**After dropping the pack into a repo, run the installer once:**

```bash
bash install.sh        # macOS / Linux
.\install.ps1          # Windows PowerShell
```

The installer is idempotent. It (1) syncs `hooks.json` into
`.claude/settings.json` and (2) creates `.claude/skills` as a symlink to
`../.github/skills`.

---

## The Developer Intelligence (DI) Signal Model

Every skill in this pack reasons through the five DI signal layers:

```
SIGNAL        QUESTION                    DATA SOURCE (GENERIC)
──────────────────────────────────────────────────────────────────
INTENT    →   What are we building?       Work items, AC, PRDs, Design docs
DESIGN    →   Is it built right?          Git Diff, AST, Architecture docs
QUALITY   →   Is it production-ready?     Test results, Coverage, Lint/SAST
RISK      →   What could break?           Deps, Schema changes, API contracts
CONFIDENCE→   Should we proceed?          Synthesis of above (Phase 2)
```

Each signal maps to a **threshold action**:

| Tier | 🟢 Green | 🟡 Yellow | 🔴 Red |
|------|----------|-----------|--------|
| **Early** | Proceed with AI guidance | Human review + coaching note | Block + coaching report |
| **Mid** | Auto-proceed | Human review required | Block + diagnostic report |
| **Higher** | Fully autonomous | Auto-assign senior reviewer | Block + auto-rollback suggestion |

Maturity tier is set during the DI Diagnostic and re-evaluated quarterly.

---

## Pack Structure

```
dev-iq/
│
├── CLAUDE.md                              # Always-on guidance for Claude Code
├── AGENTS.md                              # Always-on for Codex CLI / Cursor / Aider
├── install.sh                             # macOS / Linux installer
├── install.ps1                            # Windows installer
├── MANIFEST.md                            # Inventory of all pack files
│
├── .github/
│   ├── copilot-instructions.md            # Always-on guidance for Copilot
│   ├── instructions/
│   │   ├── di-foundation.instructions.md
│   │   ├── di-code-standards.instructions.md
│   │   ├── di-security.instructions.md
│   │   ├── di-signal-emission.instructions.md
│   │   └── di-traceability.instructions.md
│   ├── skills/                            # Canonical skill location
│   │   ├── dev-iq-bootstrap/
│   │   ├── generate-user-stories/
│   │   ├── review-acceptance-criteria/
│   │   ├── identify-dependencies/
│   │   ├── design-api/
│   │   ├── design-data-model/
│   │   ├── generate-adr/
│   │   ├── review-architecture/
│   │   ├── scaffold-feature/
│   │   ├── code-review/
│   │   ├── debug-issue/
│   │   ├── refactor-code/
│   │   ├── review-security/
│   │   ├── explain-code/
│   │   ├── review-pr-readiness/
│   │   ├── blast-radius-estimator/
│   │   ├── review-dependencies/
│   │   ├── new-pull-request/
│   │   ├── generate-release-notes/
│   │   ├── review-deployment-readiness/
│   │   ├── generate-rollback-plan/
│   │   └── generate-traceability-matrix/
│   └── agents/
│       ├── Dev-IQ.agent.md                # Action agent
│       └── Dev-IQ-PLAN.agent.md           # Plan-first agent
│
├── .claude/
│   ├── agents/
│   │   ├── dev-iq.md                      # Claude Code subagent
│   │   └── dev-iq-plan.md                 # Claude Code plan-first subagent
│   ├── settings.json                      # Hooks wiring for Claude Code
│   └── skills/                            # Symlink → ../.github/skills/
│
├── .vscode/
│   ├── MCP.md                             # Per-server setup guide
│   ├── mcp.json                           # MCP server wiring
│   └── settings.json                      # VS Code settings
│
├── hooks/
│   ├── config/
│   │   ├── README.md
│   │   └── skill-improve.config.json
│   ├── logs/
│   │   └── skill-improve.log
│   ├── scripts/
│   │   ├── lib/
│   │   │   ├── correction-signatures.ps1 + .sh
│   │   │   └── json-utils.ps1 + .sh
│   │   ├── skill-improve-apply.ps1 + .sh
│   │   ├── skill-improve-detect.ps1 + .sh
│   │   ├── skill-improve-reflect.ps1 + .sh
│   │   ├── skill-improve-session-end.ps1 + .sh
│   │   ├── skill-improve-session-start.ps1 + .sh
│   │   └── track-telemetry.ps1 + .sh
│   ├── state/
│   │   ├── .last-janitor
│   │   ├── dismissed-lessons.json
│   │   └── edit-frequency.json
│   └── hooks.template.json
│
├── scripts/
│   ├── bootstrap.sh                       # Workspace bootstrapper (macOS/Linux)
│   └── bootstrap.ps1                      # Workspace bootstrapper (Windows)
│
├── tests/
│   └── .gitignore
│
└── .dev-iq/                               # Per-client config
    ├── config.yaml                        # Maturity tier, tracker, framework
    ├── maturity-profile.md                # Tier rationale
    ├── governance.md                      # Compliance posture
    ├── telemetry-overlay.md               # Generic signals + client data sources
    └── CHANGELOG.md                       # Version history
```

---

## The Four Layers of the Pack

```
LAYER          PRIMITIVE                                  ROLE
─────────      ─────────────────────────────────          ──────────────────────────
Foundation     .github/copilot-instructions.md            Always-on DI guidance
               .github/instructions/*.instructions.md     (loaded automatically;
               CLAUDE.md                                   Claude reads CLAUDE.md)

Skills         .github/skills/<name>/SKILL.md             Invokable workflows
               (mirrored read-only at .claude/skills/)    (called via /skill-name)

Agents         .github/agents/Dev-IQ.agent.md             Default front-door agent
               .github/agents/Dev-IQ-PLAN.agent.md        Read-only planning sibling
               .claude/agents/dev-iq{,-plan}.md            Claude Code subagents

Tools          .vscode/mcp.json                           External integrations
                                                          (ADO, Jira, GitHub)

Hooks          hooks/hooks.json + hooks/scripts/          Session-end skill
               (wired via .vscode/settings.json and        refinement + telemetry
               .claude/settings.json)
```

---

## Quick Start

### 1. Drop the Pack into the Client Repo

Copy these into the repo root:
- `MANIFEST.md`
- `README.dev-iq.md`
- `CLAUDE.md` + `AGENTS.md`
- `.github/copilot-instructions.md`
- `.github/instructions/`
- `.github/skills/`
- `.github/agents/`
- `.claude/`
- `.vscode/mcp.json` + `.vscode/settings.json`
- `hooks/`
- `scripts/`
- `.dev-iq/`

### 2. Configure for the Client Context

Open `.dev-iq/config.yaml` and set:
- `client.name`
- `maturity.tier` — `early`, `mid`, or `higher` based on DI Diagnostic
- `tracker.type` — `ado` or `jira`
- `vcs.type` — `github`, `ado-repos`, `gitlab`, or `bitbucket`
- `language` — primary language(s)

Open `.dev-iq/maturity-profile.md` and document the rationale for the chosen tier.

### 3. Configure the Telemetry Overlay (Client-Specific)

Open `.dev-iq/telemetry-overlay.md` and map each DI signal to your
client's actual data sources:

```yaml
signals:
  intent:
    source: ado                          # ado | jira | linear | github-issues
    work_item_types: [User Story, Task]
  design:
    architecture_docs: docs/architecture/
    pattern_library: docs/patterns/
  quality:
    coverage_tool: sonarqube             # sonarqube | codecov | coveralls
    lint_tool: eslint                    # eslint | pylint | rubocop
  risk:
    dependency_file: package.json        # package.json | requirements.txt | pom.xml
    schema_path: db/migrations/
```

### 4. Wire MCP

Open `.vscode/mcp.json` and confirm the servers for your tracker and VCS
are enabled. Provide the required PATs / API tokens at input prompts.

### 5. Bootstrap the Workspace

```
@Dev-IQ help me onboard this repo
```
or directly:
```
/dev-iq-bootstrap
```

### 6. Validate

```
/code-review
```

The agent should respond with a DI five-layer assessment of the current
branch diff.

---

## The Skill Registry

Skills are organized by developer lifecycle phase. All skills are invoked
in Copilot Chat with `/skill-name`. Maturity gating is enforced by each
skill that requires it.

### Requirements

| Skill | DI Signal | Purpose |
|-------|-----------|---------|
| `/generate-user-stories` | INTENT | Convert requirements to stories with AC |
| `/review-acceptance-criteria` | INTENT | Review ACs for completeness and clarity |
| `/identify-dependencies` | RISK | Surface blockers and cross-team dependencies |

### Design

| Skill | DI Signal | Purpose |
|-------|-----------|---------|
| `/design-api` | DESIGN | RESTful API design from requirements |
| `/design-data-model` | DESIGN | Entity/database design from stories |
| `/generate-adr` | DESIGN | Architecture Decision Record generation |
| `/review-architecture` | DESIGN + RISK | Architecture review through DI lens |

### Development

| Skill | DI Signal | Purpose |
|-------|-----------|---------|
| `/scaffold-feature` | INTENT + DESIGN | Generate boilerplate from AC + story |
| `/code-review` | DESIGN + QUALITY | Review code through DI five-layer lens |
| `/debug-issue` | RISK + QUALITY | Structured bug diagnosis + fix suggestion |
| `/refactor-code` | DESIGN + QUALITY | Refactoring suggestions with rationale |
| `/review-security` | QUALITY + RISK | Security-focused code review |
| `/explain-code` | INTENT | Plain-language code explanation |

### Code Review / PR

| Skill | DI Signal | Purpose |
|-------|-----------|---------|
| `/review-pr-readiness` | RISK + QUALITY | Go/Hold/Discuss verdict |
| `/blast-radius-estimator` | RISK | Map downstream impact of a change |
| `/review-dependencies` | RISK | Dependency change risk analysis |
| `/new-pull-request` | INTENT + RISK | PR body with DI risk band + traceability |

### Deployment

| Skill | DI Signal | Purpose |
|-------|-----------|---------|
| `/generate-release-notes` | INTENT | Release notes from commits/PRs |
| `/review-deployment-readiness` | QUALITY + RISK | Go/No-Go deployment checklist |
| `/generate-rollback-plan` | RISK | Rollback steps from deployment context |

### Cross-Cutting

| Skill | DI Signal | Purpose |
|-------|-----------|---------|
| `/generate-traceability-matrix` | INTENT + DESIGN | Req ↔ Code ↔ Test matrix |
| `/dev-iq-bootstrap` | — | Workspace bootstrapper |

> **Testing skills are covered by Assert.IQ.**
> Install both packs together for full SDLC + QE coverage.

---

## Maturity Awareness

The pack reads `.dev-iq/maturity-profile.md` and adjusts behavior:

| Tier | Behavior |
|------|----------|
| **Early** | Foundation + intent + design review only. Risk assessment operates in advisory mode. All outputs are drafts with coaching notes. Human review required for every output. |
| **Mid** | Add quality signals, automated code review, PR readiness in suggest-only mode. DI routing operates as designed. Risk assessment provides structured reports. |
| **Higher** | Full pack including blast radius estimation, autonomous PR readiness verdict, and predictive deployment risk. Confidence signal available (Phase 2). |

---

## The Feedback Loop

Skills improve from production experience. When a DI signal issues a
**High Confidence** outcome but a production incident still occurs:

```
1. Post-Mortem Skill Audit is triggered
2. Skill author analyzes why the signal missed
3. Prompt template is updated with new constraint or example
4. Skill is returned to REVIEW status
5. Updated skill re-enters approval workflow
```

**Ownership:**

| Role | Responsibility |
|------|---------------|
| Primary | Skill author |
| Fallback | Team Lead / Competency Council |
| Escalation | Pack Maintainer |

---

## Governance & Guardrails

| Concern | Control |
|---------|---------|
| AI-generated code merged without review | `@di-review-required` header on every skill output |
| Skills applied at wrong maturity | Maturity tier gate in every applicable skill |
| Client-specific data in generic prompts | Telemetry overlay separates generic from client-specific |
| Vendor lock-in | Markdown / YAML / JSON only — portable across LLM IDE tools |
| Secrets in prompts | Mask rule in foundation instructions |
| Hallucinated traceability | Trace must reference a real work item resolvable via MCP |
| Compliance violations | `governance.md` defines client compliance posture |
| Feedback loop ownership gaps | Three-tier ownership (Author → Team Lead → Pack Maintainer) |

Every skill includes an explicit **Governance** section.

---

## Customization

| Need | Where |
|------|-------|
| Change language/framework | `.dev-iq/config.yaml` → `language` |
| Switch tracker (ADO ↔ Jira) | `.dev-iq/config.yaml` + `.vscode/mcp.json` |
| Adjust maturity tier | `.dev-iq/config.yaml` + `.dev-iq/maturity-profile.md` |
| Add client telemetry | `.dev-iq/telemetry-overlay.md` |
| Add a domain skill | New folder under `.github/skills/<name>/` with `SKILL.md` |
| Adjust code standards | `.github/instructions/di-code-standards.instructions.md` |
| Adjust security rules | `.github/instructions/di-security.instructions.md` |

### Adding a New Skill

1. Create `.github/skills/your-skill/SKILL.md` with:
   - YAML frontmatter: `name`, `description`, `di_signal`, `maturity_required`
   - `## Overview`
   - `## When to Use`
   - `## Instructions`
   - `## Inputs Required`
   - `## Output Format`
   - `## Examples`
   - `## Governance`
2. Add supporting templates or references to the same folder
3. Update the skill registry in this README
4. Update `MANIFEST.md`
5. Claude Code picks up the skill automatically via the `.claude/skills/` symlink

---

## Troubleshooting

**The skill can't find the work item.**
Confirm MCP is wired (`.vscode/mcp.json`) and the PAT has read access. Test
with a minimal MCP query directly.

**Generated code doesn't match our conventions.**
Update `.github/instructions/di-code-standards.instructions.md` with
explicit examples of your project's patterns.

**Risk assessment feels off.**
Adjust signal weighting in `.github/skills/review-pr-readiness/SKILL.md`.
Each DI layer is independently tunable.

**Skill outputs feel generic.**
The pack relies on instructions files for project-specific shape. Update
`di-code-standards.instructions.md` or `di-traceability.instructions.md`
with real examples from your codebase.

**Client telemetry not mapping correctly.**
Check `.dev-iq/telemetry-overlay.md` — ensure each signal's source
matches your actual tools and file paths.

---

## What Dev.IQ Is Not

- It is not a runtime. There is no service to deploy.
- It is not a SaaS. The client owns the files; if Sparq rotates off the
  account, the pack stays.
- It is not a replacement for engineering judgment. Every output is a
  draft; human review is required.
- It is not a replacement for Assert.IQ. Use both packs together for full
  SDLC + QE coverage.
- It is not a tooling pitch. Use it where the maturity supports it. Lead
  with DI thinking, not with this pack.

---

## Versioning

| Version | Notes |
|---------|-------|
| 0.1.0 | Initial release. DI five-layer signal model. Pack structure established. 21-skill registry defined. Foundation, instructions, and core developer skills. |

Tag releases. Keep a CHANGELOG in `.dev-iq/CHANGELOG.md`.

---

## Dev.IQ + Assert.IQ — Sparq Intelligence Studio

```
┌─────────────────────────────────────────────────────────────────┐
│                   SPARQ INTELLIGENCE STUDIO                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────────────────────┐  ┌──────────────────────────┐   │
│   │         DEV.IQ           │  │       ASSERT.IQ           │   │
│   │  Developer Intelligence  │  │  Quality Intelligence     │   │
│   │                          │  │                           │   │
│   │  Requirements            │  │  Plan                     │   │
│   │  Design                  │  │  Develop (testing)        │   │
│   │  Development             │  │  Review                   │   │
│   │  Code Review / PR        │  │  Execute                  │   │
│   │  Deployment              │  │  Learn                    │   │
│   │                          │  │                           │   │
│   │  Primary: Developers     │  │  Primary: QE Engineers    │   │
│   │  Signal: DI (5 layers)   │  │  Signal: QI (4 layers)   │   │
│   └──────────────────────────┘  └──────────────────────────┘   │
│                                                                  │
│   Same pack architecture. Same hooks. Same MCP wiring.          │
│   Different roles. Different signals. Different skills.         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Ownership

| Role | Responsibility |
|------|---------------|
| Pack Technical Owner | [Your Name] |
| DI Framework Sponsor | [Name] |
| Pilot Account Lead | [Embedded Lead] |
| Governance Review | DI Sponsor + Sparq InfoSec |
| Versioning and Release | [Your Name] |
| Collaboration | Assert.IQ / Jarius Hayes |

---

## Where to Learn More

- Assert.IQ Agent Pack — the QE capability layer this pack complements
- Quality Intelligence Kit (Sparq internal) — the operating model that inspired DI
- DI Diagnostic Guide — how to set the right maturity tier
- Sparq Skills Library — human-readable prompts that informed these agent skills
