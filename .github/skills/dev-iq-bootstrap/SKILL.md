---
name: dev-iq-bootstrap
description: Guide the installation and configuration of the Dev.IQ Agent Pack into a new workspace. Use when asked to "install Dev.IQ", "bootstrap Dev.IQ", "set up Dev.IQ", or "configure Dev.IQ for this project".
di_signal: —
maturity_required: early
status: approved
---

# Dev.IQ Bootstrap

## Overview
Installs the Dev.IQ Agent Pack into the current workspace. The script
auto-detects language, framework, tracker, and VCS from the project
files and git remote — so there is nothing to fill in except the
client name. This skill calls the bootstrap script, asks one question
if running interactively, and ends with a single clear next step.

## When to Use
- First-time install of Dev.IQ into any project
- Upgrading a trial install to team-visible (committed) mode
- Any time the user says: "install Dev.IQ", "bootstrap", "set up Dev.IQ",
  "onboard this repo to Dev.IQ", "configure Dev.IQ"

---

## Step 1 — Detect Existing Installation

Check for `.dev-iq/.install-manifest.json`:

**Already installed:**
- Read the manifest: version, mode, installed_at.
- If the user wants to upgrade or graduate: run `scripts/bootstrap.sh --graduate`
  (or `scripts/bootstrap.ps1 -Graduate` on Windows). Done.
- If the user wants to upgrade the pack version: run `scripts/bootstrap.sh`.

**Not installed — proceed to Step 2.**

---

## Step 2 — Auto-Detect (run silently, no output to user)

Read the following from the workspace; do not ask the user for these:

| What | How |
|------|-----|
| Tracker | git remote URL — `dev.azure.com` → ado, `github.com` → github-issues |
| VCS | git remote URL — github / ado-repos / gitlab / bitbucket |
| ADO org + project | regex on `dev.azure.com/{org}/{project}` |
| Language | `package.json` → typescript/javascript; `requirements.txt` → python; `pom.xml` → java; `*.csproj` → csharp; `go.mod` → go; `Gemfile` → ruby; `Cargo.toml` → rust |
| Framework | `package.json` deps: next → nextjs, react, angular, vue, nestjs, express; `requirements.txt`: fastapi, django, flask |

The bootstrap script performs this detection automatically and pre-fills
`config.yaml`. Do not re-ask the user for anything that can be derived.

---

## Step 3 — One Question

The only thing that cannot be auto-detected is the client name. Ask:

> What is the client or project name?

Use the answer to set `config.yaml` → `client.name` after the script runs.
If no useful answer is given, skip and the user can fill it in later.

---

## Step 4 — Run Bootstrap

**macOS / Linux:**
```bash
bash scripts/bootstrap.sh
```
The script will ask one question interactively:
> "Just you, or the whole team? [1] Just me  [2] Whole team (default: 1)"

**Windows:**
```powershell
.\scripts\bootstrap.ps1
```

If `scripts/` does not exist: the Dev.IQ pack has not been cloned yet.
Instruct the user to clone it first:
```bash
git clone https://github.com/your-org/dev-iq.git /tmp/dev-iq
bash /tmp/dev-iq/scripts/bootstrap.sh --target .
```

---

## Step 5 — Apply Client Name

After the script exits:
```bash
python3 -c "
import re, sys
path = '.dev-iq/config.yaml'
with open(path) as f: t = f.read()
t = re.sub(r'(name:\s*)\"\"', r'\g<1>\"' + sys.argv[1] + '\"', t, count=1)
with open(path, 'w') as f: f.write(t)
" "CLIENT_NAME_HERE"
```

---

## Step 6 — Verify and Smoke Test

Confirm these files exist:
- `.dev-iq/config.yaml` — check language, framework, tracker are populated
- `.dev-iq/.install-manifest.json` — version and mode recorded
- `.github/skills/` — skill definitions present

Then run `/explain-code` on any file. If it returns a Purpose + INTENT signal
verdict, the install is working.

---

## Output Format

Keep the completion message to three lines:

```
Dev.IQ [version] is ready.
Open Copilot Chat, select Dev-IQ, type /explain-code. That's it.

Detected: [language] / [framework] | [tracker]
```

Do not produce a checklist, a configuration table, or a multi-section report
unless the user explicitly asks for more detail. The install either worked or
it did not.

If it did not work: report the exact error from the script output and the one
command needed to resolve it.

@di-review-required

---

## Upgrade / Graduate

| Command | What it does |
|---------|-------------|
| `bash scripts/bootstrap.sh --graduate` | Move trial files into git tracking |
| `bash scripts/bootstrap.sh` | Upgrade pack version in place |
| `bash scripts/bootstrap.sh --uninstall` | Remove all Dev.IQ files |

---

## Governance
- Never silently overwrite user files — bootstrap script preserves existing
  files via SHA256 compare and conflict resolver
- Trial mode uses `.git/info/exclude` only — the codebase `.gitignore` is
  never modified
- Manifest must be written after every install, upgrade, and graduate

## Related Skills
- `/explain-code` — first smoke test after install
- `/review-pr-readiness` — validate four-layer assessment end-to-end
