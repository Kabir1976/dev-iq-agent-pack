---
name: dev-iq-bootstrap
description: Guide the installation and configuration of the Dev.IQ Agent Pack into a new workspace. Use when asked to "install Dev.IQ", "bootstrap Dev.IQ", "set up Dev.IQ", or "configure Dev.IQ for this project".
di_signal: —
maturity_required: early
status: approved
---

# Dev.IQ Bootstrap

## Overview
Guides the installation and configuration of the Dev.IQ Agent Pack into a new
workspace — detecting whether Dev.IQ is already installed, running the
bootstrap script in the appropriate mode, prompting for key configuration
values, verifying the installation, and running a smoke test to confirm the
pack is operational.

This is a setup skill, not an assessment skill. It has no DI signal layer of
its own — it creates the conditions for all other skills to function correctly.

## When to Use
- When installing Dev.IQ into a new project for the first time
- When onboarding a new client workspace to the Dev.IQ Agent Pack
- When upgrading a trial install to a committed (team-visible) install
- When a workspace is missing the `.dev-iq/` directory and other skills are
  falling back to Early maturity defaults
- When the install manifest is missing or corrupt and needs to be regenerated
- Any time the user says: "install Dev.IQ", "bootstrap Dev.IQ", "set up Dev.IQ",
  "configure Dev.IQ for this project", "onboard this repo to Dev.IQ"

## Instructions

### Step 1: Detect Existing Installation
Check for the presence of `.dev-iq/` directory in the workspace root:

**If `.dev-iq/` exists:**
- Read `.dev-iq/.install-manifest.json` (if present) to determine:
  - Currently installed version
  - Install mode (trial / committed)
  - Installation date
- Ask: "Dev.IQ is already installed (version [X], mode: [mode]). What would
  you like to do? [1] Upgrade, [2] Change mode (trial → committed), [3]
  Reconfigure, [4] Exit"

**If `.dev-iq/` does not exist:**
- Proceed to Step 2.

**If `~/.dev-iq/` exists but no project-level `.dev-iq/`:**
- Inform: "A user-level Dev.IQ configuration was found at `~/.dev-iq/`.
  The project-level install adds per-project config (stack, governance,
  maturity profile). Proceeding with project install."

### Step 2: Select Install Mode
Present the three install modes and ask which to use:

| Mode | What it does | When to use |
|------|-------------|------------|
| `--mode=trial` | All files added to `.git/info/exclude` — invisible to git, local only | Evaluating Dev.IQ; not ready to commit to the team |
| `--mode=committed` | Files staged and committed to the repo — visible to the whole team | Team adoption; everyone gets Dev.IQ |
| `--mode=ask` (default) | Interactive prompt at each file (useful for custom selection) | Selectively installing some files |

Also present the graduate path for trial installs:
- "If you start in trial mode, run `scripts/bootstrap.sh --graduate` when
  the team is ready to adopt — this moves the files into git tracking
  without reinstalling."

### Step 3: Run the Bootstrap Script
**On macOS / Linux:**
```bash
bash scripts/bootstrap.sh --mode=[chosen mode]
```

**On Windows:**
```powershell
.\scripts\bootstrap.ps1 --mode=[chosen mode]
```

If the scripts directory does not exist (first-time install from the agent
pack distribution):
- Instruct the user to first clone or copy the Dev.IQ pack files into the
  project, or to run the one-liner install if one is documented in INSTALL.md.

**Pre-existing file handling:**
The bootstrap script compares SHA256 hashes of existing files with the pack
versions. If a conflict is detected, the user is presented with:
- Keep existing
- Replace with pack version
- Show diff

Never silently overwrite user files.

### Step 4: Prompt for Key Configuration Values
After the script completes, guide the user through the key values in
`.dev-iq/config.yaml`:

```yaml
# Key fields to configure:

workspace:
  role: monorepo               # monorepo | prod | tests
  tracking_system: ado         # ado | jira | github

stack:
  language: typescript         # e.g. typescript, python, java, go, csharp
  framework: express           # e.g. express, fastapi, spring, nextjs
  database: postgres           # e.g. postgres, mysql, mongodb, none
  test_runner: jest            # e.g. jest, pytest, junit, vitest

maturity:
  tier: early                  # early | mid | higher

code_standards:
  min_coverage_threshold: 70   # percentage (0–100)

signals:
  quality:
    sast_tool: none            # e.g. sonarqube, semgrep, codeql, none
```

For each key, state: what it does, why it matters for DI signal behavior,
and what happens if left at the default.

