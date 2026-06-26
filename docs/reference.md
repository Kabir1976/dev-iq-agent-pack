# Dev.IQ

> The capability layer for developer delivery intelligence. DI-grounded skills,
> instructions, agents, and tools that turn GitHub Copilot Chat **and**
> Claude Code into a delivery-aware engineering partner inside the IDE.

**Version**: v0.11.0

---

## At a Glance

Dev.IQ is a set of markdown, YAML, and JSON files that bootstrap into a repo and give GitHub Copilot Chat and Claude Code a Developer Intelligence reasoning layer — 27 skills, two agents, and MCP wiring for ADO and GitHub — without deploying any runtime or service.

**Fastest path to first value:** extract the zip → run `bootstrap.sh --preset=solo` against your repo → open Copilot Chat → select Dev-IQ → run `/review-pr-readiness` on a branch with changes. Under 20 minutes, requires nothing beyond VS Code and Git.

**Skills work without MCP.** If Node.js isn't installed or credentials aren't configured, every skill that needs external data falls back to asking you to paste the content inline. Nothing is blocking.

---

## Prerequisites — What You Need

### Required

| Dependency | Minimum version | Notes |
|------------|-----------------|-------|
| VS Code | 1.99 | Host for Copilot Chat and MCP servers |
| GitHub Copilot Chat extension | v0.22 | Agent mode, skill invocation, custom agents. Check: `Help → About` |
| Git | Any recent | Branch detection, diff context for skills |
| dev-iq pack | v0.11.0 | Provided as a zip by your engagement lead |

> **Claude Code alternative:** Claude Code CLI works instead of or alongside Copilot Chat. Skills and agents behave identically. See `.claude/claude-readme.md` for Claude-specific setup.

### Optional — needed for live data pull

| Dependency | What it unlocks | Without it |
|------------|-----------------|------------|
| Node.js 18+ | All MCP servers (ADO, GitHub, filesystem) | Skills ask you to paste work item text and PR details manually |
| ADO Personal Access Token | Live work item + PR fetch for `/review-pr-readiness`, `/validate-acceptance-criteria`, `/estimate-effort`, `/generate-traceability` | You paste the work item when prompted |
| GitHub PAT | Live PR diff and repo context when `vcs.type: github` | Skills use the diff visible in your editor |

**Creating an ADO PAT:** ADO → top-right avatar → Personal access tokens → New Token.
Scopes needed: **Work Items (Read)**, **Code (Read)**, **Pull Request Threads (Read & Write)**.

**Credentials are never written to files.** VS Code stores them in your OS keychain on first prompt. The `${input:ADO_PAT}` syntax in `mcp.json` triggers this — nothing is committed.

### Windows checklist

Do these before running bootstrap. These are the most common blockers on corporate machines.

**1. PowerShell execution policy**
```powershell
Get-ExecutionPolicy -Scope CurrentUser
# If Restricted or AllSigned:
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```
If you get "Access denied", your machine is managed by Group Policy — speak to your IT contact.

**2. Unblock zip contents** (after extracting the zip)
```powershell
Get-ChildItem "C:\Tools\dev-iq" -Recurse | Unblock-File
```

**3. Developer Mode** (recommended, not required)
Settings → Privacy & security → For developers → Developer Mode On.
Enables directory symlinks without an admin shell. Without it, bootstrap falls back to copying skill files — safe but requires re-running after edits.

---

## What's Disabled in v0.11.0

These features are built and wired but explicitly turned off. The flag is in `.dev-iq/config.yaml` unless noted otherwise.

