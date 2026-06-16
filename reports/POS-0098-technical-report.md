# POS-0098 Technical Report

## Session

- Ticket: POS-0098
- Role: implementation
- Branch: ticket/POS-0098
- Target branch: main
- Result: implemented and ready for verification/review

## Files Changed

```text
STATE.md
docs/autonomy/dogfooding-workflow.md
lib/palari/prompt.bash
tests/run-prompt.sh
tickets/open/POS-0098-dogfood-current-main-palari-orchestrator-workflow.md
reports/POS-0098-technical-report.md
reports/human/POS-0098-human-report.md
reports/evidence/POS-0098/
```

## Outcome

- Salvaged the useful stale POS-0098 idea onto current `main`.
- Rebuilt `ticket/POS-0098` from the accepted mainline after POS-0097 merged.
- Added `docs/autonomy/dogfooding-workflow.md` as the concise note for future
  Palari Orchestrator agents.
- Corrected the obsolete guidance: the current base is main, not
  `ticket/POS-0097`, and deleted POS-0097 worktrees must not be followed.
- Documented the first commands a fresh agent should run after context
  compaction: branch/status inspection, fetch/prune, `palari status --next`,
  `palari state`, `palari run --dry-run --until blocked`, and ticket audit.
- Documented the canonical current loop for ticket creation/routing, claim,
  worktree isolation, evidence refresh, fresh-context review, human acceptance,
  and explicit commit/push/merge.
- Updated `STATE.md` to point collaborators at the dogfooding workflow note.
- Updated `palari prompt long-run` so compacted agents reorient with state,
  dry-run planning, and branch/target-branch verification.
- Updated `tests/run-prompt.sh` to assert the new long-run orientation lines.
- Did not change broker behavior, policy acceptance, human quorum behavior,
  ticket acceptance rules, dependencies, secrets, runtime state, external
  services, push/merge behavior, or deployment behavior.

## Verification

- Passed:
  - `test -f docs/autonomy/dogfooding-workflow.md`
  - `grep -q 'current base is main' docs/autonomy/dogfooding-workflow.md`
  - `grep -q 'after context compaction' docs/autonomy/dogfooding-workflow.md`
  - `./tests/run-prompt.sh`
  - `./tests/run-state.sh`
  - `bash -n lib/palari/prompt.bash tests/run-prompt.sh tests/run-state.sh`
  - `git diff --check`
  - `./bin/palari scope-check POS-0098`
  - `./bin/palari lint POS-0098`
  - `./bin/palari report-lint POS-0098`
  - `./bin/palari ci POS-0098`
- Evidence score:
  - `./bin/palari evidence score POS-0098 --strict`: 85/100,
    `needs-review`, because the fresh reviewer note is not yet present.

## CI Evidence

- CI run: `./bin/palari ci POS-0098 --base main`
- Evidence bundle: `reports/evidence/POS-0098/`
- JUnit: `reports/evidence/POS-0098/junit.xml`
- SARIF: `reports/evidence/POS-0098/palari.sarif`
- Attestation: `reports/evidence/POS-0098/manifest.json`
- Base ref: `main`
- CI result: passed
- Evidence score: 85/100, `needs-review`; missing fresh reviewer note.

## Stale Work Handling

- The old dirty POS-0098 worktree was based on the pre-merge POS-0097 stack and
  contained obsolete base/worktree instructions.
- A backup of that stale work was saved under `/tmp` before rebuilding the
  branch from main.
- The old local branch was renamed to `stale/POS-0098-pre-main`; it was not
  pushed or deleted.

## Risks / Follow-Ups

- This ticket is documentation and prompt-orientation only. It does not create
  an autonomous runner or change any governance gate.
- Remote branch cleanup remains separate and was not touched.
