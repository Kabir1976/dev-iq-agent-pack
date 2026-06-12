# Maturity Profile

**Current tier:** Early
**Set on:** Pilot start
**Re-evaluate:** 30 days after first skill use in production workflow

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

## Graduation Criteria — Moving to Mid

Consider requesting a formal DI Diagnostic to move to **Mid** tier when:

- The team has used at least 3 skills across 10 or more PRs
- Skill outputs feel accurate and are being acted on (not just read and ignored)
- The team lead is comfortable receiving structured (non-advisory) PR readiness reports
- There is a clear owner for reviewing and actioning flagged findings

---

## Tier History

| Date | Tier | Reason |
|------|------|--------|
| Pilot start | Early | Initial install — advisory mode, team onboarding |