| Feature | Config flag | Status | Notes |
|---------|-------------|--------|-------|
| **Hindsight Hooks** | `hooks.hindsight_enabled: false` | Off by default | Hook scripts fire on session events but capture no patterns until enabled. Enable after verifying the pack is stable in your repo. |
| **Decision Confidence signal** | `signals.confidence.enabled: false` | Phase 2 — not built | Do not enable. Referenced in skill output format but not computed. Ships in a future release. |
| **Blast Radius full mode** | `blast_radius.enabled: false` | Disabled at Early maturity | The `/blast-radius-estimator` skill still runs in advisory mode. Full dependency-graph traversal requires `blast_radius.dependency_map_path` and Mid+ maturity. |
| **Auto-assign reviewer on Yellow** | `pr.auto_assign_on_yellow: false` | Off | Requires ADO/GitHub PAT with write access and Mid+ maturity. |
| **Signal emission to `.dev-iq/signals/`** | — | Planned for 0.11.0 | Skills don't yet write structured JSONL signal records. The directory doesn't exist yet. |
| **Webhook telemetry sink** | `hooks.telemetry_sink: local` | Local only | Signals written to local logs only. Set `telemetry_sink: webhook` and add a URL in `hooks.telemetry_webhook_url` to push externally. |

### MCP servers: what's active vs. disabled

**Active by default (3 servers):**

| Server | What it provides | Credential needed |
|--------|-----------------|-------------------|
| `azure-devops` | Live ADO work items, ACs, PR context | ADO PAT via `${input:ADO_PAT}` |
| `github` | PR diff, branch, repo context | GitHub PAT via `${input:GITHUB_PAT}` |
| `filesystem` | Workspace file tree read access (scoped to `${workspaceFolder}`) | None |

**Disabled — pre-configured in `_disabled_servers` in `.vscode/mcp.json`:**

To enable any of these, move the server block into the `mcpServers` object and supply credentials.

| Server | What it provides | Enable when |
|--------|-----------------|-------------|
| `jira` | Live Jira issues and sprints | `tracker.type: jira` in config.yaml — replaces `azure-devops` |
| `git` | Git log, blame, structured diff | Useful for `/blast-radius-estimator` and `/generate-release-notes` on complex histories |
| `sentry` | Error tracking and issue context | Useful for `/debug-issue` on production incidents |

See `.vscode/MCP.md` for step-by-step credential setup for each server.

---

## What This Is

This pack drops into a client codebase and gives the development team an
opinionated, DI-grounded layer over **GitHub Copilot Chat and Claude Code**
in VS Code (and any other `AGENTS.md`-aware tooling: Codex CLI, Cursor,
Aider). It is *not* a SaaS product. It is *not* a runtime. It is a
versioned set of files — markdown, YAML, JSON — that lives in the repo
and is owned by the team.

The pack operationalizes the **Developer Intelligence (DI)** framework:

- The four-layer signal model (Intent → Design → Quality → Risk → Decision Confidence)
  is loaded as the AI's reasoning lens on every interaction.
- 27 skills cover the developer lifecycle: requirements, design, development,
  code review, observability, AI integration, and deployment readiness.
- A Dev.IQ agent provides delivery-aware coaching and execution.
- MCP wiring connects to ADO or Jira and to GitHub for first-class
  bidirectional context.

DI is the operating model. Dev.IQ is how teams *act* on it —
without ever becoming a tooling pitch.

> **Relationship to Assert.IQ:**
> Dev.IQ and Assert.IQ are complementary packs. Assert.IQ owns the QE lifecycle
> (testing, defects, quality signals). Dev.IQ owns the developer lifecycle
> (requirements, design, code, deployment). They share the same pack architecture
> and can be installed independently or together for full SDLC coverage.

---

## Market Context: Why This Pack Exists

Three verified findings from 2025 primary research explain the problem Dev.IQ is built to solve.

**Developer trust is falling as adoption grows** (Stack Overflow 2025 Developer Survey, n=49,000+):

| Metric | 2024 | 2025 |
|---|---|---|
| AI tool usage | 76% | 84% |
| Combined trust in AI accuracy | 43% | 33% |
| Active distrust | 31% | **46%** |
| Positive favorability | 72% | 60% |

**Governance coverage lags adoption by 2:1** (IBM 2025 Cost of a Data Breach Report, ~600 orgs, first year tracking shadow AI as a distinct breach vector): only 37% of organizations have policies to manage AI tools or detect unsanctioned usage; of those, only 34% audit for shadow AI.

**Unstructured adoption shows null productivity gains in real-world conditions.** A peer-reviewed RCT (SSRN/Management Science 2025, 4,867 developers, Microsoft + Accenture + Fortune 100) found a 26% increase in completed tasks under structured adoption. A two-year longitudinal study at NAV IT (703 repos, 26,317 commits) found no statistically significant improvement without governance structure — same tools, different outcomes.

