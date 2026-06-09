# POS-0029 Technical Report

## Summary

POS-0029 ran Palari-governed wave 1 from the accepted DeepSeek full-pilot
manifest: DSF-DOC-01, DSF-CLI-02, and DSF-WEB-01. The prompts included Palari
ticket claim, allowed-path, forbidden-path, scope/lint/CI/report/reviewer
context, and an explicit human acceptance boundary.

This report records execution evidence only. It does not claim Palari improves
safety, speed, performance, productivity, model quality, or implementation
quality.

## Changes

- DSF-DOC-01 completed and added a concise read-only proof-surface boundary to
  `adapters/web/README.md`.
- DSF-CLI-02 completed and made outside-scope `scope-check` diagnostics quote
  the failing path and list allowed rules one per line.
- DSF-WEB-01 completed and improved selected-ticket readiness and empty-state
  labels in `adapters/web/static/app.js`.
- The DeepSeek full-pilot data-capture sheet now records POS-0029 slot
  outcomes, timings, reruns, checks, and confounders.
- Per-slot run folders now include prompts, commands, timestamps, stdout/stderr,
  exit codes, diffs, checks, timing, and reviewer handoff notes.

## Files Changed

- `adapters/web/README.md`
- `adapters/web/static/app.js`
- `lib/palari/agents_review_scope.bash`
- `research/pilots/deepseek-full-pilot/data-capture.md`
- `research/pilots/deepseek-full-pilot/runs/palari-dsf-doc-01/**`
- `research/pilots/deepseek-full-pilot/runs/palari-dsf-cli-02/**`
- `research/pilots/deepseek-full-pilot/runs/palari-dsf-web-01/**`
- `reports/POS-0029-technical-report.md`
- `tickets/open/POS-0029-deepseek-palari-wave-1.md`

## Verification

- DSF-DOC-01:
  - `grep -q 'read-only proof surface' adapters/web/README.md` passed.
  - `grep -q 'does not accept, merge, push, or mutate critical lifecycle state' adapters/web/README.md` passed.
  - `git diff --check` passed.
- DSF-CLI-02:
  - `tests/run-cli-structure.sh` passed.
  - `tests/run-agent-wrapper.sh` passed.
  - `bash -n bin/palari lib/palari/*.bash` passed.
  - `git diff --check` passed.
- DSF-WEB-01:
  - `tests/run-dashboard-rubric.sh` passed.
  - `node --check adapters/web/static/app.js` passed.
  - `python3 -m py_compile adapters/web/server.py` passed.
  - `git diff --check` passed.

## CI Evidence

POS-0029 ticket-level Palari checks passed in the accepted integration state:

- `./bin/palari scope-check POS-0029` passed.
- `./bin/palari lint POS-0029` passed.
- `git diff --check` passed.
- `./bin/palari ci POS-0029` passed.

The Palari CI evidence bundle is:

- `reports/evidence/POS-0029/verification.log`
- `reports/evidence/POS-0029/manifest.json`
- `reports/evidence/POS-0029/junit.xml`
- `reports/evidence/POS-0029/palari.sarif`

## Risks / Follow-Ups

- DSF-DOC-01 and DSF-WEB-01 each had a first opencode attempt that exited `0`
  but produced no patch because the model resolved repository paths under the
  prompt folder. Those first attempts are preserved as `attempt-1-*`; the
  successful reruns used explicit repository-root instructions.
- During execution, POS-0029 was isolated from the POS-0028 accepted-artifact
  worktree before POS-0028 was committed. This kept POS-0029 scope-check clean
  and is recorded as a wave-1 execution confounder.
- The DSF-WEB-01 copy change includes a minor repeated phrase in one empty-state
  sentence: "evidence, evidence artifacts." It passed objective checks but
  should be considered during review.
- No public claims about safety, performance, speed, productivity, or model
  quality should be made from this wave alone.
