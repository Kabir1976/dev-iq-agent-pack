# Dev.IQ — Getting Started (UPS Trial)

**What this is:** A set of AI skills that give GitHub Copilot Chat a structured
Developer Intelligence reasoning layer — four-signal code review, PR readiness
checks, user story review, security analysis, and more. It installs into your
existing VS Code + Copilot Chat setup. Nothing new to learn. Nothing deployed.
Files only.

**Time to first result:** under 20 minutes.

---

## Step 1 — Install

Full install instructions are in `docs\trial-install-guide.md` inside the zip.
The short version:

1. Extract the zip to `C:\Tools\dev-iq\`
2. Run the Unblock-File command (Windows flags zip contents by default):
   ```powershell
   Get-ChildItem "C:\Tools\dev-iq" -Recurse | Unblock-File
   ```
3. Open PowerShell and run:
   ```powershell
   powershell -File "C:\Tools\dev-iq\scripts\bootstrap.ps1" -Target "C:\path\to\your-ups-repo" -Preset solo
   ```
   Replace the path with the actual location of the UPS repo on your machine.
4. When asked — answer **[1] Just me** (trial mode — invisible to git, nothing committed).

See `docs\trial-install-guide.md` for the Windows checklist (execution policy,
ADO credentials) and troubleshooting steps.

---

## Step 2 — Verify the install worked

**VS Code:**
Open the UPS repo. Open Copilot Chat (`Ctrl+Alt+I`). Click the agent selector
at the top of the chat panel — **Dev-IQ should appear in the dropdown.**
Select it, then type `/explain-code` and point it at any source file.

**Visual Studio 2022:**
Open the UPS repo. Open Copilot Chat (`Alt+/`). Type `@Dev-IQ` to invoke the
agent — it autocompletes if the agent files were installed correctly.
Then type `/explain-code` and point it at any source file.

> **Visual Studio one-time setup:** You must enable repository instructions
> manually first. Go to **Tools → Options → GitHub → Copilot → (General)** and
> turn on **"Enable repository custom instructions"**. Without this, the DI
> reasoning layer will not load.

**Pass for either IDE:** The response includes a **Purpose** section and an
**INTENT signal** verdict — you're live.

**If Dev-IQ does not appear / @Dev-IQ does not autocomplete:** this is the
first thing to report back. Include your IDE, version (`Help → About`), and
Copilot extension version.

---

## Step 3 — Using Dev-IQ in your IDE

The workflow is the same in both VS Code and Visual Studio 2022. The only
difference is how you invoke the Dev-IQ agent.

| | VS Code | Visual Studio 2022 |
|---|---|---|
| **Open Copilot Chat** | `Ctrl+Alt+I` | `Alt+/` |
| **Invoke Dev-IQ agent** | Select from dropdown | Type `@Dev-IQ` |
| **Run a skill** | `/skill-name` | `/skill-name` |
| **Min version** | VS Code 1.99 | Visual Studio 2022 v17.14 |

**Five patterns to know:**

1. **Invoke the agent first.** In VS Code: select Dev-IQ from the dropdown. In
   Visual Studio: type `@Dev-IQ` at the start of your message. Skills will not
   respond without the agent active.

2. **Invoke a skill by name.** Type `/skill-name` — Copilot Chat autocompletes.
   The agent reads your open files, the diff, and any connected ADO work items
   automatically.

3. **Select code before running a skill** to scope it. For `/code-review` or
   `/explain-code`, highlight the function or class first.

4. **Paste when prompted.** If ADO credentials aren't wired, skills ask you to
   paste the work item or PR description inline. Everything still works.

5. **Output always ends with `@di-review-required`.** This is intentional — it
   marks AI-generated content as awaiting your review. The agent advises; you decide.

---

## Step 4 — Skills reference

22 skills are available. This is the full list with the most practical starting
points highlighted.

### Start here (Day 1)

| Skill | When to use | What you get |
|-------|------------|--------------|
| `/explain-code` | Any unfamiliar file or function | Purpose, patterns, dependencies, INTENT signal |
| `/code-review` | Before or during a PR | Line-level findings across Design + Quality + Security, severity-rated |
| `/review-pr-readiness` | Before merging a PR | Four-layer Go / Hold / No-Go verdict with explicit rationale |

### High value (Day 1–2)

| Skill | When to use | What you get |
|-------|------------|--------------|
| `/review-security` | Any file with auth, data, or external calls | OWASP-grounded security scorecard |
| `/review-acceptance-criteria` | Before sprint commit | AC-by-AC rating: Testable / Specific / Complete / Consistent |
| `/estimate-effort` | Sizing a story or ticket | Calibrated story-point estimate with rationale and uncertainty band |
| `/debug-issue` | Something broke | Root cause hypothesis, reproduction steps, fix options |
| `/refactor-code` | Code that needs cleanup | Prioritized findings + refactored code with rationale |

### Delivery and design (Day 2–3)

| Skill | When to use | What you get |
|-------|------------|--------------|
| `/review-deployment-readiness` | Before a production deploy | Deployment go/no-go checklist |
| `/generate-rollback-plan` | Before a risky deploy | Step-by-step rollback procedure with trigger criteria |
| `/review-architecture` | Design or tech debt review | Architecture signal assessment across four layers |
| `/scaffold-feature` | Starting a new feature | Boilerplate file structure, interfaces, test stubs |
| `/design-api` | New or changed API surface | API contract review, naming, consistency |
| `/design-data-model` | Schema or data model work | Data model assessment with migration risk |
| `/generate-adr` | Architecture decision to record | Architecture Decision Record (ADR) document |
| `/identify-dependencies` | Before a major change | Upstream/downstream dependency map |
| `/blast-radius-estimator` | Before a breaking change | Blast radius estimate — who and what is affected |
| `/generate-traceability-matrix` | Audit or compliance | Requirements → code → tests traceability table |
| `/generate-release-notes` | After a sprint | Release notes from the diff |
| `/new-pull-request` | Creating a PR | PR description with DI context |
| `/review-dependencies` | After adding packages | Dependency risk review (CVEs, licensing) |

---

## Skills validation checklist

Use this to confirm the skills are working as expected. Try the Tier 1 skills
on Day 1 — they take under 10 minutes total. Work through Tier 2 and 3 over
the following days.

### Tier 1 — Confirm the pack is live (Day 1, ~10 min)

**[ ] `/explain-code`**
- Select any function or class in the UPS codebase
- Type `/explain-code` in Dev-IQ chat
- **Pass:** Response includes Purpose, INTENT signal, and `@di-review-required`
- **Fail:** Generic response with no signal labels, or skill doesn't respond

**[ ] `/code-review`**
- Select a file or function you recently changed
- Type `/code-review` in Dev-IQ chat
- **Pass:** Returns numbered findings with severity (🔴/🟠/🟡/⚪), DI layer label (DESIGN/QUALITY), and `@di-review-required`
- **Fail:** Generic code comments with no DI structure

---

### Tier 2 — Core value skills (Day 1–2, ~30 min total)

**[ ] `/review-pr-readiness`**
- Open a branch with recent changes
- Type `/review-pr-readiness`
- **Pass:** Four-layer assessment (INTENT / DESIGN / QUALITY / RISK), each rated STRONG / WEAK / UNGRADED, and a Go / Hold / No-Go verdict
- **Fail:** Missing layer labels, or verdict without rationale
- **Note if:** Any layer is UNGRADED and why (missing diff, no work item, etc.)

**[ ] `/review-security`**
- Select a file that handles authentication, user data, or external API calls
- Type `/review-security`
- **Pass:** OWASP-grounded checklist with severity ratings (🔴 Critical / 🟠 High / 🟡 Medium / ⚪ Low) and `@di-review-required`
- **Fail:** Generic "looks secure" response with no checklist

**[ ] `/review-acceptance-criteria`**
- Paste a work item or user story into chat, then type `/review-acceptance-criteria`
- Or if ADO MCP is wired: `/review-acceptance-criteria AB#[work-item-number]`
- **Pass:** Table rating each AC as Pass / Weak / Fail across Testable / Specific / Complete / Consistent, plus a Sprint-Readiness verdict
- **Fail:** Narrative feedback with no structured rating

