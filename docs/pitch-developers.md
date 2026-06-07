# Dev.IQ — A Better Thinking Partner in Your IDE

*Read time: 4 minutes. No install required to read this.*

---

## The problem you already feel

AI coding tools got faster. Review queues got longer.

The 2025 DORA report put numbers on something most developers already sense: AI improves throughput but increases delivery instability. GitHub's internal data shows AI-generated code produces roughly 40% more defects per PR. CodeRabbit — the most widely-deployed AI reviewer — has a 28% noise rate. You're generating more, reviewing harder, and catching less.

The gap isn't speed. The gap is *decision quality at the moment you write code.*

---

## What Dev.IQ does differently

Dev.IQ is not a linter. It is not a coverage gate. It is not a dashboard your manager watches.

It is a reasoning layer that sits inside **GitHub Copilot Chat** and **Claude Code** — the tools you're already using — and applies a structured four-layer thinking model to every code and delivery question you ask it.

| Layer | The question it answers |
|-------|------------------------|
| **Intent** | Are we building the right thing? Does this match the requirement? |
| **Design** | Is it being built the right way — patterns, architecture, naming? |
| **Quality** | Is it production-ready — error handling, null safety, security? |
| **Risk** | What could break — dependencies, schema changes, downstream blast radius? |

Every skill output runs through all four layers and gives you evidence, not a score. The difference matters: a green build tells you nothing about whether the PR solves the right problem or quietly breaks a downstream consumer.

---

## What changes on day one

You open Copilot Chat (or Claude Code), select the Dev-IQ agent, and type `/`. You get 21 skills covering your full delivery loop.

**Three you'll use on the first day:**

`/explain-code` — point at any file. Get a structured breakdown of what it does, what assumptions it makes, and where the intent gaps are. Not just "what does this do" — "what should I know before touching this."

`/code-review` — paste a diff. Get a four-layer review: intent match, design findings, quality issues (with severity), and risk flags. Every finding cites the file and line. No noise, no re-stating what the code does.

`/review-pr-readiness` — before you open the PR. Get a Go / Hold verdict with evidence. If it's a Hold, you know exactly which layer and why. You fix it before the reviewer sees it — not after.

---

## It starts advisory. It grows with your team.

Day one: every output is a draft. The agent says "consider this" and "I flagged this" — nothing is blocked, nothing is mandatory. You read it, you decide.

As the team's confidence grows, you can promote the maturity tier:
- **Early** (default) — advisory mode, coaching notes, all outputs are drafts
- **Mid** — structured reports, High security findings block the PR verdict
- **Higher** — autonomous PR verdicts, full blast radius estimation

The tier is a one-line config change. You set it. You can change it back.

---

## It does not slow you down

Trial mode installs every file locally and hides them from git entirely — your `.gitignore` is never touched. One command, five minutes, invisible to your team until you're ready.

```bash
# macOS / Linux
bash ~/tools/dev-iq/scripts/bootstrap.sh --preset=solo

# Windows
.\tools\dev-iq\scripts\bootstrap.ps1 -Preset solo
```

When the team is ready to adopt: `--graduate` moves the files into git tracking. No reinstall.

---

## What it is not

- Not a SaaS — no account, no data leaving your IDE boundary
- Not an AI that pushes code — it proposes, you decide; `@di-review-required` is on every output
- Not a replacement for code review — it makes review faster by front-loading the structured thinking
- Not locked to Sparq — the pack is yours; if Sparq rotates off, it stays in your repo

---

## See it live

We'll run three live skills on your actual code in the session. Bring a PR you recently opened or a service file you find complex — or we'll pick one together.

`/explain-code` · `/code-review` · `/review-pr-readiness`

Questions: **kabir.chugh@teamsparq.com**

---

*Dev.IQ Agent Pack v0.9.0 · Sparq Intelligence Studio*
*21 skills · GitHub Copilot Chat + Claude Code · github.com/Kabir1976/dev-iq*