The trust gap, governance gap, and productivity variance are all addressed by the same thing: a structured, tiered reasoning layer that developers and organizations can trust.

---

## Enterprise Governance: Agent Autonomy Classification

Gartner's May 2026 research identifies four AI agent autonomy tiers — Observe,
Advise, Act with Approval, Act Autonomously — and states that applying uniform
governance across all four tiers is the primary cause of enterprise AI agent
failure. The prescription: governance controls must be proportionate to the
autonomy level of the specific agent.

Dev.IQ operates at the **Advise** and **Act with Approval** tiers only.
No skill operates at Act Autonomously. This is enforced by `governance.md`
(`allow_ai_merge_without_review: false`) and the `@di-review-required` marker
on all skill output.

### Skill autonomy tier mapping

| Gartner tier | What the agent does | Dev.IQ skills at this tier |
|---|---|---|
| **Observe** | Reads and surfaces information. No recommendations. | `explain-code`, `identify-dependencies`, `generate-traceability` |
| **Advise** | Makes recommendations. Human decides and acts. | `review-code`, `review-security`, `review-pr-readiness`, `review-architecture`, `validate-acceptance-criteria`, `refactor-code` *(plan phase)*, `blast-radius-estimator`, `estimate-effort`, `review-observability`, `review-ai-integration` |
| **Act with Approval** | Produces a complete artifact (code, plan, ADR). Developer reviews and applies manually. | `scaffold-feature`, `generate-adr`, `design-data-model`, `generate-rollback-plan`, `generate-release-notes`, `debug-issue`, `review-deployment-readiness`, `refactor-code` *(apply phase)*, `generate-openapi`, `onboard-codebase`, `dev-iq-tailor` |
| **Act Autonomously** | Takes action without human review. | **None** — prohibited by `governance.md` |

### What this means in practice

- No skill can merge a PR, write files to the codebase, or post comments to ADO/GitHub without the developer initiating the action.
- `scaffold-feature` outputs to the chat window — the developer pastes or applies. Nothing is written automatically.
- PR verdicts (Go / Hold / No-Go) are advisory. The human makes the merge decision in every case.
- The `@di-review-required` marker on every skill output is a formal signal that AI-generated content has not been human-reviewed yet, not a suggestion.

### Governance configuration for security teams

The controls that enforce this are in `.dev-iq/governance.md` in the client's repo:

```yaml
allow_ai_merge_without_review: false   # PR verdicts are advisory only
allow_new_dependencies: false          # No new packages without developer confirmation
mask_secrets_in_prompts: true          # Secrets never appear in skill I/O
compliance_posture: enterprise         # Skills refuse requests that violate this posture
```

These are not configurable per-session — they are read at skill load time and govern all skill behavior for the team.

---

## Dual-Target: Copilot and Claude Code

The pack ships one canonical copy of every asset and exposes it through both
tools' native config surfaces. There is no duplicated content — only thin
entry-point files (`CLAUDE.md`, `AGENTS.md`, `.claude/agents/*`) plus a
short installer that wires `.claude/settings.json` and the skills symlink.

| Asset | Canonical location | Copilot reads | Claude reads |
|---|---|---|---|
| Always-on guidance | `.github/copilot-instructions.md` + mirrored body in `CLAUDE.md` | `.github/copilot-instructions.md` | `CLAUDE.md` |
| Scoped instructions | `.github/instructions/*.instructions.md` | same (auto via `applyTo`) | same (via `@`-imports in `CLAUDE.md`; "When this applies" prose) |
| Skills (22) | `.github/skills/*/SKILL.md` | `.github/skills/` directly | `.claude/skills/` (symlink → `.github/skills/`) |
| Agents | `.github/agents/Dev-IQ.agent.md` + `Dev-IQ-PLAN.agent.md` (Copilot) + `.claude/agents/dev-iq.md` + `dev-iq-plan.md` (Claude) | agent files | subagent files |
| Hooks | `hooks/hooks.json` + `hooks/scripts/` | yes (via `chat.hookFilesLocations`) | `.claude/settings.json` (hooks block, synced by installer) |
| MCP wiring | `.vscode/mcp.json` | yes | yes (VS Code MCP is tool-agnostic) |
| Per-client config | `.dev-iq/*` | yes | yes |
| Generic agent pointer | `AGENTS.md` | n/a | read by Codex CLI / Cursor / Aider |