Maturity tier in particular: explain what changes at each tier so the team
can set the right level of autonomy.

### Step 5: Verify the Installation
Check that the key files are in place:

| File | Required | Purpose |
|------|----------|---------|
| `.dev-iq/config.yaml` | Yes | Stack and maturity configuration |
| `.dev-iq/maturity-profile.md` | Yes | Maturity tier behavior overrides |
| `.dev-iq/governance.md` | Recommended | Compliance posture and license policy |
| `.dev-iq/.install-manifest.json` | Yes | Version and mode tracking |
| `.github/skills/` | Yes | Skill definitions (symlinked from `.claude/skills`) |
| `.claude/settings.json` | Recommended | Hook configuration |

Flag any missing required file as a verification failure.

### Step 6: Run a Smoke Test
Run a quick smoke test to confirm the pack is operational:

1. Select a small, representative file in the codebase (a service class or
   a utility function — not a config file)
2. Run `/explain-code` on it
3. Verify the output includes: Purpose, How It Works, Assumptions, and an
   INTENT signal verdict
4. If the output is complete: smoke test passed
5. If the output is missing sections or errors: report the failure and
   troubleshoot

### Step 7: Report Installation Results
Produce a completion summary.

## Inputs Required
| Input | Source | Required |
|-------|--------|----------|
| Install mode preference | User selects | Yes |
| Stack language and framework | User states | Required for config |
| Database type | User states | Required for config |
| Tracking system (ADO/Jira/GitHub) | User states | Required for traceability |
| Maturity tier | User selects | Required |
| Existing installation status | Auto-detected | Auto-detected |

## Output Format

```
## Dev.IQ Bootstrap — [project name or path]
Initiated: [date]
Install mode: [trial | committed | ask]

---

### Installation Checklist

| Step | Status | Notes |
|------|--------|-------|
| Existing install check | ✓ | [no existing install / existing version X] |
| Install mode selected | ✓ | [mode] |
| Bootstrap script run | ✓ / ✗ | [result or error] |
| Configuration prompted | ✓ | [key values set] |
| File verification | ✓ / ✗ | [all present / [file] missing] |
| Smoke test | ✓ / ✗ | [passed / failed — reason] |

---

### Configuration Summary

```yaml
workspace.role: [value]
workspace.tracking_system: [value]
stack.language: [value]
stack.framework: [value]
stack.database: [value]
maturity.tier: [value]
```

---

### What Was Installed

| File / Directory | Mode | Notes |
|-----------------|------|-------|
| `.dev-iq/config.yaml` | [trial/committed] | Project configuration |
| `.dev-iq/maturity-profile.md` | [trial/committed] | Maturity tier behavior |
| `.dev-iq/governance.md` | [trial/committed] | Compliance posture |
| `.dev-iq/.install-manifest.json` | [trial/committed] | Install record |
| `.github/skills/` | [trial/committed] | [N] skill definitions |
| `.claude/settings.json` | [trial/committed] | Hook configuration |

---

### Smoke Test Result

Ran `/explain-code` on `[file path]`:
- Purpose: ✓
- How It Works: ✓
- Assumptions: ✓
- INTENT Signal: ✓

**Result: PASSED** — Dev.IQ is operational.

@di-review-required

---

### Next Steps

1. Run `/explain-code` on any file to verify INTENT signal works in context
2. Run `/generate-user-stories` with a recent feature request to test INTENT output
3. Run `/review-pr-readiness` on an open PR to test the full four-layer assessment
4. When the team is ready to adopt: run `bash scripts/bootstrap.sh --graduate`
   to move from trial to committed mode

---

```

## Examples

### Example 1: Fresh Trial Install

**User says:** `/dev-iq-bootstrap` on a new TypeScript/Express project

**Result:**

