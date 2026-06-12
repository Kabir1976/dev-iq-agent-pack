# Dev.IQ Governance

**Pack version:** 0.9.0
**Maturity tier:** Early
**Review cadence:** Quarterly or after a major delivery milestone

---

## Data Boundary

This is the most important section. Dev.IQ is an IDE-resident pack — it does
not run as a service and it does not transmit data outside the IDE boundary.

| What stays inside | Detail |
|-------------------|--------|
| Source code | Never sent to any external system. The agent reads what is open in the IDE. |
| ADO credentials | Stored in the OS keychain by VS Code. Never written to `mcp.json` or any file on disk. Never committed. |
| Repository content | MCP filesystem server is scoped to `${workspaceFolder}` — it cannot read files outside the open repo. |
| Session state | Hook scripts write only to `hooks/state/` inside this workspace. Nothing is transmitted. |

**What does leave the IDE:** The text of your prompt and any context you explicitly
include (e.g. a code snippet you paste, or a file the agent reads at your
instruction) is sent to the configured LLM provider (GitHub Copilot / Azure OpenAI)
over your organisation's standard HTTPS connection. This is identical to what
happens when you use Copilot Chat without Dev.IQ.

---

## AI Output Controls

- Every skill output carries `@di-review-required`. No generated code is applied
  to the repository without explicit developer approval — the agent proposes, the
  developer decides.
- All outputs are advisory drafts at **Early** maturity. No autonomous verdicts.
- Security findings rated **Critical** or **High** always block the PR readiness
  verdict — no override regardless of delivery pressure or maturity tier.

---

## Access Controls

| Control | Setting |
|---------|---------|
| AI merge without human review | Disabled (`allow_ai_merge_without_review: false`) |
| New dependencies without confirmation | Blocked (`allow_new_dependencies: false`) |
| Secrets in prompts | Masked (`mask_secrets_in_prompts: true`) |
| Traceability required | Yes — every generated artifact must reference its work item |

---

## Traceability

- All generated code artifacts must reference the source ADO work item (`AB#XXXX`)
  when one is available.
- PRs without a linked work item are flagged as a Risk finding at Medium severity.
- A traceability matrix can be generated on demand with `/generate-traceability-matrix`.

---

## Maturity Gate

**Current tier: Early** — all outputs are advisory. Human review is required
for every output before it is used. Blast radius estimation is disabled.

Re-evaluate tier in `.dev-iq/maturity-profile.md` after 30 days of pilot use.

---

## What Dev.IQ Does Not Do

- Does not run as a service — no server to deploy, no background process.
- Does not store conversation history beyond the current IDE session.
- Does not modify CI/CD pipelines automatically — all CI changes require developer review.
- Does not write to any system outside the local workspace.
- Does not share data between workspaces or users.