---

## Installation

The pack supports two install paths. Pick based on whether you're evaluating
Dev.IQ or deploying it into a team's repo.

### Path A — Try it on the pack folder itself

Best when you want to explore Dev.IQ without touching your team's repository.
Extract the pack zip, then run the bootstrap from inside the pack folder.

```bash
# macOS / Linux
cd path/to/dev-iq
bash scripts/bootstrap.sh --preset=solo

# Windows PowerShell
cd C:\Tools\dev-iq
powershell -File scripts\bootstrap.ps1 -Preset solo
```

What it does (all inside the pack folder):

- Renders `hooks/hooks.template.json` into `hooks/hooks.json` with the pack root absolute path baked in.
- Merges the rendered hooks block into `.claude/settings.json`, preserving any other keys.
- Creates `.claude/skills` as a symlink to `../.github/skills` so Claude Code discovers the same skills Copilot does (falls back to a copy on Windows without Developer Mode — re-run after edits in that case).

Idempotent on every platform — safe to re-run. Reverse with `--uninstall`.

### Path B — Install into your codebase

This is the real deployment path. Bootstrap copies the full set of workspace
surfaces into a target repo so Copilot Chat and Claude Code can discover the
skills, agents, instructions, hooks, and config from that codebase.

Run from a terminal in your target repo. No editor required:

```bash
# 1. Extract the pack zip somewhere on your machine (one time, anywhere)
#    e.g. ~/tools/dev-iq  or  C:\Tools\dev-iq on Windows

# 2. cd into YOUR repo
cd ~/code/my-app

# 3. Run the bootstrap pointing at the extracted pack
bash ~/tools/dev-iq/scripts/bootstrap.sh --mode=trial

# Windows PowerShell
powershell -File C:\Tools\dev-iq\scripts\bootstrap.ps1 -Mode trial
```

The script is fully standalone — it accepts `--preset=solo|pod`, prompts
interactively when run in a TTY, and writes everything Copilot and Claude need
into your workspace. You do not need to open VS Code or Claude Code first, and
`/dev-iq-bootstrap` does not need to be loaded — the script is what the skill
calls under the hood.

**What does `--preset=solo` do?** Solo sets trial mode (files are invisible to
git via `.git/info/exclude`) with no hooks. Use it when you're evaluating
Dev.IQ alone before sharing with the team. Graduate to committed at any time
with `--graduate`. Use `--preset=pod` if the team has already agreed to adopt
Dev.IQ and wants the files checked in.

Already have the pack loaded in your editor? You can also run
`/dev-iq-bootstrap` from Copilot Chat or Claude Code — same outcome,
chat-driven prompts.

### Presets

| Preset | What it configures | Best for |
|--------|--------------------|----------|
| `pod` | Committed + hooks | Cross-functional teams adopting DI together |
| `solo` | Trial, no hooks, instructions user-global | Individual contributor evaluating solo |
| `portable` | Committed mode, no hooks — minimal footprint | Client handoff or read-only install |

**Portable mode** installs files visibly into git (committed) without the hooks
directory. Use it when you want the team to be able to commit the pack but don't
need the session-end hook scripts.

```bash
bash ~/dev-iq/scripts/bootstrap.sh --preset=portable
# Reverse with: --uninstall
```

### Pinning to a version

v0.11.0 is a pre-release — no git tags have been cut yet. Use the zip provided
by your engagement lead, which is pinned to a specific commit. Once the repo
moves to tagged releases (v1.0.0+), bootstrap CLI flags, manifest schema, skill
names, and workspace surface layout will not change incompatibly without a
major-version bump.

---

## Distributing to Colleagues

Three options depending on your environment. For most corporate/restricted environments, Option 1 is the fastest path.

### Option 1 — Zip file (no internet required)

