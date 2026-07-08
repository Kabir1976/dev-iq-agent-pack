# Dev.IQ — Governance Posture (client template)

**Pack version:** 0.12.0
**Review cadence:** Quarterly or after a major delivery milestone

<!-- =========================================================================
HOW TO USE THIS FILE
=====================
1. Work through each section top-to-bottom.
2. Replace every <PLACEHOLDER> with your project's actual value.
3. For the Compliance Posture table, set the "Applies" column to: yes | partial | no.
4. Delete rows for regimes, escalation triggers, or tools that do not apply
   to your project — shorter is better than incorrect.
5. Fill in the Human Review Gates, Escalation Paths, and Approval tables
   before your first AI-assisted delivery workflow is used in production.
6. Re-approve quarterly or on any material change to compliance posture.

The values here drive refusal, escalation, and review behavior across every
skill in the pack. If a section says "the agent must refuse", it will.
========================================================================= -->

---

## 1. Compliance Posture

Document the regulatory regimes and data classifications that apply to this
codebase. The agent uses this section to decide what it may read, write,
generate, and log without explicit human confirmation.

**Instructions:** set `yes` or `partial` for each regime that applies.
For every `yes` / `partial` row, fill in the sub-table below the main table.
Leave unaffected regimes as `no` (or delete the row entirely).

| Regime | Applies | Default implication |
|--------|---------|---------------------|
| HIPAA | `<yes \| partial \| no>` | No PHI in code snippets, prompts, signals, or logs. |
| PCI-DSS | `<yes \| partial \| no>` | No cardholder data; use project-provided test card prefixes only. |
| SOX | `<yes \| partial \| no>` | Audit trail required for every AI-modified artifact; release decisions documented. |
| GDPR | `<yes \| partial \| no>` | No personal data in code snippets, signals, or telemetry without a consent basis. |
| CCPA | `<yes \| partial \| no>` | Same as GDPR for California residents. |
| FedRAMP / FISMA | `<yes \| partial \| no>` | Boundary protection for AI tool access; review with InfoSec before enabling MCP. |
| ISO 27001 | `<yes \| partial \| no>` | Information security controls apply to AI-generated artifacts and logs. |
| Internal data classification | `<yes \| partial \| no>` | Set to the highest data class the repo handles (e.g. Public / Internal / Confidential / Restricted). |
| _`<Other regime>`_ | `<yes \| partial \| no>` | _`<Describe the implication for AI-generated artifacts.>`_ |

**For each `yes` or `partial` row, complete this block (copy once per regime):**

```
Regime: <name>
Data classes present: <e.g. PHI, PAN, PII, secrets>
Where they live: <paths, fixture dirs, config files, env vars>
Refusal pattern: The agent must refuse to read, write, generate, or paste
  content of this class without explicit human confirmation via
  <describe your confirmation mechanism, e.g. a /confirm command or PR comment>.
Exceptions: <any approved exceptions and who approved them>
```

---

## 2. Data Boundary

Dev.IQ is an IDE-resident pack — it does not run as a service and it does not
transmit data outside the IDE boundary.

| What stays inside | Detail |
|-------------------|--------|
| Source code | Never sent to any external system. The agent reads what is open in the IDE. |
| ADO credentials | Stored in the OS keychain by VS Code. Never written to `mcp.json` or any file on disk. Never committed. |
| Repository content | MCP filesystem server is scoped to `${workspaceFolder}` — it cannot read files outside the open repo. |
| Session state | Hook scripts write only to `hooks/state/` inside this workspace. Nothing is transmitted. |

**What does leave the IDE:** The text of your prompt and any context you
explicitly include (e.g. a code snippet you paste, or a file the agent reads at
your instruction) is sent to the configured LLM provider (GitHub Copilot, Azure
OpenAI, or Anthropic Claude) over your organisation's standard HTTPS connection.
This is identical to what happens when you use Copilot Chat or Claude Code
without Dev.IQ.

---

## 3. AI Output Controls

