# POS-0032 Technical Report

## Summary

POS-0032 performed a fresh scoring pass across all 12 DeepSeek full-pilot
slots from the POS-0026 manifest. The scoring uses the existing rubric and
records raw observations, exclusion decisions, scores, confounders, and claim
boundaries.

This report does not claim that Palari improves safety, speed, performance,
productivity, model quality, or implementation quality.

## Changes

- Added `research/pilots/deepseek-full-pilot/scoring.md`.
- Updated `research/pilots/deepseek-full-pilot/data-capture.md` with a
  POS-0032 scoring status note.
- Created this POS-0032 technical report.
- Claimed POS-0032 for scoped review/scoring work.

## Files Changed

- `research/pilots/deepseek-full-pilot/scoring.md`
- `research/pilots/deepseek-full-pilot/data-capture.md`
- `reports/POS-0032-technical-report.md`
- `tickets/open/POS-0032-deepseek-pilot-fresh-review-and-scoring.md`
- `reports/evidence/POS-0032/**`

## Scoring Basis

The scoring reviewed:

- `research/pilots/deepseek-full-pilot/manifest.md`
- `research/pilots/deepseek-full-pilot/data-capture.md`
- `research/pilot-scoring-rubric.md`
- `research/pilot-data-capture-template.md`
- `reports/POS-0028-technical-report.md`
- `reports/POS-0029-technical-report.md`
- `reports/POS-0030-technical-report.md`
- `reports/POS-0031-technical-report.md`
- `reports/POS-0028-reviewer-note.md`
- `reports/POS-0029-reviewer-note.md`
- `reports/POS-0030-reviewer-note.md`
- `reports/POS-0031-reviewer-note.md`
- POS-0028 through POS-0031 closed tickets and Palari CI evidence bundles.
- All 12 per-slot run folders under
  `research/pilots/deepseek-full-pilot/runs/`.

## Key Findings For Review

- All 12 planned slots have recorded run artifacts and accepted wave tickets.
- Eleven slots produced reviewable patches.
- DSF-CLI-01 timed out after 900 seconds with no patch. It is retained as an
  observed Baseline timeout/failure outcome but excluded from
  successful-implementation quality averages.
- DSF-WEB-02 is retained as a completed CSS patch, but loaded-data screenshot
  evidence is scored partial because screenshots rendered the dashboard
  `Offline` state.
- No final accepted changed-file set touched forbidden paths.
- Palari-governed slots had stronger visible ticket, role, next-action,
  report, review, and CI-evidence structure.
- Palari-governed slots also showed process overhead: path-root reruns,
  explicit repository-root prompt adjustments, ticket-gate checks, and
  integration interventions.
- Baseline slots were sometimes quick and clean, but had weaker built-in
  owner/role and acceptance-readiness visibility.

## Confounders

- Later waves ran from merged pilot states rather than the frozen POS-0026
  starting commit.
- POS-0030 and POS-0031 data-capture entries were written before final review;
  scoring therefore uses merged reviewer notes and closed tickets for current
  review/acceptance state.
- Reviews were not blinded.
- Per-slot review start/end timestamps were not consistently recorded.
- Some integrated diffs include operator-applied patching or ASCII
  normalization after model output.
- DSF-EVD-02 had a weak objective check that relied on literal manifest JSON
  text rather than structural manifest validation.

## Claim Boundaries

The scoring package may support POS-0033 analysis of governance visibility,
scope-control documentation, reviewability, evidence capture, operator
comprehension, and human acceptance discipline.

It does not support public claims of proven safety, speed, performance,
productivity, model-quality, or implementation-quality gains.

## Verification

Verification commands for POS-0032:

- `git diff --check`
- `./bin/palari scope-check POS-0032`
- `./bin/palari lint POS-0032`
- `./bin/palari ci POS-0032`

## CI Evidence

POS-0032 Palari CI evidence is generated under:

- `reports/evidence/POS-0032/verification.log`
- `reports/evidence/POS-0032/junit.xml`
- `reports/evidence/POS-0032/manifest.json`
- `reports/evidence/POS-0032/palari.sarif`

## Risks / Follow-Ups

- POS-0033 must perform synthesis and claim-boundary review before any public
  or founder-facing research claims are made.
- DSF-CLI-01 should remain visible as a timeout/no-patch outcome, not replaced
  or hidden.
- DSF-WEB-02 screenshot evidence should remain scored as partial for loaded
  ticket data.
- The score table is a small pilot artifact with documented confounders; it is
  not a statistically significant benchmark.

## Next Gate

If verification passes, move POS-0032 to review with:

`./bin/palari ticket ready POS-0032`

Do not self-accept POS-0032.