Create a clean zip from the pack and share via Teams, email, or SharePoint:

```bash
cd /path/to/dev-iq
git archive --format=zip --output=~/Desktop/dev-iq-v0.11.0.zip HEAD
```

`git archive` includes only committed files — no `.git` folder, no machine-specific files (`.claude/settings.local.json`, `hooks/hooks.json`, `.DS_Store`) are included. The result is exactly what a colleague needs to run bootstrap.

Colleagues receive the zip and follow [docs/trial-install-guide.md](trial-install-guide.md).

### Option 2 — GitHub collaborator (if colleagues have GitHub access)

Invite them to `github.com/Kabir1976/dev-iq`:

> GitHub → Settings → Collaborators → Add people

They clone once, then run bootstrap against their own repos. No zip needed; they get updates via `git pull`.

### Option 3 — Internal Git server (enterprise long-term)

If your organisation has an internal ADO or GitLab instance:

```bash
git remote add internal https://your-internal-git/dev-iq.git
git push internal main
```

Colleagues clone from the internal URL and run bootstrap as normal. Updates are pushed to the internal remote.

---

## What Bootstrap Delivers

Bootstrap copies the complete workspace surface into the target repo.
Copilot and Claude Code can't auto-discover skills or agents that aren't
physically present in the workspace, so all of them ship in.

| Surface | Why it's per-repo |
|---------|-------------------|
| `.dev-iq/config.yaml` | Maturity tier, tracker, language, signal sink — varies by repo. |
| `.dev-iq/governance.md` | Compliance posture — varies by client / regulatory regime. |
| `.dev-iq/maturity-profile.md` | Tier rationale — team-specific. |
| `.github/copilot-instructions.md` + `.github/instructions/di-*.instructions.md` | Copilot reads these only from the workspace; their `applyTo` globs scope to repo files. |
| `.github/skills/` | All 27 DI skills — Copilot Chat reads them from this workspace path. |
| `.github/agents/` | `Dev-IQ.agent.md` and `Dev-IQ-PLAN.agent.md` custom chat modes. |
| `.claude/agents/` | Claude Code subagent counterparts (`dev-iq.md`, `dev-iq-plan.md`). |
| `.claude/skills` | Symlink to `../.github/skills` (copy fallback on Windows without Developer Mode). |
| `CLAUDE.md` / `AGENTS.md` | Claude and other agent runners read these from the repo root. |
| `.vscode/settings.json` + `.vscode/mcp.json` | Wires VS Code Copilot; declares MCP servers. JSON deep-merged into any pre-existing settings — your values win on conflicts. |
| `hooks/` (scripts/, config/, hooks.json) | Hook scripts that fire on session events. `hooks.json` rendered at bootstrap time so paths resolve to workspace copies. |
| `.claude/settings.json` | Claude Code reads the hooks block from here. Bootstrap merges only the hooks key, preserving any other settings. |

### Trial vs Committed

| Mode | What happens | Reverse with |
|------|-------------|--------------|
| `--mode=trial` | Files land in workspace; paths added to `.git/info/exclude` (local-only). `.gitignore` untouched. | `--graduate` (promote) or `--uninstall` (remove) |
| `--mode=committed` | Files land in workspace and are visible to git. | `--uninstall` |
| `--mode=ask` (default in TTY) | Prompts interactively. Non-TTY falls back to `committed`. | — |

SHA256-compares before writing — pre-existing files are preserved, never
silently overwritten. Every install writes `.dev-iq/.install-manifest.json`
recording `{version, installed_at, mode, paths[]}`.

**Graduating from trial → committed:**

```bash
# macOS / Linux
scripts/bootstrap.sh --graduate

# Windows
powershell -File scripts\bootstrap.ps1 -Graduate

# Then commit the pack files:
git add .dev-iq .claude .github CLAUDE.md AGENTS.md
git commit -m "chore: adopt Dev.IQ agent pack"
```

**Removing the pack from a workspace:**

```bash
# macOS / Linux
scripts/bootstrap.sh --uninstall
scripts/bootstrap.sh --uninstall --dry-run  # preview without changing anything

# Windows
powershell -File scripts\bootstrap.ps1 -Uninstall
powershell -File scripts\bootstrap.ps1 -Uninstall -DryRun
```

