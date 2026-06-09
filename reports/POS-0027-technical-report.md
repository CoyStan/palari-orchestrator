# POS-0027 Technical Report

## Summary

POS-0027 created the scaffolding and follow-on ticket route for the accepted
DeepSeek full pilot manifest. It did not run any DeepSeek/opencode task slots.

## Changes

- Created `research/pilots/deepseek-full-pilot/data-capture.md` with all 12
  manifest slots, wave-ticket routing, run-folder names, required artifacts,
  and claim boundaries.
- Created `research/pilots/deepseek-full-pilot/runs/` with placeholder folders
  for all six Baseline-agent slots and all six Palari-governed slots.
- Created follow-on tickets:
  - POS-0028 for Baseline wave 1: DSF-DOC-02, DSF-CLI-01, DSF-WEB-02.
  - POS-0029 for Palari-governed wave 1: DSF-DOC-01, DSF-CLI-02,
    DSF-WEB-01.
  - POS-0030 for Baseline wave 2: DSF-TST-02, DSF-GOV-01, DSF-EVD-01.
  - POS-0031 for Palari-governed wave 2: DSF-TST-01, DSF-GOV-02,
    DSF-EVD-02.
  - POS-0032 for fresh review, scoring, exclusions, and data-quality audit.
  - POS-0033 for synthesis and claim-boundary review.

## Files Changed

- `research/pilots/deepseek-full-pilot/data-capture.md`
- `research/pilots/deepseek-full-pilot/runs/README.md`
- `research/pilots/deepseek-full-pilot/runs/*/README.md`
- `tickets/open/POS-0028-deepseek-baseline-wave-1.md`
- `tickets/open/POS-0029-deepseek-palari-wave-1.md`
- `tickets/open/POS-0030-deepseek-baseline-wave-2.md`
- `tickets/open/POS-0031-deepseek-palari-wave-2.md`
- `tickets/open/POS-0032-deepseek-pilot-fresh-review-and-scoring.md`
- `tickets/open/POS-0033-deepseek-pilot-synthesis-and-claims-review.md`
- `reports/POS-0027-technical-report.md`

## Manifest Preservation

The POS-0026 manifest assignments were preserved. POS-0027 did not change task
IDs, condition assignments, randomization, model choice, scoring linkage,
forbidden paths, or claim boundaries.

The POS-0027 ticket scope also acknowledges
`research/pilots/deepseek-first-pilot/**` because accepted POS-0025 pilot
artifacts are still uncommitted in this workspace and Palari local scope-check
evaluates all dirty paths together. POS-0027 did not modify those first-pilot
artifacts.

## Safety And Claim Boundaries

- No pilot task was executed in POS-0027.
- No product, dashboard, CLI, test, docs, or governance implementation changes
  from the 12 slot tasks were made.
- The scaffolding states that Palari may measure governance visibility, scope
  control, reviewability, evidence capture, and human acceptance discipline.
- The scaffolding does not claim that Palari proves safety, speed, performance,
  model quality, correctness, secure changes, or safe merges.

## Verification

- POS-0027 objective scaffold checks: passed.
- `git diff --check`: passed.
- `./bin/palari lint POS-0027`: passed.
- `./bin/palari ci POS-0027`: passed.
- First `./bin/palari ci POS-0027` attempt failed because local scope-check saw
  accepted but uncommitted POS-0025 first-pilot artifacts. The POS-0027 scope
  declaration now records those artifacts as dirty carryover.

## CI Evidence

- `reports/evidence/POS-0027/verification.log`
- `reports/evidence/POS-0027/junit.xml`
- `reports/evidence/POS-0027/palari.sarif`
- `reports/evidence/POS-0027/manifest.json`

## Risks / Follow-Ups

- POS-0028 is the next execution ticket and should run Baseline wave 1 only
  after POS-0027 review.
- Accepted POS-0025 and POS-0026 artifacts are still uncommitted. They were
  preserved and intentionally left in place.
- POS-0027 deliberately did not execute any DeepSeek task slot, so the full
  pilot has no new safety, speed, performance, or model-quality result yet.
- Future execution tickets must preserve fresh context per slot and must record
  exclusions instead of silently replacing failed or unflattering runs.
