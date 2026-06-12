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

**3. Check your VS Code version**

The Dev-IQ agent requires VS Code 1.99 or later and GitHub Copilot Chat
extension v0.22 or later. Check: `Help → About` in VS Code.

If you're behind on either, update before continuing.

**4. Confirm you can create an ADO Personal Access Token**

Go to your ADO org → top-right avatar → **Personal access tokens**. If you can
see this page, you're fine. If it's blocked, MCP won't connect to ADO — skills
will still work, they'll just ask you to paste work item details rather than
fetching them automatically.

---

## What you need

- VS Code with GitHub Copilot Chat (agent mode enabled)
- Git on your PATH (`git --version` in a terminal should work)
- The dev-iq zip I sent you

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
powershell -File "C:\Tools\dev-iq\scripts\bootstrap.ps1" -Target "C:\path\to\your-repo" -Mode trial
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

Open the UPS repo in VS Code. Open Copilot Chat and select **Dev-IQ** from
the agent dropdown. Run:

```
/explain-code
```

Point it at any source file. If it comes back with a **Purpose** section and
an **INTENT signal** verdict, you're live.

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

No formal report needed. Just a quick message with:
- Did the install work first try, or did you hit something?
- Did the skill outputs feel useful or generic?
- Anything that surprised you — good or bad?

Reach out to the person who sent you this guide with any questions.
