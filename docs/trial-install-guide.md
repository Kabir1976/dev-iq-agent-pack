# Dev.IQ — Personal Trial Install Guide

This is a personal trial install — just you, invisible to the rest of the
team until you decide to share it. The whole thing should take under 20 minutes.

---

## Before you start (Windows checklist)

Run through this before anything else. These are the most common blockers
on corporate Windows machines.

**1. Check your PowerShell execution policy**

Open PowerShell and run:
```powershell
Get-ExecutionPolicy -Scope CurrentUser
```

If it returns `Restricted` or `AllSigned`, scripts are blocked. Fix it with:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

If you get an "Access denied" error, your machine is managed by Group Policy —
speak to the person who sent you this guide before proceeding.

**2. Unblock the zip contents**

Files extracted from a zip downloaded off the internet are flagged by Windows
and will be blocked from running. After extracting the zip, run this once:
```powershell
Get-ChildItem "C:\Tools\dev-iq" -Recurse | Unblock-File
```

**3. Check your IDE version**

- **VS Code:** requires 1.99 or later + GitHub Copilot Chat extension v0.22 or later. Check: `Help → About`.
- **Visual Studio 2022:** requires v17.14 or later. Check: `Help → About`.

If you're behind, update before continuing.

**4. Visual Studio 2022 only — enable repository instructions**

This step is easy to miss and blocks everything if skipped.

In Visual Studio: **Tools → Options → GitHub → Copilot → (General)**  
Turn on **"Enable repository custom instructions"** and click OK.

Without this, the DI reasoning layer (copilot-instructions.md) never loads,
and Dev-IQ will respond like a generic Copilot agent with no DI context.

**5. Confirm you can create an ADO Personal Access Token**

Go to your ADO org → top-right avatar → **Personal access tokens**. If you can
see this page, you're fine. If it's blocked, MCP won't connect to ADO — skills
will still work, they'll just ask you to paste work item details rather than
fetching them automatically.

---

## What you need

- **VS Code 1.99+** with GitHub Copilot Chat extension v0.22+ (agent mode enabled)  
  **— or —**  
  **Visual Studio 2022 v17.14+** with GitHub Copilot extension (latest)
- Git on your PATH (`git --version` in a terminal should work)
- The dev-iq zip I sent you

> **Visual Studio 2022 one-time setup:** After install, go to  
> **Tools → Options → GitHub → Copilot → (General)** and enable  
> **"Enable repository custom instructions"** — otherwise the DI reasoning layer won't load.

---

## Step 1 — Extract the zip

Unzip to a permanent location:
```
C:\Tools\dev-iq\
```

Then run the Unblock-File command from the checklist above if you haven't already.

---

## Step 2 — Run bootstrap in trial mode

Open PowerShell and run:
```powershell
powershell -File "C:\Tools\dev-iq\scripts\bootstrap.ps1" -Target "C:\path\to\your-ups-repo" -Preset solo
```

Replace `C:\path\to\your-ups-repo` with the actual path to the UPS repo on
your machine.

When it asks **"Just you, or the whole team?"** — answer **[1] Just me**.

Trial mode means the files are invisible to git. Nothing gets committed,
nothing touches the team's repo or anyone else's machine.

---

## Step 3 — Fill in the config

Open `.dev-iq\config.yaml` inside the UPS repo and fill in what you know:

```yaml
client:
  name: "[your client name]"

tracker:
  type: "ado"
  ado:
    org_url: ""    # e.g. https://dev.azure.com/your-org
    project: ""    # e.g. YourProjectName

vcs:
  type: "ado-repos"

stack:
  languages:
    - ""           # e.g. csharp, typescript, java
```

Leave anything you're unsure of blank — skills still work, they'll just ask
you for the details inline.

---

## Step 4 — Wire your ADO credentials (optional but recommended)

This lets skills pull live work item data from ADO without you having to paste it.

**Create a Personal Access Token in ADO:**
- ADO → top-right avatar → Personal access tokens → New Token
- Scopes needed: **Work Items (Read)**, **Code (Read)**, **Pull Request Threads (Read & Write)**
- Copy the token — you won't see it again

**Connect in VS Code:**
- Open Copilot Chat
- VS Code will prompt for `ADO_ORG_URL` and `ADO_PAT` the first time a skill needs them
- Enter your org URL (e.g. `https://dev.azure.com/my-org`) and the token
- VS Code stores both in your OS keychain — you won't be asked again

**Note on Node.js:** MCP servers require Node.js 18+. If you don't have it,
skip this step — skills fall back to paste mode automatically. You can wire
MCP later once Node.js is available.

---

## Step 5 — Verify it's working

**VS Code:**
Open the UPS repo. Open Copilot Chat (`Ctrl+Alt+I`). Look for **Dev-IQ** in
the agent dropdown at the top of the chat panel. Select it, then run:
```
/explain-code
```