---

## Upgrading to a New Release

Upgrades are explicit and intentional:

1. Read the release notes on the Releases page and any migration notes.
2. Uninstall the current path you used:
   - Path A: `bash scripts/bootstrap.sh --uninstall` in the cloned pack.
   - Path B: `bash scripts/bootstrap.sh --uninstall` in each target repo.
3. `git pull` (or re-clone) to the new tag, then re-run the same path to refresh.

---

## Platform Notes (`.claude/skills` symlink)

The installer creates `.claude/skills` as a directory symlink to
`../.github/skills/`, so Copilot and Claude share one canonical copy of the
27 skills. Behavior varies by platform:

| Platform | What happens | What you need to do |
|----------|-------------|---------------------|
| macOS / Linux | Symlink created normally. | Nothing — edits to either path reflect instantly. |
| Windows + Developer Mode (or admin shell) | Symlink created normally. | Enable Developer Mode once: Settings → Privacy & security → For developers → Developer Mode On. Then re-run `bootstrap.ps1`. |
| Windows without Developer Mode / admin | Installer falls back to copying `.github/skills/` → `.claude/skills/` and logs the fallback. | Re-run `bootstrap.ps1` after editing any skill so Claude sees the change. Prefer Developer Mode to avoid drift. |
| CI runners, Docker COPY, manual zip downloads | Symlinks may not be preserved — you may get a broken link or a copy. | Run `scripts/bootstrap.sh` after checkout to repair the link. |

The installer is idempotent on every platform — re-running is always safe.

---

## The Developer Intelligence (DI) Signal Model

Every skill in this pack reasons through four DI signal layers:

```
SIGNAL        QUESTION                    DATA SOURCE (GENERIC)
──────────────────────────────────────────────────────────────────
INTENT    →   What are we building?       Work items, AC, PRDs, Design docs
DESIGN    →   Is it built right?          Git diff, AST, Architecture docs
QUALITY   →   Is it production-ready?     Test results, Coverage, Lint/SAST
RISK      →   What could break?           Deps, Schema changes, API contracts
              ─────────────────
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
│   │   ├── validate-acceptance-criteria/
│   │   ├── identify-dependencies/
│   │   ├── design-api/
│   │   ├── design-data-model/
│   │   ├── generate-adr/
│   │   ├── review-architecture/
│   │   ├── scaffold-feature/
│   │   ├── review-code/
│   │   ├── debug-issue/
│   │   ├── refactor-code/
│   │   ├── review-security/
│   │   ├── explain-code/
│   │   ├── review-pr-readiness/
│   │   ├── blast-radius-estimator/
│   │   ├── review-dependencies/
│   │   ├── create-pull-request/
│   │   ├── generate-release-notes/
│   │   ├── review-deployment-readiness/
│   │   ├── generate-rollback-plan/
│   │   └── generate-traceability/
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
└── .dev-iq/                               # Per-client config (created by bootstrap)
    ├── config.yaml                        # Maturity tier, tracker, framework
    ├── maturity-profile.md                # Tier rationale
    ├── governance.md                      # Compliance posture
    ├── telemetry-overlay.md               # Signal → data source mapping
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

## How to Use

### Invoking a skill

Open Copilot Chat in VS Code (or Claude Code). Type `/` to see available skills.
Type the skill name to invoke. Provide inputs when prompted, or skip if the skill
can resolve them from context (work item from branch name, scope from current
diff, etc.).

### Using the Dev-IQ agents

Pick **Dev-IQ** from the agent dropdown for default behavior — it routes to the
right skill and has full tools to act. Pick **Dev-IQ-PLAN** when you want
plan-first behavior on a larger or riskier task; it produces a plan and surfaces
a **Start Implementation** handoff button that switches back to Dev-IQ for
execution. Both agents are maturity-aware: they adjust recommendations based on
`maturity.tier` and proactively raise traceability gaps, design issues on
changed surfaces, and governance concerns when AI is applied to high-risk areas.

### Combining skills

Skills compose. A typical PR-time workflow:

```
/estimate-effort                → size the work before you start
/design-api                     → design the interface
/scaffold-feature               → generate boilerplate
/review-code                    → four-layer review
/review-pr-readiness            → Go/Hold verdict before opening PR
/create-pull-request               → PR body with DI risk band + traceability
```

A typical incident-driven workflow:

```
/debug-issue                    → structured diagnosis + fix suggestion
/review-security                → confirm the fix doesn't introduce new exposure
/blast-radius-estimator         → map what else could be affected
/review-deployment-readiness    → Go/No-Go before pushing the fix
/generate-rollback-plan         → have a plan before you deploy
```

### Configure for your client context

Open `.dev-iq/config.yaml` and set:

- `client.name`
- `maturity.tier` — `early`, `mid`, or `higher` based on the DI Diagnostic
- `tracker.type` — `ado` or `jira`, plus connection details
- `vcs.type` — `github`, `ado-repos`, `gitlab`, or `bitbucket`
- `language` — primary language(s)

Open `.dev-iq/maturity-profile.md` and document the rationale for the chosen tier.

### Wire the telemetry overlay

Open `.dev-iq/telemetry-overlay.md`. It contains five tables — one per DI signal layer — mapping each signal to your client's actual data sources. Fill in the `Value` column for each field that applies; leave fields blank if the tool isn't in use (the agent marks that signal UNGRADED rather than fabricating data).

Example fields you'll fill in:

| Signal | Field | Example value |
|--------|-------|---------------|
| INTENT | Tracker | `ado` |
| INTENT | Base URL | `https://dev.azure.com/my-org` |
| QUALITY | Coverage tool | `sonarqube` |
| QUALITY | SAST tool | `snyk` |
| RISK | Primary dependency file | `package.json` |
| RISK | Schema / migration path | `db/migrations/` |

