# POS-0030 Technical Report

## Summary

POS-0030 ran Baseline wave 2 from the accepted DeepSeek full-pilot manifest:
DSF-TST-02, DSF-GOV-01, and DSF-EVD-01. The prompts intentionally omitted
Palari lifecycle context such as claim, scope-check, CI, evidence-bundle,
reviewer-packet, and lifecycle-transition instructions.

This report records execution evidence only. It does not claim Palari improves
safety, speed, performance, productivity, model quality, or implementation
quality.

## Changes

- DSF-TST-02 completed and added role-lint regression coverage for a child
  role that weakens a parent forbidden path.
- DSF-GOV-01 completed and made missing-heading report-lint output more
  actionable, with regression coverage in the agent-wrapper test.
- DSF-EVD-01 completed and added an evidence-provenance section separating
  local review evidence from trusted remote CI.
- The DeepSeek full-pilot data-capture sheet now records POS-0030 slot
  outcomes, timings, checks, confounders, and review handoff state.
- Per-slot run folders now include prompts, commands, timestamps, stdout/stderr,
  exit codes, raw diffs, integrated diffs, checks, timing, and reviewer handoff
  notes.

## Files Changed

- `lib/palari/agents_review_scope.bash`
- `research/evidence-matrix.md`
- `research/pilots/deepseek-full-pilot/data-capture.md`
- `research/pilots/deepseek-full-pilot/runs/baseline-dsf-tst-02/**`
- `research/pilots/deepseek-full-pilot/runs/baseline-dsf-gov-01/**`
- `research/pilots/deepseek-full-pilot/runs/baseline-dsf-evd-01/**`
- `reports/POS-0030-technical-report.md`
- `tests/run-agent-wrapper.sh`
- `tests/run-roles.sh`
- `tickets/open/POS-0030-deepseek-baseline-wave-2.md`

## Verification

- DSF-TST-02:
  - `tests/run-roles.sh` passed.
  - `grep -q 'authority check failed' tests/run-roles.sh` passed.
  - `git diff --check` passed.
- DSF-GOV-01:
  - `tests/run-agent-wrapper.sh` passed.
  - `bash -n bin/palari lib/palari/*.bash` passed.
  - `grep -q 'missing' tests/run-agent-wrapper.sh` passed.
  - `git diff --check` passed.
- DSF-EVD-01:
  - `grep -q 'local evidence is review evidence' research/evidence-matrix.md`
    passed.
  - `grep -q 'trusted remote CI' research/evidence-matrix.md` passed.
  - `git diff --check` passed.

## CI Evidence

POS-0030 ticket-level Palari checks passed in the review-ready state:

- `tests/run-roles.sh` passed.
- `tests/run-agent-wrapper.sh` passed.
- `bash -n bin/palari lib/palari/*.bash` passed.
- `git diff --check` passed.
- `./bin/palari scope-check POS-0030` passed.
- `./bin/palari lint POS-0030` passed.
- `./bin/palari ci POS-0030` passed.

CI evidence bundle:

- `reports/evidence/POS-0030/verification.log`
- `reports/evidence/POS-0030/junit.xml`
- `reports/evidence/POS-0030/manifest.json`
- `reports/evidence/POS-0030/palari.sarif`

## Risks / Follow-Ups

- Execution baseline was `c5b9549`, which includes accepted POS-0028 and
  POS-0029 pilot artifacts. This means prior wave artifacts existed in the repo
  snapshot available to the model sessions. Score this as a confounder during
  POS-0032.
- DSF-TST-02 stdout shows a broad file listing that included prior run artifact
  paths. No prior transcript content was used as task input, but this should be
  considered during fresh review and scoring.
- DSF-GOV-01 and DSF-EVD-01 raw model diffs used non-ASCII dash punctuation.
  Ticket integration normalized those separators to ASCII while preserving the
  substance. Raw and integrated diffs are both preserved.
- DSF-EVD-01 had one in-session objective-check correction after the required
  lowercase grep phrase was initially capitalized.
- No public claims about safety, performance, speed, productivity, or model
  quality should be made from this wave alone.
