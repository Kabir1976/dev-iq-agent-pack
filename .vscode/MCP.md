# MCP Server Setup Guide

## Security boundary — read this first

Dev.IQ MCP servers are IDE-resident. They do not transmit data outside
your machine beyond what GitHub Copilot already sends to the configured
LLM provider.

**Credentials are never written to `mcp.json`, never committed, and never
logged.** VS Code's `${input:NAME}` mechanism prompts you once and stores
the value in your operating system's keychain — the same store used by
your browser and password manager. To clear a stored credential:
`Ctrl+Shift+P` → **MCP: Clear Stored Inputs**.

The `filesystem` server is scoped to the path you enter at first prompt —
default `${workspaceFolder}`. It cannot read files outside that path.

---

## How the 20-server catalog works

`mcp.json` declares 20 MCP servers — one for every common tracker, VCS
host, database, observability tool, and collaboration platform. All servers
are declared in the flat `servers` object; **none are disabled by default**.

VS Code only prompts for credentials the first time a skill actually needs a
given server. If you never use Datadog, the Datadog server never activates
and you are never prompted. You do not need to delete or comment out servers
you don't use.

**Which servers you need depends on your stack** (`config.yaml` → `tracker.type`,
`vcs.type`, `signals.quality.*`). The table below shows common combinations:

| Your stack | Essential servers |
|------------|-----------------|
| ADO + GitHub repos | `azure-devops` + `github` + `filesystem` + `git` |
| ADO + ADO repos | `azure-devops` + `filesystem` + `git` |
| Jira + GitHub | `atlassian` + `github` + `filesystem` + `git` |
| Jira + GitLab | `atlassian` + `gitlab` + `filesystem` + `git` |
| GitHub Issues | `github` + `filesystem` + `git` |
| No tracker yet | `filesystem` + `git` — skills fall back to paste mode |

Add observability servers (`sentry`, `grafana`, `datadog`, `honeycomb`) when
you want `/debug-issue` to pull live error events automatically.

---

## Server reference

### Tracker — pick one that matches `tracker.type` in config.yaml

#### `azure-devops` — ADO work items, PRs, boards

**Prerequisites:** Node.js 18+

| Input | Description |
|-------|-------------|
| `ado_org` | `https://dev.azure.com/YOUR-ORG` |
| `ado_pat` | ADO Personal Access Token — Work Items (Read/Write), Code (Read), PR Threads (Read/Write) |

**Unlocks:** `/generate-user-stories`, `/review-acceptance-criteria`, `/review-pr-readiness`, `/generate-traceability-matrix` reading live ADO data.

**Troubleshooting:**
- *"401 Unauthorized"*: PAT expired or wrong scope — regenerate with the permissions above.
- *"Work item not found"*: Check `config.yaml` project name matches exactly (case-sensitive).
- *Skill says "no work item linked"*: Pass the ID explicitly: `/review-pr-readiness AB#1234`.

---

#### `atlassian` — Jira work items and Confluence pages

**Prerequisites:** Node.js 18+

| Input | Description |
|-------|-------------|
| `jira_base_url` | `https://your-org.atlassian.net` |
| `jira_api_token` | Jira → Account settings → Security → API tokens |
| `jira_email` | Your Atlassian account email |

**Config alignment:**
```yaml
tracker:
  type: "jira"
  jira:
    base_url: "https://your-org.atlassian.net"
    project_key: "PROJ"
```

---

### VCS — pick one that matches `vcs.type` in config.yaml

#### `github` — GitHub PRs and repo context

**Prerequisites:** Node.js 18+ (uses Copilot MCP HTTP endpoint — no npx)

| Input | Description |
|-------|-------------|
| `github_pat` | GitHub PAT (classic) with `repo` + `pull_requests: write` scopes |

**Unlocks:** `/review-pr-readiness` (PR diff), `/new-pull-request` (creates PR with DI risk band), `/blast-radius-estimator` (repo graph).

---

#### `gitlab` — GitLab MRs and repo context

**Prerequisites:** Node.js 18+

| Input | Description |
|-------|-------------|
| `gitlab_pat` | GitLab personal access token (`api` scope) |
| `gitlab_api_url` | `https://gitlab.com/api/v4` (or your self-hosted URL) |

---

#### `bitbucket` — Bitbucket PRs and repo context

**Prerequisites:** Node.js 18+

| Input | Description |
|-------|-------------|
| `bitbucket_workspace` | Bitbucket workspace slug |
| `bitbucket_email` | Your Bitbucket account email |
| `bitbucket_app_password` | Bitbucket app password with `pull_requests: read/write` |

---

### Local VCS

#### `git` — git log, blame, and diff (always recommended)

**Prerequisites:** Python 3.10+ and `uv` (`brew install uv` or `pip install uv`)

