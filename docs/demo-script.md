# Dev.IQ — Live Demo Script

*For: tech lead + developer team · Duration: 30–40 min · Format: facilitated, live in IDE*

---

## Before the session

**Your setup (5 min before people arrive):**
- Dev.IQ installed via `--preset=pod` against a repo the team knows
- VS Code open with that repo loaded
- Copilot Chat (or Claude Code) visible on one monitor
- One complex service file identified (pick it from their codebase, not a toy example)
- One recently-opened PR with a real diff identified
- A browser tab open to the GitHub PR

**Ask the team to bring:**
> "If you have a file in the codebase you find complex or a PR you opened this week — bring it. We'll run the skills on your actual code, not a demo repo."

---

## Opening (3 min)

Do not start with slides.

Open with one question to the room:

> "How many of you have approved a PR, it passed CI, and something still broke in production?"

(Hands go up. Let it sit for two seconds.)

> "That's not a process failure. That's a signal gap. Green build tells you if the code runs. It doesn't tell you if the code was the right answer, if it follows your patterns, or what it breaks downstream. That's what we're going to look at today."

---

## Demo 1 — `/explain-code` (8 min)

**Purpose:** Show that the agent reasons about *intent*, not just syntax.

**Setup:**
1. Open a complex service file — ideally something with business logic the team has debated
2. Select the whole file (or the key function if it's large)
3. In Copilot Chat: select Dev-IQ agent, type `/explain-code`

**Talking points while it runs:**
- "Notice it's not summarizing the code — you can read the code. It's telling you *what the code assumes*, *where the intent gaps are*, and *what a new developer needs to know before touching this*."
- "That INTENT signal at the bottom — that's the DI layer assessment. STRONG means the code matches what you'd expect for its name and context. WEAK means something's off."

**What to highlight in the output:**
- The "Assumptions" section — developers are usually surprised by what the agent catches
- Any INTENT: WEAK findings — these are conversation starters
- The `@di-review-required` marker — "This is a draft. You decide. The agent proposes, you approve."

**Transition:**
> "That's what the agent sees before it reviews anything. Now let's look at what it does with a real PR."

---

## Demo 2 — `/review-code` (10 min)

**Purpose:** Show structured four-layer review vs. reviewer instinct.

**Setup:**
1. Open the PR in GitHub (browser)
2. Copy the diff or open the changed files in VS Code
3. In Copilot Chat: select changed files as context, type `/review-code`

**Talking points while it runs:**
- "It's running through all four layers — Intent, Design, Quality, Risk. Each finding will tell you which layer it belongs to and how severe it is."
- "What you won't see: re-stating what the code does. That's noise. Every finding has to answer: *why does this matter?*"

**What to highlight in the output:**
- The severity breakdown: Critical/High are blocked; Medium are review items; Low are notes
- A DESIGN finding if one comes up — "This is where pattern drift gets caught. Not in a quarterly architecture review — at authorship."
- A RISK finding if one comes up — "Blast radius: what else does this change touch?"
- Missing traceability if no work item is linked — "INTENT layer is UNGRADED without a work item. That's not a failure — it's honest. You know what you don't know."

**Pause for the tech lead:**
> "Is this the kind of thing that would've been caught in your current review process? How long would that have taken?"

**Transition:**
> "Now — what if the developer ran this *before* opening the PR?"

---

## Demo 3 — `/review-pr-readiness` (8 min)

**Purpose:** Show the Go / Hold verdict before the PR is even opened.

**Setup:**
1. Use the same diff / changed files as Demo 2
2. Type `/review-pr-readiness`

**Talking points while it runs:**
- "This is the four-layer assessment as a pre-merge gate. It gives a verdict: Go, Go with comments, or Hold."
- "Hold means something in the four layers needs to be addressed before this goes to review. Not after your reviewer spends 45 minutes on it."
- "The maturity tier controls how assertive the verdict is. Right now we're in Early — everything is advisory. You can take it or leave it."

**What to highlight in the output:**
- The layer-by-layer verdict table
- Any Hold condition — explain which layer triggered it and what fixes it
- "If the team moves to Mid maturity, High security findings here automatically block the verdict — not the developer, not any external party — the configured rules the team agreed on."

**Pause:**
> "What's your current pre-merge process? What would it mean if 100% of PRs had this before review?"

---

## Maturity model (3 min, no demo needed)

Show `.dev-iq/maturity-profile.md` in VS Code.

> "This is the dial. Early means the agent coaches. Mid means the agent reports with structure and High security findings block. Higher means the agent issues autonomous verdicts."

> "You set this. You change it. It's a one-line YAML edit. We're not asking you to go to Higher on day one — most teams start at Early and graduate when it feels right."

---

## Objection handling

**"Is this going to slow us down?"**
> "Trial mode takes 5 minutes. The skills fire when you invoke them — nothing runs automatically. You're adding a structured thinking layer you were doing informally anyway. The question isn't whether it slows you down. It's whether the thinking you were doing informally was catching everything it should."

**"Isn't this just a linter?"**
> "A linter checks syntax rules. This checks whether the PR solves the right problem, follows your patterns, handles errors correctly, and won't break downstream consumers. Different tool, different layer."

**"Does anyone outside our team see our code?"**
> "No. The pack is a set of markdown and YAML files. It runs inside your IDE — your code hits your AI provider (GitHub Copilot or Anthropic), same as it does today. There's no server in the loop. You own the pack."

**"What happens if we want to remove it or take ownership ourselves?"**
> "The pack stays in your repo either way. Your team can keep using it, modify it, and update it independently. There's no licence, no SaaS subscription, no account to cancel. Run `--uninstall` to remove it cleanly if needed."

**"Can we customize the rules?"**
> "Yes — `.dev-iq/config.yaml` sets your stack, maturity tier, coverage thresholds, SAST tool. The instruction files in `.github/instructions/` are markdown — your team can edit them. The skills in `.github/skills/` are editable too."

---

## Close (3 min)

> "We're going to leave trial installs running on [N] repos today. You'll have the skills available from your next session."

Hand out: `docs/pitch-developers.md` (the written summary they can share)

Ask the team:

> "What's the one thing in your current delivery loop that you'd most want a second set of eyes on? That's probably the first skill to run."

---

## Post-session follow-up

Send within 24 hours:
- `docs/pitch-developers.md` (the written pitch)
- `docs/trial-install-guide.md` with the bootstrap command for self-service individual install
- A calendar invite for a 30-day check-in: "What signals are you seeing?"

---

*Dev.IQ Agent Pack v0.12.0*
