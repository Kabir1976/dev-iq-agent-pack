# Dev.IQ

**v0.11.0** · [Full documentation →](docs/reference.md)

---

## Developer Intelligence

Traditional development asks one question: *does this work?*

**Developer Intelligence** asks four:

| Layer | Question |
|---|---|
| **Intent** | What are we building, and does it match what was asked? |
| **Design** | Is it being built the right way — patterns, architecture, standards? |
| **Quality** | Is it production-ready — secure, tested, performant? |
| **Risk** | What could break — downstream dependencies, schema changes, blast radius? |

These four layers combine into **Decision Confidence** — a synthesized, traceable answer to *"is this ready to ship?"* that no single linter pass or green build can give you.

The immediate impact:

- Developers stop asking "does it compile?" and start asking "does this solve the right problem the right way?"
- PR conversations shift from gut-feel to evidence.
- Design decisions get documented and traceable — not just implied.
- Architecture guardrails enforce themselves through every code review, every PR, every deployment check.

---

## Dev.IQ — DI inside your IDE

Dev.IQ is the accelerator. It drops a DI reasoning layer directly into **GitHub Copilot Chat** and **Claude Code** so developers don't have to learn a new tool or change their workflow. The IDE they already use becomes delivery-intelligent.

- **31 skills** covering the full developer lifecycle — API design, feature scaffolding, code review, security analysis, observability review, AI integration review, PR readiness, blast radius estimation, deployment checks, and more.
- **Two agents** (`Dev-IQ` for full execution, `Dev-IQ-PLAN` for plan-first workflows) with a built-in handoff button between them.
- **Maturity-aware behavior** — a one-file config scales the pack from "early / advisory only" to "higher / autonomous PR verdicts," meeting teams where they are.
- **MCP wiring** to GitHub, ADO, Jira, Sentry, Grafana, Playwright, Slack, and 13 more tool surfaces — configured in one file, credentials kept in your OS keychain.
- **Hindsight Hooks** that learn from corrections across sessions and progressively tighten agent behavior for your specific codebase.

DI is the operating model. Dev.IQ is how developers act on it — from day one, in the tools they already use.

> Dev.IQ covers the developer lifecycle. Assert.IQ covers the QE lifecycle.
> Install both for full SDLC coverage.

---

## Why structured governance matters now

The enterprise AI developer tooling market has a trust problem that is getting worse, not better.

**Developer trust is falling as adoption grows.** Stack Overflow's 2025 Developer Survey (49,000+ respondents) found that combined developer trust in AI tool accuracy fell from 43% to 33% year-over-year, while AI adoption grew from 76% to 84%. Active distrust rose from 31% to 46% — nearly doubling. Positive favorability dropped 12 points (72% → 60%). Developers are using tools they trust less than they did twelve months ago.

**Governance coverage is the gap.** IBM's 2025 Cost of a Data Breach Report (the first year tracking shadow AI as a distinct breach vector, ~600 organizations) found that only 37% of organizations have policies to manage AI tools or detect unsanctioned usage. Of those, only 34% perform regular audits.

**Unstructured adoption doesn't move the needle.** A peer-reviewed RCT across 4,867 developers at Microsoft, Accenture, and a Fortune 100 firm (SSRN/Management Science 2025) found a 26% increase in completed tasks with structured AI adoption. A real-world longitudinal study at NAV IT (703 repositories, 26,317 commits, two years) found no statistically significant improvement without structured governance. The same tool, opposite outcomes.

Dev.IQ addresses all three: the trust gap with explicit signal grounding (UNGRADED over invented confidence), the governance gap with maturity tiers and a governance posture file, and the adoption gap by giving teams a structured reasoning layer rather than an autocomplete shortcut.

---

## Get started in three steps

### 1 · Install the plugin

**VS Code Copilot Chat**

1. `Cmd+Shift+P` → **`Chat: Install Plugin From Source`**
2. Paste the shorthand — no URL, no `@ref`:
   ```
   [your-org]/dev-iq
   ```
3. Pick **`dev-iq`** from the list → confirm → **`Developer: Reload Window`**.

**Claude Code**