```
## Dev.IQ Bootstrap — api-service
Initiated: 2026-06-06
Install mode: trial

---

### Installation Checklist

| Step | Status | Notes |
|------|--------|-------|
| Existing install check | ✓ | No existing install found |
| Install mode selected | ✓ | trial — files in .git/info/exclude |
| Bootstrap script run | ✓ | Completed in 4 seconds |
| Configuration prompted | ✓ | TypeScript, Express, PostgreSQL, ADO, Early |
| File verification | ✓ | All required files present |
| Smoke test | ✓ | /explain-code on src/auth/tokenService.ts passed |

---

### Configuration Summary

```yaml
workspace.role: monorepo
workspace.tracking_system: ado
stack.language: typescript
stack.framework: express
stack.database: postgres
maturity.tier: early
```

---

### What Was Installed

| File | Mode | Notes |
|------|------|-------|
| .dev-iq/config.yaml | trial | Project configuration |
| .dev-iq/maturity-profile.md | trial | Early maturity — advisory mode, coaching notes |
| .dev-iq/governance.md | trial | Default governance posture |
| .dev-iq/.install-manifest.json | trial | Version: 1.0.0 |
| .github/skills/ | trial | 22 skill definitions |
| .claude/settings.json | trial | Hook configuration |

---

### Smoke Test Result

Ran `/explain-code` on `src/auth/tokenService.ts`:
- Purpose: ✓
- How It Works: ✓
- Assumptions: ✓
- INTENT Signal: ✓

**Result: PASSED** — Dev.IQ is operational in trial mode.

---

### Next Steps

1. Try `/explain-code` on a complex service class to validate INTENT output
2. Try `/review-pr-readiness` on an open PR to see the four-layer assessment
3. Share the experience with the team — when ready, run:
   `bash scripts/bootstrap.sh --graduate` to move to committed mode
```

---

### Example 2: Upgrading Trial to Committed

**User says:** "We want to commit Dev.IQ to the repo — the trial worked well."

**Result:**

```
## Dev.IQ Bootstrap — upgrade trial → committed
Initiated: 2026-06-06

---

Existing installation detected: version 1.0.0, mode: trial
Action: Graduate to committed mode

Running: `bash scripts/bootstrap.sh --graduate`

Files moving from .git/info/exclude to git tracking:
- .dev-iq/config.yaml ✓
- .dev-iq/maturity-profile.md ✓
- .dev-iq/governance.md ✓
- .dev-iq/.install-manifest.json ✓
- .github/skills/ (symlink) ✓

Install manifest updated: mode: committed, graduated: 2026-06-06

---

### Next Steps

1. Stage and commit the Dev.IQ files: `git add .dev-iq/ .github/skills/`
2. Push and open a PR — include a note that Dev.IQ is being adopted
3. Share INSTALL.md with teammates so they can set up Claude Code integration
4. Consider upgrading maturity tier to `mid` after 2–3 sprints of use
```

---

### Example 3: Existing Install — Reconfigure Maturity Tier

**User says:** "We want to upgrade from Early to Mid maturity."

**Result:**

```
## Dev.IQ Bootstrap — reconfigure
Detected: version 1.0.0, mode: committed, current tier: early

Reconfiguring maturity tier from early → mid.

What changes at Mid maturity:
- Structured reports replace coaching notes (more concise output)
- High security findings block PR verdict (advisory at Early)
- PR readiness verdict moves from draft to suggest-only mode
- DI routing operates as designed (not advisory)
- Risk assessment produces structured reports (not simplified)

Updating .dev-iq/config.yaml: maturity.tier: mid ✓
Updating .dev-iq/maturity-profile.md: tier: mid ✓

### Next Steps

1. Re-run `/review-pr-readiness` on an existing PR to see the Mid maturity output
2. Confirm with the team that coaching notes are no longer needed before
   distributing the upgraded configuration
3. When High security findings are being consistently resolved pre-merge,
   consider upgrading to Higher maturity for autonomous PR verdicts
```

---

## Governance
- Never silently overwrite user files — the bootstrap script compares hashes
  and presents a conflict resolver if files differ; this behavior must be
  preserved in all install paths
- Trial mode files must never be added to `.gitignore` — they are added to
  `.git/info/exclude` only; the codebase `.gitignore` is never modified
- The install manifest (`.dev-iq/.install-manifest.json`) must be updated
  after every install, upgrade, and graduate operation
- All output carries a clear summary of what was installed and in what mode —
  no silent installs
- Configuration values set during bootstrap determine the behavior of all
  other skills — prompt carefully and explain the consequence of each value
- The smoke test is required after every fresh install — if it fails, the
  bootstrap is not complete; diagnose and resolve before reporting success

## Related Skills
- `/explain-code` — the first skill to run as a smoke test after bootstrap;
  verifies the INTENT signal layer is operational
- `/review-pr-readiness` — run on an existing PR after bootstrap to validate
  the full four-layer DI assessment is working
- `/generate-user-stories` — run with a recent feature request to verify
  INTENT-layer story generation is configured correctly
- `/review-acceptance-criteria` — use after bootstrapping to begin applying
  DI signal to the existing backlog; a good first workflow for new teams
