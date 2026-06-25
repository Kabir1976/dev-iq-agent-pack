# Dev.IQ — Maturity Profile

<!--
HOW TO USE THIS FILE
====================
1. Work through the checklist under "Indicators" — check every box that
   genuinely applies to your team today.
2. Count checked boxes to guide your tier choice (see the tier quick guide).
3. Set the tier in this file AND in .dev-iq/config.yaml (maturity.tier).
4. Fill in the Effective and Re-evaluation dates.
5. Capture your rationale in plain language — 2–5 sentences is enough.
6. Get sign-off from the roles in the Approval section.
7. Re-run this file as a workspace prompt quarterly, or when a re-evaluation
   trigger fires, to keep the tier current.

TIER QUICK GUIDE
================
  early   → 0–4 indicators checked, or brand-new team / greenfield install.
             Safest starting point. All outputs are advisory. No autonomous verdicts.
  mid     → 5–9 indicators checked, stable-but-maturing delivery.
             Structured reports. High findings block verdict. Suggest-only PR readiness.
  higher  → 10+ indicators checked, strong governance and signal pipeline.
             Full pack. Autonomous PR verdicts. Blast radius enabled.

When in doubt, choose the tier below where you think you are.
You can promote one tier at a time as indicators are established.
-->

---

## Current Tier

**Tier:** `early`  *(options: early | mid | higher)*

**Effective:** `Pilot start`
**Re-evaluation due:** 30 days after first skill use in a production workflow

---

## Why Early

This is an initial pilot deployment. The team is building familiarity with
DI-grounded workflows and evaluating the pack's value before wider adoption.
Early tier is appropriate because:

- Team members are new to AI-assisted delivery workflows
- The formal DI Diagnostic has not yet been completed
- All AI outputs should be explicitly advisory — no autonomous verdicts
- Human review of every AI output is non-negotiable at this stage

---

## What Early Tier Means in Practice

| Capability | Early behaviour |
|------------|----------------|
| Skill outputs | Always labelled `@di-review-required` — drafts only |
| PR readiness verdict | Recommendation, not a binding Go/Hold decision |
| Risk assessment | Advisory mode — surfaces findings, does not block |
| Blast radius estimation | Disabled |
| Coaching notes | Included on every significant output |
| Autonomous merge | Never — developer approves every change |

---

## Indicators *(check every one that genuinely applies today)*

Count checked boxes and use the tier quick guide above to determine your tier.

### Foundation

- [ ] Bootstrap installed and at least one hook confirmed running
- [ ] At least one skill validated end-to-end in the IDE (output reviewed, feedback given)
- [ ] MCP servers connected and tested (filesystem, ADO/GitHub, or equivalent)
- [ ] CI workflow active (`copilot-setup-steps.yml` or equivalent running on PRs)
- [ ] PR template adopted by the team (work item link + DI layer fields in use)

### Signals

- [ ] Artifact store used — at least one ADR or rollback plan saved to `.dev-iq/artifacts/`
- [ ] First PR readiness verdict used before a real merge decision
- [ ] First security review run on a real PR (not a demo or test PR)

### Quality

- [ ] Code-review skill used on 5 or more PRs
- [ ] Review-acceptance-criteria skill run on at least one sprint of stories
- [ ] Traceability matrix generated and reviewed with the team
- [ ] Governance.md signed off by the tech lead or engineering manager

### Governance

- [ ] Maturity tier reviewed with the full delivery team (not just the DI lead)
- [ ] Feedback collected from 2 or more developers who used the pack in practice
- [ ] Rollback plan generated for at least one production deployment

---

## Indicators Absent *(gaps preventing a higher tier)*

<!-- List the specific indicators above that are not yet true for your team.
Be honest — this is the basis for a realistic promotion path. -->

- `<e.g. MCP servers not yet connected — skills running in offline mode>`
- `<e.g. No PRs have used the PR readiness verdict yet>`
- `<Add more as needed>`

---

## What Would Shift This Tier Up

<!-- List the 2–4 changes that, once true, would justify re-evaluating to
the next tier. These become your DI improvement backlog items. -->

- `<e.g. 5+ PRs reviewed with the code-review skill over 2 sprints>`
- `<e.g. Governance.md signed off and compliance posture filled in>`
- `<Add more as needed>`

---

## Graduation Criteria — Moving to Mid

Consider requesting a formal DI Diagnostic to move to **Mid** tier when:

- The team has used at least 3 skills across 10 or more PRs
- Skill outputs feel accurate and are being acted on (not just read and ignored)
- The team lead is comfortable receiving structured (non-advisory) PR readiness reports
- There is a clear owner for reviewing and actioning flagged findings

---

## Tier Behavior Summary

| Capability | Early | Mid | Higher |
|------------|-------|-----|--------|
| Skill outputs | Advisory drafts only (`@di-review-required`) | Structured reports | Full autonomous verdicts |
| PR readiness verdict | Recommendation | High findings block | Autonomous Go/Hold |
| Risk assessment | Advisory | Flags findings | Blast radius enabled |
| Blast radius estimation | Disabled | Disabled | Enabled |
| Coaching notes | On every output | On Medium+ findings | On request |
| Autonomous merge | Never | Never | Never — developer always decides |

---

## Tier History

| Date | Tier | Reason |
|------|------|--------|
| Pilot start | Early | Initial install — advisory mode, team onboarding |

---

## Re-evaluation Triggers

Re-evaluate the tier ahead of schedule when any of these occur — do not wait
for the quarterly date:

1. Compliance posture changes (new regime added or removed in `governance.md`)
2. New tooling adopted that materially changes signal availability (SAST, coverage, ADO integration)
3. Team composition changes by more than 30% (new engineering lead, new QE, major onboarding)
4. Pack upgrade that introduces new skills or changes skill behavior at the current tier
5. Sustained pattern of skill outputs being overridden or ignored — may indicate over-promotion
6. First production incident where a Dev.IQ verdict was cited in the post-mortem
7. Assert.IQ installed alongside Dev.IQ — shared skill boundaries need re-alignment

---

## Approval

| Role | Name | Date |
|------|------|------|
| Dev.IQ sponsor / DI lead | | |
| Engineering lead | | |
| Delivery lead / EM | | |

*Re-approve on tier promotion or demotion, or when a re-evaluation trigger fires.*
