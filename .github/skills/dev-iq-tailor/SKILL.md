---
name: dev-iq-tailor
mode: agent
description: "Tailor a freshly-installed Dev.IQ pack to THIS codebase — discover the stack once, then customize config.yaml, governance.md, maturity-profile.md, the five instruction files, the skills, and mcp.json in dependency order, gated by human review. WHEN: customize the pack, tailor Dev.IQ, configure config.yaml for my repo, fill in the placeholders, set up governance, just installed the pack what next, onboard the pack to my codebase."
---

<!-- markdownlint-disable MD033 -->
<!--
HOW THIS SKILL RELATES TO /dev-iq-bootstrap
==============================================
`/dev-iq-bootstrap` does PLACEMENT — it copies the pack
surfaces into the workspace (trial vs committed, presets, graduate,
uninstall). It never edits file CONTENT; everything it drops still
carries `<PLACEHOLDER>` values and universal-template defaults.

This skill does TAILORING — it takes that freshly-placed pack and
rewrites the configurable content so it describes THIS team: the right
tracker, VCS, language stack, governance posture, maturity tier, and MCP
servers. Run bootstrap first, then this.

WHY config.yaml IS THE KEYSTONE
===============================
Every skill in the pack is a universal template that reads its values
from `.dev-iq/config.yaml` at runtime (the `{{PLACEHOLDER}}` blocks
resolve from config keys). A thorough config.yaml pass therefore makes
~90% of per-skill customization happen automatically. This skill does
NOT rewrite skill bodies by default — that would diverge from the
shipped templates and make future pack upgrades a merge headache.
Instead it CONFIG-DRIVES the skills and only gap-checks them. Deep
skill-body rewriting is opt-in and tier-gated (see Phase 6).
-->

# /dev-iq-tailor

Walk a user who just installed the Dev.IQ pack through a thorough,
evidence-driven customization pass. You discover the codebase once, then
tailor the pack's configurable surfaces **in dependency order** so the
keystone (`config.yaml`) is set before anything that reads from it.

This skill is **language-, framework-, tracker-, VCS-, and
cloud-agnostic**. It tailors whatever stack the repo actually uses; it
does not impose one.

## When to use

- The user just ran `/dev-iq-bootstrap` (or `bootstrap.sh`) and wants
  the pack tailored to their codebase rather than left on defaults.
- The user explicitly typed `/dev-iq-tailor`, or asked to
  "customize the pack / fill in the placeholders / configure this for
  my repo."
- The agent detected unresolved `<PLACEHOLDER>` values in
  `.dev-iq/config.yaml` and the user wants them filled.

Do **not** use this skill to install or place the pack — that is
`/dev-iq-bootstrap`. If `.dev-iq/config.yaml` does not exist,
stop and route the user to `/dev-iq-bootstrap` first.

## Core principles

1. **config.yaml first, everything else after.** It is the keystone;
   downstream files and skills read from it.
2. **Discover once, tailor many.** Build a single Stack Profile up
   front, then reuse it for every file. Do not re-scan per file.
3. **Human review is a gate, not a formality.** Present the Stack
   Profile and proposed changes before writing. Never tailor governance
   or compliance posture silently.
4. **Infer the technical, ask the judgemental.** Languages, trackers,
   CI systems, and VCS hosts are detectable — infer them. Compliance
   regimes, maturity tier rationale, and org URLs are not — ask.
5. **Never invent compliance.** Detecting a `payment/` path raises a
   PCI-DSS *question*; it never flips a regime to `yes`.
6. **Reversible and idempotent.** Snapshot every file before editing;
   re-running the skill must not double-edit.
7. **Preserve upgradability.** Prefer config keys over skill-body
   rewrites so the team can pull future pack versions cleanly.

## Phase 0 — Preconditions

1. Confirm `.dev-iq/config.yaml` exists. If absent → route to
   `/dev-iq-bootstrap` and stop.
2. Read `.dev-iq/config.yaml > maturity.tier`. It gates Phase 6.
3. Confirm the working tree is under version control and reviewable
   (so every edit shows up in `git diff`). If not, warn the user that
   changes will be harder to review and ask to proceed.
4. Note whether this is a first run (placeholders present) or a re-run
   (snapshots already exist). On a re-run, treat existing
   `*.di.pre-tailor` snapshots as the baseline — do not overwrite them.

## Phase 1 — Discovery (read-only)

Build a **Stack Profile** by scanning the workspace. Do this once. Be thorough — no hand-waving. For
large repos, run the independent scans in parallel. Detect:

