# POS-0073 Reviewer Note

## Review Result

Accept-ready for POS-0073 after repair re-review.

## Findings

No remaining findings after repair.

## Verification Reviewed

Initial implementation evidence included:

- `python3 -m py_compile adapters/broker/mock_broker.py`
- `bash -n lib/palari/broker.bash tests/run-broker-mock.sh`
- `./tests/run-broker-mock.sh`

## Required Changes

None remaining after the repair below.

## Recommendation

Proceed with normal human/authorized acceptance after stack-order tickets ahead
of POS-0073 are accepted.

## Evidence Notes

- `tests/run-broker-mock.sh` creates a risk R3 fixture and checks JSON output for `requires_human: true`.
- The same test confirms no `reports/evidence/BRK-0101/broker` directory is created by check-only calls.

## Fresh Review Finding

Initial fresh-context review by Dalton subagent on 2026-06-15 found POS-0073
not accept-ready.

- Finding: `broker check` compared the raw resource string to allowed and
  forbidden globs without normalizing `..` segments first.
- Repro:
  `./bin/palari broker check POS-0073 --tool filesystem --action write --resource 'adapters/broker/../deploy/foo' --json`
- Prior result: `allowed: true` because the raw string matched
  `adapters/broker/**`.
- Expected result: `allowed: false`, because the path normalizes to
  `adapters/deploy/foo`, outside the ticket's allowed broker path.

## Repair Applied

- Broker resource matching now normalizes `.` and `..` segments before
  evaluating allowed and forbidden path globs.
- Absolute paths and repository-escaping resource strings fail closed.
- JSON check output includes `normalized_resource`.
- Regression coverage verifies
  `adapters/broker/../deploy/foo` returns `allowed: false`.

## Repair Verification

- `python3 -m py_compile adapters/broker/mock_broker.py`
- `bash -n lib/palari/broker.bash tests/run-broker-mock.sh tests/run-sandbox.sh`
- `./tests/run-broker-mock.sh`
- `./tests/run-sandbox.sh`
- `./tests/run-company-os-snapshot.sh`
- `./tests/run-risks.sh`
- `./tests/run-policy-simulation.sh`
- `bats tests/palari_acceptance.bats`

## Repair Re-review

Noether subagent re-reviewed POS-0073 after the repair on 2026-06-15 and found
no remaining blocker in broker permission check path handling.

- Confirmed `broker check` now normalizes `.` and `..` resource segments before
  allowed/forbidden matching.
- Confirmed the prior repro now fails closed with `allowed: false`,
  `normalized_resource: adapters/deploy/foo`, and
  `reasons: ["resource is outside ticket allowed paths"]`.
- Confirmed allowed resource `adapters/broker/mock_broker.py` returns
  `allowed: true`.
- Confirmed forbidden/outside/absolute/escaping resources return
  `allowed: false`.
- Confirmed check-only probes did not create broker evidence.

Re-review verification:

- `git status --short --branch`: clean worktree, `ticket/POS-0097` ahead of
  origin.
- `./tests/run-broker-mock.sh`: passed.
- `./tests/run-sandbox.sh`: passed.
- Direct traversal check for `adapters/broker/../deploy/foo`: passed expected
  denial.
- `./bin/palari evidence score POS-0073 --strict`: passed, `100/100`.
- `./bin/palari scope-check POS-0073`: passed.
- `./bin/palari report-lint POS-0073`: passed.