No credentials — reads your local `.git` directory. Scoped to `${workspaceFolder}`.

**Unlocks:** `/blast-radius-estimator` (change history), `/generate-release-notes` (commit graph).

---

### Filesystem

#### `filesystem` — workspace file tree access

**Prerequisites:** Node.js 18+

| Input | Description |
|-------|-------------|
| `fs_allowed_path` | Path the server may read/write — defaults to `${workspaceFolder}` |

No credentials. Scoped to the path you enter at first prompt.

**Unlocks:** `/explain-code`, `/review-architecture`, `/blast-radius-estimator` traversing the full repo without relying only on diff context.

---

### Database

#### `postgres` — Postgres schema and query context

**Prerequisites:** Node.js 18+

| Input | Description |
|-------|-------------|
| `pg_connection_string` | `postgresql://user:pass@host:5432/dbname` |

Useful for `/design-data-model` (schema awareness) and `/code-review` (ORM vs raw query patterns).

---

#### `sqlite` — SQLite file access

**Prerequisites:** Python 3.10+ and `uv`

| Input | Description |
|-------|-------------|
| `sqlite_db_path` | Absolute path to the `.db` file |

---

### Cloud

#### `aws` — AWS resource context

**Prerequisites:** Python 3.10+ and `uv`, with AWS CLI configured

| Input | Description |
|-------|-------------|
| `aws_profile` | Named profile from `~/.aws/credentials` |
| `aws_region` | AWS region (e.g. `us-east-1`) |

---

### Observability

#### `sentry` — live error events

**Prerequisites:** Python 3.10+ and `uv`

| Input | Description |
|-------|-------------|
| `sentry_token` | Sentry auth token (Settings → Auth tokens → Create new) |
| `sentry_org` | Your org slug from the Sentry URL |

**Unlocks:** `/debug-issue` reads recent Sentry events for the affected service before diagnosing.

---

#### `grafana` — dashboards and alerts

**Prerequisites:** Node.js 18+

| Input | Description |
|-------|-------------|
| `grafana_url` | Grafana base URL |
| `grafana_api_key` | Grafana API key (Service accounts → Add service account token) |

---

#### `datadog` — metrics, logs, and traces

**Prerequisites:** Node.js 18+

| Input | Description |
|-------|-------------|
| `dd_api_key` | Datadog API key |
| `dd_app_key` | Datadog application key |
| `dd_site` | `datadoghq.com` (or `datadoghq.eu` etc.) |

---

#### `honeycomb` — distributed traces

**Prerequisites:** Node.js 18+

| Input | Description |
|-------|-------------|
| `honeycomb_api_key` | Honeycomb API key |

---

### Browser automation

#### `playwright` / `puppeteer` — web automation

**Prerequisites:** Node.js 18+. No credentials.

Useful for `/debug-issue` when the error is a UI-layer rendering problem.

---

### Knowledge bases

#### `notion` — Notion pages and databases

**Prerequisites:** Node.js 18+

| Input | Description |
|-------|-------------|
| `notion_headers` | JSON string: `{"Authorization": "Bearer secret_...", "Notion-Version": "2022-06-28"}` |

---

#### `confluence` — Confluence pages (uses Atlassian credentials)

**Prerequisites:** Python 3.10+ and `uv`. Reuses `jira_base_url`, `jira_email`, `jira_api_token` inputs — supply once, shared with `atlassian`.

---

### Communication

#### `slack` — Slack channels and messages

**Prerequisites:** Node.js 18+

| Input | Description |
|-------|-------------|
| `slack_bot_token` | Bot token (`xoxb-...`) from your Slack app |
| `slack_team_id` | Slack workspace ID (visible in the workspace URL) |

---

#### `teams` — Microsoft Teams channels

**Prerequisites:** Node.js 18+

| Input | Description |
|-------|-------------|
| `teams_app_id` | Azure AD app (client) ID |
| `teams_app_password` | Azure AD app client secret |
| `teams_tenant_id` | Microsoft Entra tenant ID |

---

## How `${input:variable}` works

VS Code Copilot Chat processes `${input:NAME}` variables in `mcp.json` at
startup. The first time an MCP server is activated, VS Code opens a prompt
for each `input:` variable in that server's config. The value is stored in
the OS keychain under a key derived from the workspace folder — it is never
written to disk or to `mcp.json` itself.

To reset a stored credential: `Ctrl+Shift+P` → **MCP: Clear Stored Inputs**.

---

## Verifying a server is connected

In Copilot Chat, type `/` and look for tools with an MCP badge. To confirm:

```
@Dev-IQ use the azure-devops tool to read work item AB#1
```

If the server is connected, it returns the work item. If not, it names the
missing credential so you know exactly what to supply.
