# MCP Server Setup Guide

## Security boundary — read this first

Dev.IQ MCP servers are IDE-resident. They do not transmit data outside
your machine beyond what GitHub Copilot already sends to the configured
LLM provider.

| Credential | How it is stored | Where it goes |
|-----------|-----------------|---------------|
| ADO Personal Access Token | OS keychain (VS Code secure input) | Sent only to your ADO org over HTTPS |
| GitHub PAT | OS keychain (VS Code secure input) | Sent only to github.com over HTTPS |

**Credentials are never written to `mcp.json`, never committed, and never
logged.** VS Code's `${input:NAME}` mechanism prompts you once and stores
the value in your operating system's keychain — the same store used by
your browser and password manager. To clear a stored credential:
`Ctrl+Shift+P` → **MCP: Clear Stored Inputs**.

The `filesystem` server is scoped to `${workspaceFolder}` — it cannot
read files outside the repository you have open in VS Code.

---

This guide covers credential setup for each MCP server declared in
`.vscode/mcp.json`. Three servers are **enabled by default** for a
standard ADO + GitHub shop. The rest are pre-configured but disabled —
move them into `mcpServers` when you need them.

---

## Which servers do I need?

| Your setup | Enable these servers |
|------------|---------------------|
| ADO work items + GitHub repos | `azure-devops` + `github` + `filesystem` |
| ADO work items + ADO repos | `azure-devops` + `filesystem` |
| Jira + GitHub | `jira` (from `_disabled_servers`) + `github` + `filesystem` |
| No tracker yet | `filesystem` only — skills fall back to paste mode |

---

## Enabled by default

### `azure-devops` — ADO work items and PRs

**What it unlocks:**
- `/generate-user-stories` reads ACs directly from ADO work items
- `/review-acceptance-criteria` pulls the work item's ACs for validation
- `/review-pr-readiness` fetches the PR diff and linked work item automatically
- `/generate-traceability-matrix` reads requirement → code linkage from ADO

**Prerequisites:** Node.js 18+ (for `npx`)

**Credentials:**

| Variable | What it is | Where to get it |
|----------|-----------|-----------------|
| `ADO_ORG_URL` | Your org URL | `https://dev.azure.com/YOUR-ORG` |
| `ADO_PAT` | Personal Access Token | ADO → User settings → Personal access tokens |

**PAT permissions required:**
- Work Items: Read & write
- Code: Read (if using ADO Repos)
- Pull Request Threads: Read & write

**VS Code setup:**
1. Open a Copilot Chat session — VS Code will prompt for both values.
2. Enter the org URL (e.g. `https://dev.azure.com/my-org`) and the PAT.
3. VS Code stores both in your OS keychain — you won't be asked again.

**Claude Code setup:**
```bash
# Add to your shell profile or .env (never commit):
export ADO_ORG_URL="https://dev.azure.com/my-org"
export ADO_PAT="your-pat-here"
```

**Config alignment:** Set these in `.dev-iq/config.yaml`:
```yaml
tracker:
  type: "ado"
  ado:
    org_url: "https://dev.azure.com/my-org"
    project: "MyProject"
```

**Troubleshooting:**
- *"401 Unauthorized"*: PAT expired or wrong scope — regenerate with the permissions above.
- *"Work item not found"*: Check the project name in `config.yaml` matches exactly (case-sensitive).
- *Skill says "no work item linked"*: The PAT is valid but the skill couldn't find an ADO link in the branch name or PR. Pass the work item ID explicitly: `/review-pr-readiness AB#1234`.

---

### `github` — GitHub PRs and repo context

**What it unlocks:**
- `/review-pr-readiness` fetches the PR diff from GitHub without paste
- `/new-pull-request` creates the PR with the DI risk band pre-filled
- `/blast-radius-estimator` can traverse the full repo graph

**Prerequisites:** Node.js 18+

**Credentials:**

| Variable | What it is | Where to get it |
|----------|-----------|-----------------|
| `GITHUB_PAT` | Personal Access Token (classic) | GitHub → Settings → Developer settings → Personal access tokens |

**PAT scopes required:** `repo` (full repo access), `pull_requests: write`

**VS Code setup:**
1. Open Copilot Chat — VS Code prompts for the token.
2. Paste your PAT — stored in OS keychain.

**Claude Code setup:**
```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_..."
```

**Config alignment:**
```yaml
vcs:
  type: "github"
```

**Troubleshooting:**
- *"Resource not accessible by integration"*: PAT scope too narrow — add `repo`.
- *PR tool not appearing*: Confirm `vcs.type = github` in `.dev-iq/config.yaml`.

---

### `filesystem` — workspace file tree access

**What it unlocks:**
- `/explain-code` can read any file in the repo, not just what's pasted
- `/blast-radius-estimator` traverses the full directory tree
- `/review-architecture` can read actual config and structure files

**Prerequisites:** Node.js 18+

**Credentials:** None — scoped to `${workspaceFolder}` automatically.

**VS Code setup:** Works immediately after the pack is installed. No prompts.

**Troubleshooting:**
- *"Access denied"*: The server is scoped to the workspace folder opened in VS Code. Open the root of the repo, not a subfolder.

---

## Disabled by default (move into `mcpServers` to enable)

### `jira` — Jira work items

**Use instead of `azure-devops` when your tracker is Jira.**

**Prerequisites:** Node.js 18+

| Variable | What it is |
|----------|-----------|
| `JIRA_BASE_URL` | `https://your-org.atlassian.net` |
| `JIRA_EMAIL` | Your Atlassian account email |
| `JIRA_API_TOKEN` | Jira → Account settings → Security → API tokens |

**Config alignment:**
```yaml
tracker:
  type: "jira"
  jira:
    base_url: "https://your-org.atlassian.net"
    project_key: "PROJ"
```

---

### `git` — git log and blame

**Useful for:** `/blast-radius-estimator` (change history) and
`/generate-release-notes` (commit graph).

**Prerequisites:** Python 3.10+ and `uv` (`brew install uv` or `pip install uv`)

No credentials — reads your local git repo.

---

### `sentry` — live error events

**Useful for:** `/debug-issue` — agent reads recent Sentry events for
the affected service before diagnosing.

**Prerequisites:** Node.js 18+

| Variable | What it is |
|----------|-----------|
| `SENTRY_AUTH_TOKEN` | Sentry → Settings → Auth tokens → Create new |
| `SENTRY_ORG_SLUG` | Your org slug from the Sentry URL |

---

## How `${input:VARIABLE}` works

VS Code Copilot Chat processes `${input:NAME}` variables in `mcp.json` at
startup. The first time an MCP server is used, VS Code opens a prompt for
each `input:` variable in that server's env block. The value is stored in
the OS keychain under a key derived from the workspace folder — it is never
written to disk or to `mcp.json` itself.

To reset a stored credential: `Cmd+Shift+P` → **Keychain: Clear MCP Secrets**.

---

## Verifying a server is connected

In Copilot Chat, type `/` and look for tools with an MCP badge. You can also
run a direct tool call to confirm:

```
@Dev-IQ use the azure-devops tool to read work item AB#1
```

If the server is connected, it returns the work item. If not, it returns a
connection error that usually names the missing credential.