| Dimension | Signals to read |
|---|---|
| Languages | file extensions, `*.csproj` / `*.sln`, `package.json`, `pyproject.toml`, `go.mod`, `pom.xml`, `Gemfile`, `Cargo.toml` |
| Frameworks | Express, NestJS, Spring, FastAPI, Django, ASP.NET, Rails, etc. from `package.json`, `pom.xml`, project deps |
| CI system | `.github/workflows/**` → GitHub Actions; `azure-pipelines.yml` → Azure Pipelines; `*.gitlab-ci.yml`; `Jenkinsfile` |
| Tracker | infer from CI/links/remote: GitHub Issues, Azure Boards (ADO), Jira, Linear |
| VCS host | `git remote -v` host: github.com / dev.azure.com / gitlab / bitbucket |
| Deployment patterns | Dockerfile, `docker-compose.yml`, Helm charts, Terraform, Kubernetes manifests, serverless configs |
| Observability | Sentry (`@sentry/*`, `sentry-sdk`), Grafana, Datadog, Honeycomb (in deps or env files) |
| Database | postgres, mysql, sqlite, mongodb, redis in deps; migration dirs (`migrations/`, `db/migrate/`) |
| API contracts | `openapi*.y?ml`, `swagger*.json`, `asyncapi*.y?ml`, `*.proto` |
| Topology | one repo with code+tests (monorepo) vs split prod/tests repos |
| Sensitive paths | dirs matching `payment*`, `billing`, `auth`, `checkout`, `export*`, `migrations`, PII/PCI hints |
| Traceability idiom | dominant language → marker style (C# → `// AB#`, JS/TS → `// AB#`, Python → `# AB#`, Java → `// AB#`, Go → `// AB#`) |

Record the evidence for each detection (the file/path that proves it),
so the review step can show its work. Where a dimension cannot be
detected, mark it **needs input** — do not guess.

## Phase 2 — Align (the review gate)

Present the Stack Profile to the user as a compact table: each detected
value, the evidence, and the proposed config key it will set. Then:

1. Ask **only** for what could not be inferred or is a judgement call:
   - Tracker org/project URL + project key (e.g. ADO organization URL
     and project; Jira base URL + key).
   - Compliance regimes that apply (offer the detected sensitive-path
     hints as *prompts*, e.g. "I see `checkout/` and `payment/` — does
     PCI-DSS apply?").
   - Maturity tier confirmation + a 2–5 sentence rationale, and the
     Effective / Re-evaluation dates.
2. Confirm the proposed traceability marker style.
3. Get explicit go-ahead before writing anything. This is the mandatory
   human-review gate.

## Phase 3 — Tailor `config.yaml` (keystone)

Snapshot, then fill **every** `<PLACEHOLDER>` you have evidence or an
answer for. If you're unsure, ask the user. Leave a clearly-marked `TODO(tailor):` only where a secret
or human-only value is required.

- `client.name`, `client.embedded_team`, `client.context` (1–3 sentence
  domain/stack summary from the Stack Profile).
- `tracker.type` **and** `tracker.system` (keep in sync); fill the
  matching sub-block (github/ado/jira/linear); comment out the rest.
- `vcs.type` **and** `vcs.host` (keep in sync); `default_branch`.
- `maturity.tier` + `rationale` (mirror what you set in the profile).
- `stack.languages`, `stack.frameworks`, `stack.deployment_targets`
  from the detected stack.
- `traceability.marker_style` to the detected idiom.
- `pr.risk_thresholds.sensitive_paths` — add the detected sensitive
  dirs to the shipped defaults.
- `workspace.role` + `companion_repo` when split-repo was detected.
- `signals.quality.sast_tool`, `signals.quality.coverage_tool` from
  detected CI configuration.

Do not remove the explanatory comments — they help the next maintainer.

## Phase 4 — Tailor `governance.md` + `maturity-profile.md`

Snapshot each, then:

- **governance.md**: set each regime's "Applies" to the user's answers
  from Phase 2 (`yes` / `partial` / `no`). For every `yes`/`partial`,
  fill the per-regime block (data classes, where they live, refusal
  pattern). Delete rows the user said don't apply. **Never** set a
  regime to `yes` without an explicit user answer.
- **maturity-profile.md**: set the tier (matching `config.yaml`), the
  Effective and Re-evaluation dates, the plain-language rationale, and
  check the indicators the user confirmed. Keep the two tier values in
  lockstep — a mismatch is a defect.

## Phase 5 — Tailor the five instruction files

Snapshot each, then tailor to the detected stack:

- `di-traceability.instructions.md` — align the `applyTo` glob and the
  marker examples to the dominant language (e.g. keep `**/*.{cs,xaml}`
  for .NET; switch to `**/*.{ts,tsx,js}` for a JS/TS repo).
- `di-signal-emission.instructions.md` — point the emission step at the
  detected CI system (GitHub Actions / Azure Pipelines / GitLab CI) and
  the configured signal sink from `telemetry-overlay.md`.
- `di-security.instructions.md` — add any framework-specific security
  notes (e.g. CORS defaults for NestJS, SQL injection patterns for raw
  query ORMs). Do not over-edit; the file is mostly universal.
- `di-code-standards.instructions.md` — align naming convention
  defaults to the dominant language; adjust the abstraction examples to
  match the detected framework. Read the existing code first.
- `di-foundation.instructions.md` — leave as-is unless the user wants a
  client-specific governance note; it is the shared rulebook.

## Phase 6 — Skills pass (LIGHT by default)

Default behavior — a **config-driven gap-check**, not a rewrite:

1. For each skill in `.github/skills/` that was installed with the pack, identify the
   `config.yaml` keys it depends on.
2. Report any keys that are still unset or still `<PLACEHOLDER>` after
   Phase 3 — these are the only places a skill won't behave correctly.
3. Offer to fill the remaining keys (preferred) rather than editing the
   skill body.
4. Optionally offer to trim the long HOW-TO-CUSTOMIZE comment blocks for
   a leaner repo — for model token management, opt-in.

**Deep mode (opt-in, tier-gated):** only when the user explicitly asks
to rewrite skill bodies AND `maturity.tier` is `mid` or `higher`. Below
`mid`, decline deep rewrites and explain that config-driving keeps the
pack upgradable. Warn that deep edits complicate future pack upgrades.

## Phase 7 — Tailor `mcp.json`

Snapshot `.vscode/mcp.json`, then:

- Keep the MCP server entries the Stack Profile needs (the detected
  tracker + VCS host, plus `git`; add observability servers when Sentry,
  Grafana, or Datadog was detected; add `postgres` or `sqlite` when
  database signals were found).
- Comment out — do not delete — servers the team does not use, so
  re-enabling later is trivial.
- Leave all `${input:...}` secret placeholders intact; never inline a
  credential. Note any inputs the user must supply at first run.

## Phase 8 — Review & summary

1. Print a per-file change table: file, what changed, snapshot path.
2. List remaining `TODO(tailor):` items that need a human (secrets,
   org URLs, sign-off).
3. Remind the user to **review the diff** before committing — AI-tailored
   config is a draft pending the human-review gate.
4. Remind them to **reload the editor** so instruction changes load
   (VS Code: `⇧⌘P` → "Reload Window"; Claude Code: restart session).
5. Close with **Recommendation, Next Steps, Owners, Timeline**.

## Safety model

- Before editing any file, snapshot it to `<file>.di.pre-tailor`
  (mirrors bootstrap's `*.di.pre-install` convention). This makes
  the pass reversible and idempotent: on a re-run, an existing
  `.pre-tailor` snapshot is the baseline and is **not** overwritten.
- To revert a single file: copy its `.di.pre-tailor` snapshot back over it.
- The `*.di.pre-tailor` glob is already in the bootstrap-managed
  `.git/info/exclude` block, so snapshots never leak into git. If you
  create a snapshot outside the dirs bootstrap manages, add an exclude
  entry yourself. The skill never commits, pushes, or touches anything
  outside the workspace.
- These snapshots are **not** in the install manifest. Bootstrap
  `--uninstall` sweeps any leftover `*.di.pre-tailor` files (under
  `.dev-iq/`, `.github/instructions/`, `.vscode/`) so uninstall leaves
  no tailor litter behind. If you snapshot elsewhere, remove it manually
  when done.

## Anti-patterns (do not do these)

- Do **not** tailor `config.yaml` last — keystone goes first.
- Do **not** set a compliance regime to `yes` without an explicit user
  answer.
- Do **not** rewrite skill bodies by default; config-drive them.
- Do **not** let `maturity.tier` differ between `config.yaml` and
  `maturity-profile.md`.
- Do **not** inline secrets into `mcp.json`; keep `${input:...}`.
- Do **not** skip the snapshot step — every edit must be reversible.
