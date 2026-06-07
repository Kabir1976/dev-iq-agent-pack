---
applyTo: "**/*.{yml,yaml},**/Jenkinsfile,**/*.pipeline,**/*.pipeline.yml,**/*.tf,**/.github/workflows/**"
---

# DI Signal Emission — CI/CD Configuration Rules

Apply when editing CI configuration (GitHub Actions, Azure Pipelines, GitLab CI,
Jenkinsfile) or infrastructure-as-code that affects signal collection. The goal is
to ensure the four DI signal layers have machine-readable evidence flowing into
every PR assessment.

## Why Signal Emission Matters

A DI assessment is only as good as its data sources. When CI is not wired correctly:
- QUALITY and RISK layers become UNGRADED — the agent cannot assess what it cannot read
- PR verdicts default to advisory mode regardless of maturity tier
- Decision Confidence is not computable

Every CI change should be evaluated against this question: *does this change preserve, improve, or break the signal flow?*

## Required Signal Surfaces per Layer

### INTENT Signal
- Work item links in PR titles or descriptions must flow through to the CI run context
- If the pipeline creates ADO or Jira artifacts (comments, status updates), verify the work item reference is preserved

### DESIGN Signal
- Linting output must be published as a parseable report (SARIF, JUnit XML, or JSON) — not just piped to stdout
- Architecture validation (if configured) must fail the build on violations, not just warn
- Required config keys: `stack.lint_tool` and `stack.formatter` in `.dev-iq/config.yaml`

### QUALITY Signal — Coverage
Coverage must be published as a structured report, not just a pass/fail gate:
- **Jest/Vitest:** `--coverage --coverageReporters=json,lcov`
- **pytest:** `--cov --cov-report=xml`
- **JUnit/Jacoco:** publish the `jacoco.xml` report as a pipeline artifact
- **dotnet:** `--collect:"XPlat Code Coverage"` with Cobertura report

Minimum threshold enforcement (from `.dev-iq/config.yaml` → `code_standards.min_coverage_threshold`):
```yaml
# GitHub Actions example
- name: Check coverage threshold
  run: |
    THRESHOLD=$(cat .dev-iq/config.yaml | grep min_coverage_threshold | awk '{print $2}')
    # compare against generated report
```

### QUALITY Signal — SAST
- SAST tool output must be published in SARIF format for GitHub Advanced Security, or as a JUnit XML artifact for other platforms
- SAST must run on every PR, not just on main/master merges
- Critical and High SAST findings must fail the pipeline — not warn
- Required config key: `signals.quality.sast_tool` in `.dev-iq/config.yaml`

### RISK Signal — Dependency Scanning
- Dependency vulnerability scan must run on every PR that modifies a lockfile or manifest
- Output must distinguish between Critical/High/Medium/Low findings
- Required: fail the build on Critical dependency vulnerabilities

## CI Change Assessment Rules

When modifying CI configuration, apply these checks:

### Additions (new steps, jobs, or workflows)
1. Does the new step emit signal (coverage, lint, SAST) in a structured format?
2. Does it have a timeout? Unbounded CI steps are a RISK finding.
3. Does it require secrets? Verify secrets are in the CI platform's secrets store, never in the config file.
4. Does it run on PRs as well as main branch merges?

### Removals (deleting steps or jobs)
1. Which signal layer does this step feed? State it explicitly.
2. If it feeds QUALITY or RISK: the affected layer becomes UNGRADED after removal — flag this as a RISK finding.
3. Is there a replacement? If not, the signal gap must be documented.

### Changes to Thresholds or Gates
1. Lowering a coverage threshold or removing a fail-fast gate: always flag as a RISK finding — this is weakening the signal.
2. Raising a threshold: QUALITY signal improvement — note it positively.

### Secrets in CI Configuration
- Secrets must never appear in YAML files, Jenkinsfiles, or Terraform configs.
- Secrets belong in: GitHub Secrets, Azure Key Vault, GitLab CI/CD variables, or HashiCorp Vault.
- Any `echo $SECRET`, `env: SECRET: value`, or hardcoded credential in a CI file is a Critical finding.

## Signal Sink Configuration

Dev.IQ can emit DI signals to a configured sink for aggregation and reporting.
When the CI pipeline runs a skill or DI assessment:

```yaml
# GitHub Actions — emit DI signal on PR assessment
- name: Emit DI signal
  run: |
    curl -s -X POST "${{ secrets.DI_SIGNAL_SINK_URL }}" \
      -H "Content-Type: application/json" \
      -d '{
        "event": "pr.assessed",
        "pr_ref": "${{ github.event.pull_request.number }}",
        "verdict": "${{ env.DI_VERDICT }}",
        "layers": "${{ env.DI_LAYERS }}",
        "timestamp": "${{ env.DI_TIMESTAMP }}"
      }'
```

Sink configuration lives in `.dev-iq/telemetry-overlay.md`. When sink is set to `local`, no network calls are made — signals are written to `.dev-iq/signals/` only.

## Blast Radius of CI Changes

Any change to a CI pipeline that removes a quality gate, lowers a threshold, or changes when security scanning runs must be flagged in the PR with:
- The signal layer affected
- The before/after behavior
- Who approved the change and why

CI configuration is shared infrastructure. Treat it with the same care as a breaking change to a shared library.
