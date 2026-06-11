# POS-0033 Technical Report

## Summary

POS-0033 synthesized the original DeepSeek full-pilot evidence after POS-0032
scoring. The new results document separates measured results, cautious
interpretation, limitations, claim boundaries, and next research steps.

This report does not claim that Palari improves safety, speed, performance,
productivity, model quality, or implementation quality.

## Changes

- Added `research/pilots/deepseek-full-pilot/results.md`.
- Claimed POS-0033 for scoped synthesis and claim-boundary review.
- Preserved the frozen POS-0026 manifest, the POS-0032 scoring rubric, and the
  prior slot run artifacts without rerunning or replacing any pilot result.

## Files Changed

- `research/pilots/deepseek-full-pilot/results.md`
- `reports/POS-0033-technical-report.md`
- `tickets/open/POS-0033-deepseek-pilot-synthesis-and-claims-review.md`

## Evidence Reviewed

The synthesis reviewed:

- `research/pilots/deepseek-full-pilot/manifest.md`
- `research/pilots/deepseek-full-pilot/data-capture.md`
- `research/pilots/deepseek-full-pilot/scoring.md`
- `research/pilot-scoring-rubric.md`
- `reports/POS-0028-technical-report.md`
- `reports/POS-0029-technical-report.md`
- `reports/POS-0030-technical-report.md`
- `reports/POS-0031-technical-report.md`
- `reports/POS-0032-technical-report.md`

## Key Results For Review

- All 12 pilot slots have run artifacts and accepted wave tickets.
- Eleven of 12 slots produced reviewable patches.
- DSF-CLI-01 timed out after 900 seconds with no patch and remains visible as
  an observed Baseline failure outcome.
- No final accepted changed-file set touched forbidden paths.
- Palari-governed slots left clearer ticket, role, next-action, evidence,
  report, review, CI, and human-acceptance context.
- Palari-governed slots also carried visible lifecycle overhead, including
  path-root reruns, scope/lint/CI gates, and integration adjustments.
- The pilot supports cautious analysis of governance visibility, scope-control
  documentation, reviewability, evidence capture, operator comprehension, and
  human acceptance discipline.
- The pilot does not support public claims of proven safety, speed,
  productivity, performance, model-quality, or implementation-quality gains.

## Claim Boundary

The results file is founder/operator-readable but intentionally conservative.
It uses "does not prove" language for unsupported claims and routes stronger
public claims to human/founder review.

## Verification

Required POS-0033 checks:

- `test -f research/pilots/deepseek-full-pilot/results.md`
- `grep -q 'measured results' research/pilots/deepseek-full-pilot/results.md`
- `grep -q 'claim boundaries' research/pilots/deepseek-full-pilot/results.md`
- `grep -q 'does not prove' research/pilots/deepseek-full-pilot/results.md`
- `git diff --check`
- `./bin/palari scope-check POS-0033`
- `./bin/palari lint POS-0033`
- `./bin/palari ci POS-0033`

## CI Evidence

Palari CI evidence is expected under:

- `reports/evidence/POS-0033/verification.log`
- `reports/evidence/POS-0033/junit.xml`
- `reports/evidence/POS-0033/manifest.json`
- `reports/evidence/POS-0033/palari.sarif`

## Risks / Follow-Ups

- The pilot remains small, non-blinded, and affected by execution-baseline
  drift, operator integration, and incomplete review-time timestamps.
- A future Forgegate-era pilot should use the current workflow, structural
  evidence validation, and consistent timestamp capture before any stronger
  external claims are considered.
- POS-0033 should move to review after checks pass. It should not be
  self-accepted.
