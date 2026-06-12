# Dev.IQ — Telemetry Overlay

**Pack version:** 0.9.0
**Client:** [fill in — matches config.yaml client.name]
**Configured by:** [engagement lead name]
**Last updated:** [date]

This file maps each DI signal layer to the actual data sources available in
this client's environment. The Dev-IQ agent reads this alongside `config.yaml`
to interpret signals correctly for this engagement.

Fill in the tool URLs and paths that apply. Leave a field as `none` if that
source is not available — the agent will mark the signal as **UNGRADED** rather
than fabricating data.

---

## INTENT Signal

| Field | Value |
|-------|-------|
| Tracker | `ado` |
| Base URL | `` |
| Project / board | `` |
| Work item types | `User Story, Task, Bug` |
| AC format convention | `[Given/When/Then / bullet list / none documented]` |

The agent uses this to resolve `AB#1234` or `PROJ-123` references in branch
names and PR descriptions and validate that code matches stated requirements.

---

## DESIGN Signal

| Field | Value |
|-------|-------|
| Architecture docs path | `none` |
| Pattern library path | `none` |
| ADR path | `none` |
| Architecture style | `` |

If no docs exist the agent infers patterns from existing code — note this as
UNGRADED in the assessment until documentation is available.

---

## QUALITY Signal

| Field | Value |
|-------|-------|
| Coverage tool | `none` |
| Coverage dashboard URL | `` |
| Lint tool | `none` |
| SAST tool | `none` |
| Test framework | `` |
| Minimum coverage threshold | `80` |

If no coverage tool is configured the QUALITY layer is UNGRADED for coverage.
The `minimum coverage threshold` must match `code_standards.min_coverage_threshold`
in `config.yaml`.

---

## RISK Signal

| Field | Value |
|-------|-------|
| Primary dependency file | `` |
| Schema / migration path | `none` |
| API contract file | `none` |
| High-risk paths | `` |
| Dependency scanner | `none` |

The agent uses this to estimate blast radius, flag dependency CVEs, and
identify schema or API contract changes that require a rollback plan.

---

## Signal Sink

| Field | Value |
|-------|-------|
| Sink type | `local` |
| Local signals path | `.dev-iq/signals/` |
| Webhook URL | `` |

Signals are written to `.dev-iq/signals/` as JSONL. This directory is
local-only — nothing is transmitted unless `sink: webhook` is set in
`config.yaml` and a URL is provided above.

---

## Engagement Notes

_Add client-specific signal interpretation notes here. Examples:_
- _Coverage is tracked per-service — the threshold applies to the service under review, not the monorepo aggregate._
- _ADO work items use a custom AC format: acceptance criteria live in the "Acceptance Criteria" field, not the description._
- _The team does not yet have a SAST tool — QUALITY security signals are UNGRADED until one is configured._
