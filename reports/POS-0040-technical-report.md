# POS-0040 Technical Report

## Summary

POS-0040 defines the conservative dry-run specification for a future
`palari run --dry-run --until blocked` queue runner. This is a planning and
safety-boundary slice only; no runner command or agent execution was added.

## Changes

- Added `docs/autonomy/queue-runner-dry-run.md`.
- Added `tests/run-autonomy-spec.sh`.
- Tightened POS-0040 ticket scope and completion contract.

## Files Changed

- `docs/autonomy/queue-runner-dry-run.md`
- `tests/run-autonomy-spec.sh`
- `tickets/open/POS-0040-autonomous-queue-runner-dry-run-spec.md`
- `reports/POS-0040-technical-report.md`

## Spec Coverage

The dry-run spec defines:

- inputs and outputs,
- ticket selection rules,
- skipped-ticket reasons,
- stop reasons,
- role lenses,
- supervised-mode boundary,
- non-goals,
- first implementation slice.

The spec explicitly says dry-run mode is read-only and must not claim tickets,
spawn agents, accept, commit, push, merge, deploy, mutate production, create
credentials, or bypass ForgeGate/evidence checks.

## Verification

Commands run during implementation:

- `bash -n tests/run-autonomy-spec.sh`
- `tests/run-autonomy-spec.sh`
- `./bin/palari lint POS-0040`
- `./bin/palari scope-check POS-0040`
- `git diff --check`

## CI Evidence

Palari CI evidence is expected under:

- `reports/evidence/POS-0040/verification.log`
- `reports/evidence/POS-0040/junit.xml`
- `reports/evidence/POS-0040/manifest.json`
- `reports/evidence/POS-0040/palari.sarif`

## Risks / Follow-Ups

- This ticket does not implement `palari run`.
- Future code should start with a read-only dry-run command and only later add
  supervised execution behind explicit flags.
- The dry-run planner should reuse accepted `palari prompt`, Founder Inbox, and
  role proposal work after those tickets are accepted and merged.