Or attach the file to Copilot Chat and say: "Customize this telemetry overlay for my codebase and stack." The agent asks targeted questions and fills the blanks.

### Validate

In Copilot Chat, select the Dev-IQ agent and run:

```
/review-code
```

The agent should respond with a four-layer DI assessment of the current branch
diff. If MCP is wired correctly, it will pull live work item data; if not, it
will ask for it.

### Pick a starter skill for the team

Recommended first invocations:

- **Requirements phase**: `/validate-acceptance-criteria` on a recent work item
- **Development phase**: `/review-code` on the current branch
- **PR phase**: `/review-pr-readiness` before opening the PR

---

## The Skill Registry

Skills are organized by developer lifecycle phase. All skills are invoked
in Copilot Chat with `/skill-name`. Maturity gating is enforced by each
skill that requires it.

### Requirements

| Skill | DI Signal | Purpose |
|-------|-----------|---------|
| `/validate-acceptance-criteria` | INTENT | Review ACs for completeness and clarity |
| `/identify-dependencies` | RISK | Surface blockers and cross-team dependencies |
| `/estimate-effort` | INTENT + DESIGN | Story-point / t-shirt estimate with rationale |

### Design

| Skill | DI Signal | Purpose |
|-------|-----------|---------|
| `/design-api` | DESIGN | RESTful API design from requirements |
| `/design-data-model` | DESIGN | Entity/database design from stories |
| `/generate-adr` | DESIGN | Architecture Decision Record generation |
| `/review-architecture` | DESIGN + RISK | Architecture review through DI lens |
| `/generate-openapi` | DESIGN | OpenAPI 3.x spec from controller/router code |

### Development

| Skill | DI Signal | Purpose |
|-------|-----------|---------|
| `/scaffold-feature` | INTENT + DESIGN | Generate boilerplate from AC + story |
| `/review-code` | DESIGN + QUALITY | Review code through DI four-layer lens |
| `/debug-issue` | RISK + QUALITY | Structured bug diagnosis + fix suggestion |
| `/refactor-code` | DESIGN + QUALITY | Refactoring suggestions with rationale |
| `/review-security` | QUALITY + RISK | Security-focused code review |
| `/explain-code` | INTENT | Plain-language code explanation |
| `/review-observability` | QUALITY | Logging, metrics, tracing, and alerting coverage |
| `/review-ai-integration` | QUALITY + RISK | OWASP LLM Top 10 review for LLM/agentic code |