**[ ] `/debug-issue`**
- Paste an error message or describe a bug, then type `/debug-issue`
- **Pass:** Root cause hypothesis, reproduction steps, and at least two fix options with trade-offs
- **Fail:** Generic debugging advice with no hypothesis

---

### Tier 3 — Generative skills (Day 2–3, optional)

**[ ] `/estimate-effort`**
- Paste a user story or describe a feature, then type `/estimate-effort`
- **Pass:** Fibonacci or t-shirt estimate with per-factor breakdown, uncertainty band, and scope-risk flags
- **Fail:** Bare number with no rationale or uncertainty band

**[ ] `/review-deployment-readiness`**
- On a branch ready for production
- Type `/review-deployment-readiness`
- **Pass:** Checklist table with ✓ Verified / ⚠ Unverified / ✗ Missing / N/A per item, plus Go/Hold verdict
- **Fail:** Narrative readiness commentary with no checklist

**[ ] `/generate-rollback-plan`**
- Describe a deployment (what's changing, what env)
- Type `/generate-rollback-plan`
- **Pass:** Trigger criteria (specific, observable), numbered rollback steps with role + time + verify, and irreversible actions called out
- **Fail:** Vague "revert the deployment" guidance

---

## Reporting back

After 2–3 days, reply to the Teams message that came with this zip. The
feedback template is at the bottom of `docs\trial-install-guide.md`.

The most important things to report:
1. Did Dev-IQ appear in the Copilot Chat agent dropdown?
2. Which Tier 1 skills passed the checklist criteria above?
3. Any skill output that felt wrong, generic, or unhelpful (quote what you typed and what it said)

No formal write-up needed — bullet points are fine.