**Visual Studio 2022:**
Open the UPS repo. Open Copilot Chat (`Alt+/`). Type `@Dev-IQ` to invoke the
agent — it should autocomplete. Then type:
```
/explain-code
```

**Claude Code:**
Open the UPS repo in a terminal. Type `/` to see available skills — you should
see the Dev.IQ skills listed. Then run:
```
/explain-code
```

**Pass for any IDE:** Point the skill at any source file. If the response
includes a **Purpose** section and an **INTENT signal** verdict — you're live.

**If Dev-IQ does not appear / `@Dev-IQ` does not autocomplete:** this is the
most important thing to report back. In Visual Studio, also confirm you enabled
**"Enable repository custom instructions"** in Tools → Options (see prerequisites
above). Note your IDE version and Copilot extension version (`Help → About`)
and send that to the person who gave you this guide.

**If skills appear but hooks are silent:** Open `.claude/settings.json` in the
UPS repo and confirm the `hooks` section is present. If it is missing, re-run
bootstrap. If present but hooks still don't fire, check that you are on
Dev.IQ v0.11.0 — earlier versions had incorrect hook event names that caused
silent failures.

---

## What bootstrap wired (and what it didn't)

Bootstrap installs every file to disk, but a few surfaces only load when they
are in the right place. If something feels off, check these first:

| Surface | Where it must live | What breaks if missing |
|---------|-------------------|------------------------|
| `copilot-instructions.md` | `.github/` in the UPS repo | Dev-IQ behaves like a generic Copilot agent — no DI context |
| `CLAUDE.md` | UPS repo root | Dev-IQ in Claude Code has no DI reasoning layer |
| `.dev-iq/` | UPS repo root | Skills can't read your stack config or maturity tier |
| `.claude/settings.json` | UPS repo root | Hindsight Hooks don't fire at session start/end |

Bootstrap creates all of these during install. If one is missing, re-run
bootstrap with `-Preset solo` — it is safe to run multiple times.

---

## Step 6 — Try a real skill

Open a branch with recent changes and run:

```
/review-pr-readiness
```

You should get a four-layer assessment — Intent, Design, Quality, Risk — with
a Go / Hold / Discuss recommendation. This is the core of what Dev.IQ does.

---

## Skills worth trying over the next 2–3 days

| When | Skill to try |
|------|-------------|
| Looking at an unfamiliar file | `/explain-code` |
| Before opening a PR | `/review-pr-readiness` |
| Reviewing someone else's code | `/code-review` |
| Something breaks | `/debug-issue` |
| Starting a new feature | `/generate-user-stories` |

---

## Removing the pack

If you want to uninstall, run bootstrap with the uninstall flag from the
Dev.IQ folder:

```powershell
powershell -File "C:\Tools\dev-iq\scripts\bootstrap.ps1" -Target "C:\path\to\your-ups-repo" -Uninstall
```

```bash
# macOS / Linux
bash /path/to/dev-iq/scripts/bootstrap.sh --target /path/to/your-ups-repo --uninstall
```

Uninstall reads the install manifest and restores any files that existed before
the pack was installed. Files you edited post-install (config.yaml, governance.md)
are saved as `<file>.di.uninstall-saved` so nothing is silently lost.

For trial mode: the `.git/info/exclude` block is also removed so the files
become visible to git again (useful if you decide to commit them later).

---

## Security — what stays on your machine

- No source code or repository content is sent anywhere beyond what GitHub
  Copilot already sends to the LLM provider when you use Copilot Chat normally.
- ADO credentials are stored in the Windows Credential Manager (OS keychain)
  by VS Code — never written to any file, never committed.
- The filesystem MCP server only reads files inside the repo folder you have
  open in VS Code. It cannot access anything outside that folder.
- Trial mode files are local-only. Nothing is committed to the shared repo.
- See `.dev-iq\governance.md` for the full data boundary statement.

---

## Feedback after 2–3 days

Send a short report back using these prompts — the more specific, the more useful.

**Install experience**
- Did the bootstrap run without errors on the first try? If not, what error appeared and at which step?
- Did the Dev-IQ agent appear in the Copilot Chat dropdown? (Step 5)
- Did you need to change your PowerShell execution policy? Was that step clear?

**Skill quality**
- Which skills did you try? (`/explain-code`, `/review-pr-readiness`, `/code-review`, etc.)
- Did the output feel useful and specific to your code, or generic?
- Did any skill produce output that was wrong, confusing, or unhelpful — and if so, what did you ask and what did it say?

**MCP / live data**
- Did you wire the ADO credentials (Step 4)? If yes, did work item pull work?
- If you skipped MCP, did the paste-mode fallback feel usable?

**One overall rating** (optional but useful)
> "I would / would not recommend this to a teammate on this project because _______"

Reply directly to the person who sent you this guide. No formal write-up needed — bullet points are fine.
