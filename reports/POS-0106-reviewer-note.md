# POS-0106 Reviewer Note

## Review Result

not accept-ready

## Findings

Blocking: generated artifact `allowed_paths` lint is incomplete.
`lint_one_ticket` relies on `hygiene_scope_pattern_generated`, but that helper
does not consistently match the same generated paths that
`hygiene_path_generated` recognizes. A read-only probe showed
`gate/forgegate/__pycache__/tracked.pyc`,
`gate/forgegate/__pycache__/**`, and `gate/**/*.pyc` are not classified as
generated lint scopes even though the path classifier treats nested
`__pycache__` / `.pyc` files as generated.

This leaves a tracked generated artifact able to become an explicit allowed
path and pass lint, which violates the POS-0106 focus that generated artifact
`allowed_paths` are lint errors. Relevant code:
`lib/palari/hygiene.bash`, `lib/palari/agents_review_scope.bash`, and the
current regression only checks `node_modules/**` in `tests/run-hygiene.sh`.

## Verification Reviewed

Reviewed `/tmp/POS-0106-reviewer-packet.md`, POS-0106 ticket, implementation
diff against `ticket/POS-0105`, changed source/test/doc files, technical
report, human report, and `reports/evidence/POS-0106`.

Read-only checks run:

- `git status --short --branch`: clean on `ticket/POS-0106`
- `./bin/palari status`: 0 changed paths
- `git diff --name-status ticket/POS-0105...HEAD`: 11 POS-0106-scoped changed paths
- `bash -n ...`: passed
- `./bin/palari scope-check POS-0106 --base ticket/POS-0105`: passed
- `./bin/palari lint POS-0106`: passed with only existing `serves_goal` warning
- `git diff --check ticket/POS-0105...HEAD`: passed

Evidence reviewed reports `passed`, 7 tests, 0 failures. Source changes after
evidence were not present; post-evidence commits only added POS-0106
report/evidence/ticket bookkeeping. No forbidden, secret, dependency, deploy,
or runtime paths were changed.

## Required Changes

Fix generated `allowed_paths` lint so it rejects nested generated artifact
paths/globs consistently with `hygiene_path_generated`.

Add focused regression coverage for nested generated allowed paths, for example
`gate/forgegate/__pycache__/**`, `gate/forgegate/__pycache__/tracked.pyc`, or
`gate/**/*.pyc`, and verify lint fails clearly.

## Recommendation

Reopen for the bounded lint/classification fix and regression test above. Do
not accept POS-0106 yet.

## Re-review Result

accept-ready

## Findings

No findings. The repair closes the earlier blocker: generated `allowed_paths`
lint now rejects the requested cases consistently with generated hygiene
classification.

## Verification Reviewed

- Reviewed `/tmp/POS-0106-rereview-packet.md` and this reviewer note.
- Confirmed focused regression coverage in `tests/run-hygiene.sh` for
  `node_modules/**`, `gate/forgegate/__pycache__/**`,
  `gate/forgegate/__pycache__/tracked.pyc`, and `gate/**/*.pyc`.
- `./bin/palari scope-check POS-0106 --base ticket/POS-0105`: passed, 12
  changed paths.
- `./bin/palari lint POS-0106`: passed with only the existing `serves_goal`
  warning; `report-lint: ok`.
- `bash -n ...`: passed.
- `./tests/run-hygiene.sh`: passed.
- Evidence manifest is refreshed for repair commit `f6713f0`; branch tip
  `1493fb2` only updates stored evidence files.
- Evidence reports `passed`, 7 tests, 0 failures, and artifact hashes match.
- Workspace remained clean. No unrelated forbidden, secret, dependency,
  deploy, runtime, or production path changes found.

## Required Changes

None.

## Recommendation

accept-ready.
