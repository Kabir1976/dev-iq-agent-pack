# Dev.IQ Agent Pack — Installation Guide

Version: 0.9.0 | Applies to: VS Code + GitHub Copilot Chat, Claude Code

---

## Prerequisites

Before you start, confirm the following are in place:

| Requirement | Minimum version | Check |
|-------------|----------------|-------|
| Git | 2.x | `git --version` |
| Python | 3.8+ | `python3 --version` |
| VS Code | 1.90+ | Help → About |
| GitHub Copilot Chat extension **or** Claude Code extension | Latest | VS Code Extensions panel |

You do **not** need admin rights to install Dev.IQ. It writes only into your project directory and (in trial mode) into `.git/info/exclude`.

---

## Step 1 — Get the Pack

### Option A: Download the pack

You will receive a zip file named `dev-iq-vX.Y.Z.zip`. Save it somewhere outside your project:

```
~/tools/dev-iq/     ← good
~/Downloads/        ← fine for a quick start
inside your repo    ← do not do this
```

Unzip it:

```bash
# macOS / Linux
unzip dev-iq-vX.Y.Z.zip -d ~/tools/dev-iq

# Windows (PowerShell)
Expand-Archive dev-iq-vX.Y.Z.zip -DestinationPath C:\tools\dev-iq
```

### Option B: Clone from GitHub

```bash
git clone https://github.com/Kabir1976/dev-iq ~/tools/dev-iq
```

---

## Step 2 — Run Bootstrap

Open a terminal and navigate to **your project repo** (not the dev-iq folder):

```bash
cd /path/to/your-project
```

Then run the bootstrap:

### Fast path — presets (recommended)

Use a preset to skip the interactive prompts:

| Preset | Who it's for | What it does |
|--------|-------------|-------------|
| `--preset=pod` | Team pod adoption | Committed mode + hooks enabled |
| `--preset=solo` | Individual developer trial | Trial mode (invisible to git), no hooks |
| `--preset=portable` | Client handoff / CI | Committed mode, no hooks |

**macOS / Linux:**
```bash
# Team adoption
bash ~/tools/dev-iq/scripts/bootstrap.sh --preset=pod

# Individual trial
bash ~/tools/dev-iq/scripts/bootstrap.sh --preset=solo

# Client handoff
bash ~/tools/dev-iq/scripts/bootstrap.sh --preset=portable
```

**Windows (PowerShell):**
```powershell
# Team adoption
.\tools\dev-iq\scripts\bootstrap.ps1 -Preset pod

# Individual trial
.\tools\dev-iq\scripts\bootstrap.ps1 -Preset solo

# Client handoff
.\tools\dev-iq\scripts\bootstrap.ps1 -Preset portable
```

### Manual mode selection

If you prefer to choose interactively, run without a preset — the script will prompt:

**macOS / Linux:**
```bash
bash ~/tools/dev-iq/scripts/bootstrap.sh
```

**Windows (PowerShell):**
```powershell
.\tools\dev-iq\scripts\bootstrap.ps1
```

The script will prompt you to choose an install mode:

```
[1] trial     — local only, completely invisible to git
[2] committed — files visible to git, team can commit them
```

**Choose trial** if you are evaluating Dev.IQ or want to test before sharing with your team. You can graduate to committed at any time (see Step 6).

**Choose committed** if the team has already agreed to adopt Dev.IQ and you want to commit the files in a PR.

---

## Step 3 — Configure for Your Project

Open `.dev-iq/config.yaml` in VS Code and fill in the values for your engagement:

```yaml
client:
  name: "Acme Corp"          # ← your client name
  engagement: "Modernisation Phase 1"
  engagement_lead: "Your Name"

maturity:
  tier: "early"              # ← early | mid | higher
                             #   start with early unless advised otherwise

tracker:
  type: "ado"                # ← ado | jira | github-issues
  ado:
    org_url: "https://dev.azure.com/acme"
    project: "Modernisation"

vcs:
  type: "github"             # ← github | ado-repos | gitlab | bitbucket
  default_branch: "main"

stack:
  languages: ["typescript"]  # ← your primary languages
  frameworks: ["react", "node"]
```

**Minimum required fields to fill before using skills:**
- `client.name`
- `maturity.tier`
- `tracker.type`
- `stack.languages`

Leave all other fields as defaults until you need them.

---

## Step 4 — Verify the Install

1. Open VS Code in your project folder
2. Open Copilot Chat (Ctrl+Alt+I) **or** the Claude Code panel
3. Select the **Dev-IQ** agent from the agent picker
4. Type `/` — you should see the list of available skills
5. Pick any file in your project and run:
   ```
   /explain-code
   ```
   You should receive a plain-language explanation of what the file does, structured with a DI INTENT signal assessment.

If the agent picker does not show Dev-IQ, reload VS Code (`Ctrl+Shift+P` → `Developer: Reload Window`) and try again.

---

