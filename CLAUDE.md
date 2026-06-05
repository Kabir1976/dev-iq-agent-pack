# Dev.IQ — Claude Code entrypoint

This repository is governed by the Developer Intelligence (DI) operating model.
DI is the strategic frame; Dev.IQ is the accelerator. This file is the
Claude Code counterpart to `.github/copilot-instructions.md` — same rules,
delivered through Claude's native config surface.

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

Read `.dev-iq/maturity-profile.md` before acting (or
`~/.dev-iq/maturity-profile.md` as a user-global fallback). Behavior
changes by tier:

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
  `.dev-iq/governance.md` (or `~/.dev-iq/governance.md` as a user-global
  fallback), refuse and explain.
- Never introduce new dependencies, frameworks, or architectural patterns
  without explicit confirmation from the team.
- Security findings rated High or Critical must block the PR verdict
  regardless of maturity tier.

## Output standards

- Cite the work item, file path, and DI signal layer when producing artifacts.
- Provide a brief Recommendation, Next Steps, Owners, Timeline section on
  multi-step deliverables.
- Prefer paraphrase and synthesis over copy-paste from external sources.
- Every skill output carries a `@di-review-required` marker — make this
  explicit in responses.

## Scoped guidance (load when relevant)

Copilot loads these automatically through their `applyTo` frontmatter globs.
In Claude Code, treat them as scope-conditional guidance — read the file
referenced below when the user's task matches the "When this applies" header
inside each file.

- @.github/instructions/di-foundation.instructions.md — **always-on**;
  baseline DI reasoning order for any code, design, review, or delivery question.
- @.github/instructions/di-code-standards.instructions.md — apply when
  generating, reviewing, or refactoring code in any language.
- @.github/instructions/di-security.instructions.md — apply when reviewing
  code for security issues, generating auth/data handling code, or assessing
  risk signals.
- @.github/instructions/di-traceability.instructions.md — apply when adding
  or modifying production code tied to a work item, or generating traceability
  artifacts.
- @.github/instructions/di-signal-emission.instructions.md — apply when
  editing CI configuration (GitHub Actions, Azure Pipelines, GitLab CI,
  Jenkinsfile).

## Capabilities surface

- **Subagents** — `.claude/agents/dev-iq.md` (default Dev.IQ subagent,
  full tools) and `.claude/agents/dev-iq-plan.md` (read-only planning
  sibling).
- **Skills** — `.github/skills/` (canonical) is mirrored at `.claude/skills`
  so Claude auto-discovers all 21 DI skills (code review, scaffold feature,
  API design, PR readiness, blast radius estimation, release notes, etc.).
- **Hooks** — wired through `.claude/settings.json`, sourced from
  `hooks/hooks.json` (Claude plugin format). Run `bash install.sh` (or
  `install.ps1` on Windows) after dropping the pack into a repo to sync
  hooks and create the skills symlink.
- **Per-client config** — `.dev-iq/config.yaml`, `.dev-iq/governance.md`,
  `.dev-iq/maturity-profile.md`, `.dev-iq/telemetry-overlay.md`.
- **Workspace bootstrap** — `scripts/bootstrap.sh` /
  `scripts/bootstrap.ps1`, invoked by the `/dev-iq-bootstrap` skill.
  Three install modes:
  - `--mode=committed` — files visible to git (team adoption).
  - `--mode=trial` — files added to `.git/info/exclude` (local-only;
    the codebase `.gitignore` is **never** touched). Graduate later
    with `scripts/bootstrap.sh --graduate`.
  - `--mode=ask` (default in TTY) — interactive prompt.
  Pre-existing user files are preserved via SHA256 compare + interactive
  conflict resolver. Every install records
  `.dev-iq/.install-manifest.json` (version, mode, paths).

## Companion files

- `.github/copilot-instructions.md` — the Copilot-side equivalent of this
  file. If you change behavior here, update the Copilot file too (and vice
  versa) to keep tools in lockstep.
- `AGENTS.md` — generic agent-spec pointer for non-Copilot, non-Claude
  tooling (Codex CLI, Cursor, Aider).

## Relationship with Assert.IQ

Dev.IQ and Assert.IQ are complementary packs within Sparq Intelligence Studio.
If Assert.IQ is also installed in this repo:
- Defer all test generation, defect analysis, and quality signal decisions
  to Assert.IQ skills.
- Dev.IQ owns: requirements, design, code construction, PR readiness,
  deployment readiness.
- Assert.IQ owns: test planning, test generation, flaky test analysis,
  release confidence, escaped defect analysis.
- Shared domain (each applies its own lens): code review, PR creation,
  traceability matrix.

## gstack (recommended)

This project uses [gstack](https://github.com/garrytan/gstack) for AI-assisted workflows.
Install it for the best experience:

```bash
git clone --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
cd ~/.claude/skills/gstack && ./setup --team
```

Skills like /qa, /ship, /review, /investigate, and /browse become available after install.
Use /browse for all web browsing. Use ~/.claude/skills/gstack/... for gstack file paths.
