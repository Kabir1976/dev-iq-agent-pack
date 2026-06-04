SPARQ  ·  INTELLIGENCE STUDIO  ·  CAPABILITY ONE-PAGER
**Dev.IQ Agent Pack** *(Internal use only right now)*
Developer Intelligence, dropped into your developers' IDE — works with GitHub Copilot Chat and Claude Code.

---

**What it is.**  A versioned set of files — markdown, YAML, JSON — that drops into a client codebase and turns GitHub Copilot Chat and Claude Code into a Developer Intelligence-aware delivery partner. Sparq's four-layer DI signal model (Intent → Design → Quality → Risk → Decision Confidence) is loaded as the AI's reasoning lens on every interaction. Not a SaaS. The client owns the pack.

---

## How the pieces fit

**Developer Intelligence (DI)** — the operating model. Moves software delivery from reactive execution into proactive decision support across four signal layers: intent, design, quality, and risk.

**Dev.IQ** — the commercialized Sparq capability inside Intelligence Studio that operationalizes DI with AI-assisted code review, PR readiness assessment, security review, blast radius estimation, and workflow-integrated traceability.

**Dev.IQ Agent Pack** — the capability layer inside the IDE. 21 skills, 5 always-on instruction files, two agents (Dev-IQ for action, Dev-IQ-PLAN for plan-first work), MCP wiring for GitHub and ADO, and maturity gating so capabilities only fire where the team is ready.

---

## How your team gets started

**1. Install and configure (one workspace).**  Run the bootstrap once. Set the maturity tier (Early / Mid / Higher), customize the configs, and wire MCP to your tracker (ADO or Jira) and to GitHub. Pre-existing files are preserved; settings are deep-merged.

**2. Developers stay in their IDE.**  In VS Code Copilot Chat or Claude Code, the developer picks the Dev-IQ agent and types `/` to see skills. The right instruction files load automatically based on the file in focus and the task type.

**3. A DI risk signal shows up on every PR.**  Each pull request receives a four-layer DI risk band with evidence, traceability is generated automatically, and a Go / Hold / Discuss verdict replaces gut-feel sign-off.

---

## The 21 skills at a glance

| Lifecycle Phase | Skills (invoked with `/` in chat) |
|----------------|-----------------------------------|
| Requirements | `/generate-user-stories`  ·  `/review-acceptance-criteria`  ·  `/identify-dependencies` |
| Design | `/design-api`  ·  `/design-data-model`  ·  `/generate-adr`  ·  `/review-architecture` |
| Develop | `/scaffold-feature`  ·  `/explain-code`  ·  `/refactor-code`  ·  `/debug-issue`  ·  `/review-security` |
| Code Review / PR | `/code-review`  ·  `/review-pr-readiness`  ·  `/blast-radius-estimator`  ·  `/review-dependencies`  ·  `/new-pull-request` |
| Deployment | `/generate-release-notes`  ·  `/review-deployment-readiness`  ·  `/generate-rollback-plan` |
| Cross-cutting | `/generate-traceability-matrix`  ·  `/dev-iq-bootstrap` |

---

## The value it delivers

| Where teams feel it | What changes |
|---------------------|-------------|
| Pre-merge defect detection | Critical and High findings caught before code reaches review — not after |
| Code review depth | Every review scored across four DI signal layers with evidence, not reviewer instinct |
| PR risk assessment | 100% of PRs receive a four-layer DI risk band (Go / Go with comments / Hold) |
| Design consistency | Pattern drift and layer violations flagged at authorship, not in an architecture review weeks later |
| Security posture | OWASP-grounded security check on every auth, data, and API change — Critical findings block merge unconditionally |
| Release decision | Structured deployment readiness report with rollback plan, replacing verbal sign-off |
| Traceability | Requirement-to-code-to-test matrix generated on demand — audit-ready in minutes |

---

## Governance

**Safe by design**

Every generated artifact is human-reviewable and carries a `@di-review-required` header. No code is applied to the repository without developer approval — the agent proposes, the developer decides. Capabilities are gated by a maturity tier (Early / Mid / Higher) configured per repo. Security findings rated Critical or High always block the PR verdict regardless of tier or delivery pressure. No prompt exfiltrates code, secrets, or proprietary data outside the IDE/CI boundary. All files are markdown, YAML, and JSON — portable across LLM IDE tools. The client owns the pack; if Sparq rotates off, it stays.

---

**Get started.**  Sparq runs a Developer Intelligence diagnostic, sets the maturity tier, drops the pack into one or more pilot repositories, and begins measurable signal capture inside 30 days. Expand from there.

Pack: github.com/Kabir1976/dev-iq  ·  v0.9.0  ·  
Pack owner: Kabir Chugh, Sparq  ·  
Companion: Assert.IQ Agent Pack (Quality Intelligence)