### Code Review / PR

| Skill | DI Signal | Purpose |
|-------|-----------|---------|
| `/review-pr-readiness` | RISK + QUALITY | Go/Hold/Discuss verdict |
| `/blast-radius-estimator` | RISK | Map downstream impact of a change |
| `/review-dependencies` | RISK | Dependency change risk analysis |
| `/create-pull-request` | INTENT + RISK | PR body with DI risk band + traceability |

### Deployment

| Skill | DI Signal | Purpose |
|-------|-----------|---------|
| `/generate-release-notes` | INTENT | Release notes from commits/PRs |
| `/review-deployment-readiness` | QUALITY + RISK | Go/No-Go deployment checklist |
| `/generate-rollback-plan` | RISK | Rollback steps from deployment context |

### Cross-Cutting

| Skill | DI Signal | Purpose |
|-------|-----------|---------|
| `/generate-traceability` | INTENT + DESIGN | Req ↔ Code ↔ Test matrix |
| `/dev-iq-bootstrap` | — | Workspace bootstrapper |
| `/onboard-codebase` | INTENT | New developer guide from repo structure |
| `/dev-iq-tailor` | DESIGN | Tailor pack config to this codebase |

> **Testing skills are covered by Assert.IQ.**
> Install both packs together for full SDLC + QE coverage.

---

## Maturity Awareness

The pack reads `.dev-iq/maturity-profile.md` and adjusts behavior:

| Tier | Behavior |
|------|----------|
| **Early** | Foundation + intent + design review only. Risk assessment operates in advisory mode. All outputs are drafts with coaching notes. Human review required for every output. |
| **Mid** | Add quality signals, automated code review, PR readiness in suggest-only mode. DI routing operates as designed. Risk assessment provides structured reports. |
| **Higher** | Full pack including blast radius estimation, autonomous PR readiness verdict, and predictive deployment risk. Decision Confidence signal available (Phase 2). |

Maturity is set during the DI Diagnostic and re-evaluated quarterly.

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
| Change telemetry sink | `.dev-iq/config.yaml` → `signals.sink` |

### Adding a New Skill

1. Create `.github/skills/your-skill/SKILL.md` with:
   - YAML frontmatter: `name`, `description`, `di_signal`, `maturity_required`
   - `## Overview`, `## When to Use`, `## Instructions`, `## Inputs Required`, `## Output Format`, `## Governance`
2. Add supporting templates or references to the same folder.
3. Update the skill registry in `docs/reference.md`.
4. Claude Code picks up the skill automatically via the `.claude/skills/` symlink — no second copy needed.

---

## Troubleshooting

**The skill can't find the work item.**
Confirm MCP is wired (`.vscode/mcp.json`) and the PAT has read access. Test
with a minimal MCP query directly.

**Generated code doesn't match our conventions.**
Update `.github/instructions/di-code-standards.instructions.md` with
explicit examples of your project's patterns. The agent reads instructions
before generating.

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
- It is not a SaaS. The client owns the files — if the consulting team rotates off, the pack stays.
- It is not a replacement for engineering judgment. Every output is a draft; human review is required.
- It is not a replacement for Assert.IQ. Use both packs together for full SDLC + QE coverage.
- It is not a tooling pitch. Use it where the maturity supports it. Lead with DI thinking, not with this pack.

---

## Versioning

| Version | Notes |
|---------|-------|
| 0.11.0 | Pre-release. 27 skills complete. Bootstrap with `--preset` and `--uninstall`. No git tags cut yet — distributed as a zip. All Copilot and Claude Code surfaces wired. |

See [CHANGELOG.md](../CHANGELOG.md) for the full release history including post-0.11.0 maintenance.

---

## Dev.IQ + Assert.IQ

Dev.IQ and Assert.IQ are complementary packs within Intelligence Studio.
Dev.IQ owns the developer lifecycle (requirements, design, code, deployment).
Assert.IQ owns the QE lifecycle (test planning, defect analysis, release confidence).
They share the same pack architecture and can be installed independently or together.