```bash
/plugin install [your-org]/dev-iq@v0.11.0
```

This installs the 31 skills and both agents globally. Nothing is written to your codebase yet — that's the next step.

---

### 2 · Bootstrap the plugin to your workspace

Open the **target repo** (not this one), open the chat, and run:

```
/dev-iq-bootstrap
```

The skill asks two questions, then handles everything else:

- **Trial or committed?** Trial hides pack files from git via `.git/info/exclude` — only you see them; your codebase `.gitignore` is never touched. Committed checks files in so the whole team benefits. Graduate from trial to committed any time with `scripts/bootstrap.sh --graduate`.
- **Solo or pod?** Presets that tune defaults for individual contributors vs. cross-functional teams.

Bootstrap copies instruction files, `.dev-iq/` config, `.vscode/settings.json`, `.vscode/mcp.json`, and hooks into the right places. SHA256-compares before writing — pre-existing files are preserved, never silently overwritten. Safe to re-run.

---

### 3 · Customize and wire everything in

1. **Set your maturity tier** in `.dev-iq/maturity-profile.md` — Early, Mid, or Higher. The agents read this on every code and delivery question and scale their behavior accordingly.

2. **Set your governance posture** in `.dev-iq/governance.md` — compliance constraints the agents must respect.

3. **Wire your tools** in `.vscode/mcp.json`. The pack ships 20 pre-configured MCP servers. Add credentials when VS Code prompts — they go to your OS keychain, not the file. See [`.vscode/MCP.md`](.vscode/MCP.md) for a per-server setup guide.

4. **Configure your telemetry overlay** in `.dev-iq/telemetry-overlay.md`. Map each DI signal to your client's actual data sources — ADO or Jira for intent, SonarQube or Codecov for quality, your dependency manifest for risk. Or let the agent do it:

   - Add `.dev-iq/telemetry-overlay.md` to the chat context.
   - Then say:
     ```
     Customize this telemetry overlay for my codebase and stack.
     ```
   The agent will ask a few targeted questions about your tools, tracker, and architecture, then fill in the placeholders.

5. **Run a skill.** In Copilot Chat, select the `Dev-IQ` agent and try:
   ```
   /review-code
   ```
   The agent pulls context from your connected tools and reasons through all four DI signal layers.

---

## What's inside

```
.github/
  copilot-instructions.md     ← always-on DI reasoning rules for Copilot
  instructions/               ← scoped rule sheets (code standards, security, etc.)
  skills/                     ← 31 DI skills, one subfolder each
  agents/                     ← Dev-IQ and Dev-IQ-PLAN agent definitions
.claude/
  agents/                     ← Claude Code subagent counterparts
  skills → ../.github/skills  ← symlink (copy on Windows without Dev Mode)
.vscode/
  mcp.json                    ← 20 MCP server definitions
  MCP.md                      ← per-server credential and setup guide
hooks/
  hooks.json                  ← Hindsight Hooks wiring
  scripts/                    ← session-start, apply, reflect, session-end
.dev-iq/                      ← per-repo config (created by bootstrap)
scripts/
  bootstrap.sh / .ps1         ← workspace installer, cross-platform
```

---

## Upgrade

Upgrades are explicit and intentional:

1. Read the Releases page for what changed and any migration notes.
2. Uninstall the current version — VS Code: Extensions view → `@agentPlugins` → uninstall `dev-iq`. Claude Code: `claude mcp remove dev-iq`.
3. Reinstall using the same Step 1 commands with the new tag.
4. Re-run `/dev-iq-bootstrap` to refresh workspace surfaces.

---

## Go deeper

The three steps above are the fast path. When you're ready for the full picture:

**[docs/reference.md →](docs/reference.md)** — detailed install options, full skill reference, maturity tier matrix, DI signal model, telemetry overlay guide, hooks architecture, customization guide, and troubleshooting.

Tool-specific references:
- VS Code / Copilot — [`.github/vscode-readme.md`](.github/vscode-readme.md)
- Claude Code — [`.claude/claude-readme.md`](.claude/claude-readme.md)
- MCP servers — [`.vscode/MCP.md`](.vscode/MCP.md)
