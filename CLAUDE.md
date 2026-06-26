# Dev.IQ — Claude Code entrypoint

This repository is governed by the Developer Intelligence (DI) operating model.
`.github/instructions/di-foundation.instructions.md` is the single source of
truth for DI principles, governance, maturity tiers, output standards, and
Assert.IQ boundaries — read it before acting on any code or delivery question.

## Scoped guidance (load when relevant)

- @.github/instructions/di-foundation.instructions.md — **always-on**: DI signal model, governance, maturity, output standards, Assert.IQ
- @.github/instructions/di-code-standards.instructions.md — code generation, review, refactoring
- @.github/instructions/di-security.instructions.md — security review, auth, data handling, OWASP
- @.github/instructions/di-traceability.instructions.md — work item linking, artifact tracing

> Load `.github/instructions/di-signal-emission.instructions.md` when editing CI/CD configuration (GitHub Actions workflows, Azure Pipelines, Jenkinsfiles, Terraform). It is scoped and not always-on.

## Claude Code capabilities

- **Subagents** — `.claude/agents/dev-iq.md` (full tools) and `.claude/agents/dev-iq-plan.md` (read-only planning)
- **Skills** — `.github/skills/` mirrored at `.claude/skills/` — 23 DI skills auto-discovered
- **Hooks** — `.claude/settings.json`, sourced from `hooks/hooks.json`. Run `bash scripts/bootstrap.sh` to sync.
- **Per-client config** — `.dev-iq/config.yaml`, `.dev-iq/governance.md`, `.dev-iq/maturity-profile.md`, `.dev-iq/telemetry-overlay.md`
- **Bootstrap** — `scripts/bootstrap.sh` / `scripts/bootstrap.ps1`, invoked by `/dev-iq-bootstrap`:
  - `--mode=committed` — files visible to git (team adoption)
  - `--mode=trial` — local-only via `.git/info/exclude` (codebase `.gitignore` never touched). Graduate with `--graduate`.
  - `--mode=ask` — interactive prompt (default in TTY)

## Companion files

- `.github/copilot-instructions.md` — Copilot-side entry. Same instruction files, Copilot-specific wiring.
- `AGENTS.md` — generic agent-spec pointer for Codex CLI, Cursor, Aider.
