# POS-0060 Reviewer Note

## Review Result

Reopen

## Findings

- P1 Blocking: `coverage_failures` can report a false reason and text output
  does not distinguish mixed candidate failure classes. In a temporary R5
  privacy case with one under-authorized `privacy:L5` human and one
  R5-authorized `privacy:L5` human at R5 capacity, JSON correctly showed both
  `under_authorized` and `at_capacity`, but `coverage_failures` said
  `privacy:L5 has candidates but none with R5 authority`. That is false because
  an authorized candidate exists but is at capacity. This violates the required
  output distinction.

## Verification Reviewed

- Inspected the ticket, changed diff from `8075352^` to `8075352`,
  implementation, contracts, tests, technical report, human report, and evidence
  bundle.
- Ran locally:
  - `./bin/palari human lint`
  - `./tests/run-company-os-demo.sh`
  - `./tests/run-human-governance-load.sh`
  - `./tests/run-human-governance.sh`
  - `./tests/run-workflow-planning.sh`
- All listed commands passed.
- Also ran temporary synthetic checks for underleveled and mixed
  under-authorized plus at-capacity cases. The mixed case exposed the blocking
  finding above.
- Stored CI evidence reports pass, but `reports/evidence/POS-0060/manifest.json`
  records parent SHA `3c85adf...`, not reviewed commit `8075352...`; reviewer
  did not rerun `./bin/palari ci POS-0060` because it writes evidence artifacts.

## Scope / Safety

- Core enforcement is mostly in place: skill level, authority ceiling,
  risk-specific capacity, and R5 policy-change approval are checked before
  coverage counts.
- Changed paths stay within the ticket's allowed surfaces.
- No evidence weighting, workflow risk-source planning, policy acceptance,
  broker behavior, deploy, secrets, dependencies, or lockfiles were changed.
- Reviewer made no edits; the worktree remained clean before this note update.

## Required Changes

- Fix coverage failure reporting so text and JSON accurately distinguish every
  nonempty failure class for a required skill, including mixed cases.
- Add regression coverage for mixed candidate states, at minimum
  under-authorized plus at-capacity for the same skill.
- Rerun ticket verification and refresh evidence after the fix.

## Recommendation

Reopen POS-0060. The enforcement path is close, but the output distinction
requirement is not satisfied in mixed candidate cases.

## Evidence

- `reports/evidence/POS-0060/verification.log`
- `reports/evidence/POS-0060/junit.xml`
- `reports/evidence/POS-0060/palari.sarif`
- `reports/evidence/POS-0060/manifest.json`

---

## Fresh-Context Re-Review After Repair

Review result: Accept-ready.

Reviewer: Turing subagent, 2026-06-15.

Scope reviewed:

- Latest stacked worktree `/home/quetza/palari-orchestrator-worktrees/POS-0097`.
- Repair commit `42ddc865c70d9d5b7d5adcaeeccbfceb6af25421`.
- `adapters/planning/hgl.py`
- `tests/run-human-governance-load.sh`
- `reports/evidence/POS-0060/manifest.json`
- `reports/evidence/POS-0060/verification.log`

Findings:

- No reopen findings.
- Mixed candidate-state reporting now emits multiple failure messages instead
  of collapsing to a false single reason.
- The regression covers the real prior case: one under-authorized
  `privacy:L5` candidate plus one R5-authorized `privacy:L5` candidate at R5
  capacity.

Verification:

- `./tests/run-human-governance-load.sh` passed.
- Refreshed POS-0060 evidence records commit
  `42ddc865c70d9d5b7d5adcaeeccbfceb6af25421`, status `passed`, 7 tests, 0
  failures.

Caveat:

- This is stacked-branch evidence refreshed with `--base HEAD`; it attests the
  final stacked repair commit, not an isolated POS-0060-only branch diff.