- Every skill output carries `@di-review-required`. No generated code is applied
  to the repository without explicit developer approval — the agent proposes, the
  developer decides.
- All outputs are advisory drafts at **Early** maturity. No autonomous verdicts.
- Security findings rated **Critical** or **High** always block the PR readiness
  verdict — no override regardless of delivery pressure or maturity tier.

---

## 4. Human Review Gates

The pack enforces human review before any AI-generated artifact reaches
production. The gates below define the required approval step, gate type, and
the role responsible for sign-off.

**Always-on (do not remove without a documented reason):**
- Generated code artifacts carrying `@di-review-required`
- PR readiness verdicts before any merge decision
- Security review findings rated Critical or High
- Any AI-proposed change to CI/CD configuration or infrastructure-as-code

**Project-specific gates (fill in or delete):**

| Trigger | Gate type | Approver role |
|---------|-----------|---------------|
| `<PLACEHOLDER>` | `<PLACEHOLDER>` | `<PLACEHOLDER>` |
| `<PLACEHOLDER>` | `<PLACEHOLDER>` | `<PLACEHOLDER>` |
| `<PLACEHOLDER>` | `<PLACEHOLDER>` | `<PLACEHOLDER>` |
| _`<Add rows as needed>`_ | | |

---

## 5. Escalation Paths

Replace `<PLACEHOLDER>` with actual names, aliases, or channels for your team.
Adjust SLAs to match your sprint and release cadence. Delete rows for triggers
that do not apply.

| Condition | Action | Owner |
|-----------|--------|-------|
| `<PLACEHOLDER>` | `<PLACEHOLDER>` | `<PLACEHOLDER>` |
| `<PLACEHOLDER>` | `<PLACEHOLDER>` | `<PLACEHOLDER>` |
| `<PLACEHOLDER>` | `<PLACEHOLDER>` | `<PLACEHOLDER>` |
| PR readiness verdict returns a RISK finding at High or Critical | Block merge; escalate to engineering lead before proceeding | `<PLACEHOLDER>` |
| Compliance refusal triggered by agent | Notify InfoSec and delivery lead same day | `<PLACEHOLDER>` |
| Security finding rated Critical appears in a PR | Do not merge; assign to security owner immediately | `<PLACEHOLDER>` |
| _`<Add project-specific trigger>`_ | _`<Action>`_ | _`<Owner>`_ |

---

## 6. Access Controls

| Control | Setting |
|---------|---------|
| AI merge without human review | Disabled (`allow_ai_merge_without_review: false`) |
| New dependencies without confirmation | Blocked (`allow_new_dependencies: false`) |
| Secrets in prompts | Masked (`mask_secrets_in_prompts: true`) |
| Traceability required | Yes — every generated artifact must reference its work item |

---

## 7. Traceability

- All generated code artifacts must reference the source ADO work item (`AB#XXXX`)
  when one is available.
- PRs without a linked work item are flagged as a Risk finding at Medium severity.
- A traceability matrix can be generated on demand with `/generate-traceability`.

---

## 8. Maturity Gate

**Current tier: Early** — all outputs are advisory. Human review is required
for every output before it is used. Blast radius estimation is disabled.

Re-evaluate tier in `.dev-iq/maturity-profile.md` after 30 days of pilot use.

---

## 9. What Dev.IQ Does Not Do

- Does not run as a service — no server to deploy, no background process.
- Does not store conversation history beyond the current IDE session.
- Does not modify CI/CD pipelines automatically — all CI changes require developer review.
- Does not write to any system outside the local workspace.
- Does not share data between workspaces or users.

---

## 10. Approval

Replace names and dates. Get all required signatures before the first
AI-assisted delivery workflow is used in production. Re-approve quarterly or on
any material change to compliance posture.

| Role | Name | Date |
|------|------|------|
| Dev.IQ sponsor / DI lead | | |
| Engineering lead | | |
| InfoSec (required if any compliance row = yes/partial) | | |

**Review cadence:** `<quarterly | per-release | annually>` or on material change to compliance posture.