## Step 5 — Update Dev.IQ

When a new version is available, unzip it to the same location (overwriting the old files), then re-run bootstrap against your project:

```bash
# macOS / Linux
bash ~/tools/dev-iq/scripts/bootstrap.sh --target=/path/to/your-project

# Windows
.\tools\dev-iq\scripts\bootstrap.ps1 -Target C:\path\to\your-project
```

The script detects the existing install, shows a version diff, and updates only the pack-owned files. Your `.dev-iq/config.yaml` and other configured files are never overwritten.

---

## Step 6 — Graduate from Trial to Committed (optional)

When your team is ready to commit Dev.IQ into the repository so everyone has it:

```bash
# macOS / Linux
bash ~/tools/dev-iq/scripts/bootstrap.sh --target=/path/to/your-project --graduate

# Windows
.\tools\dev-iq\scripts\bootstrap.ps1 -Target C:\path\to\your-project -Graduate
```

This removes the `.git/info/exclude` entries so git can see the Dev.IQ files. You then commit them as a normal PR:

```bash
cd /path/to/your-project
git add .github/skills/ .github/instructions/ .github/agents/ .claude/ .dev-iq/ CLAUDE.md
git commit -m "Add Dev.IQ Agent Pack v0.9.0"
git push
```

Open the PR with a short description — the team reviews and merges. From that point, every developer who pulls the branch gets Dev.IQ automatically.

---

## Step 7 — Uninstall Dev.IQ (optional)

To remove Dev.IQ from a project entirely:

**macOS / Linux:**
```bash
bash ~/tools/dev-iq/scripts/bootstrap.sh --uninstall
```

**Windows (PowerShell):**
```powershell
.\tools\dev-iq\scripts\bootstrap.ps1 -Uninstall
```

The uninstall script:
- Removes all pack-owned directories (`.github/skills/`, `.github/instructions/`, `.github/agents/`, `.claude/`, `.dev-iq/`)
- Strips the `<!-- dev-iq:start -->…`<!-- dev-iq:end -->` marker block from `CLAUDE.md` (preserves everything else in the file)
- Removes all trial-mode entries from `.git/info/exclude`
- Does **not** touch `CLAUDE.md` content outside the marker block, or any files you created yourself

After uninstall, commit the removed files if the install was in committed mode:

```bash
git add -A
git commit -m "Remove Dev.IQ Agent Pack"
git push
```

---

## Troubleshooting

### The Dev-IQ agent does not appear in Copilot Chat

- Confirm `.github/agents/Dev-IQ.agent.md` exists in your project
- Reload VS Code: `Ctrl+Shift+P` → `Developer: Reload Window`
- Check the Copilot Chat agent picker — agents load from `.github/agents/`

### The Dev-IQ agent does not appear in Claude Code

- Confirm `.claude/agents/dev-iq.md` exists in your project
- Restart Claude Code

### `/explain-code` runs but ignores DI instructions

- Check that `CLAUDE.md` in your project contains the `<!-- dev-iq:start -->` block
- Re-run bootstrap to repair it: the script will detect and update the marker block

### Bootstrap fails: "Target is not a git repository"

- Run `git init` in your project first, then re-run bootstrap

### Trial mode: git still shows dev-iq files as untracked

- Confirm `.git/info/exclude` contains the `# dev-iq` block
- Run `git status` — if files still appear, check that the paths in exclude match exactly
- Alternatively, add them to your `.gitignore` manually

### Windows: "running scripts is disabled"

Run PowerShell as Administrator and execute:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
Then re-run bootstrap.

---

## What Was Installed

| Location | Contents | Owned by |
|----------|----------|----------|
| `.github/skills/` | 21 skill definitions | Pack — updated on upgrade |
| `.github/instructions/` | 5 always-on instruction files | Pack — updated on upgrade |
| `.github/agents/` | Dev-IQ and Dev-IQ-PLAN agent specs | Pack — updated on upgrade |
| `.claude/agents/` | Claude Code agent definitions | Pack — updated on upgrade |
| `.claude/skills.md` | Skills index for Claude Code | Pack — updated on upgrade |
| `.dev-iq/config.yaml` | Your engagement configuration | You — never overwritten |
| `.dev-iq/governance.md` | Governance posture | You — never overwritten |
| `.dev-iq/maturity-profile.md` | Maturity tier rationale | You — never overwritten |
| `CLAUDE.md` (marker block) | DI reasoning instructions for Claude | Pack — marker block updated on upgrade, your content preserved |
| `.dev-iq/.install-manifest.json` | Install record (version, date, mode) | Generated — not committed |

---

## Ownership

Everything Dev.IQ needs is in the files above. No external service, no account required. The team can:

- Continue using the skills as-is
- Update by downloading a new zip and re-running bootstrap
- Modify skill definitions in `.github/skills/` to suit their evolving standards

---

*Dev.IQ Agent Pack v0.9.0*
