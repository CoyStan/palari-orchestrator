# POS-0073 Reviewer Note

## Review Result

Pending fresh-context review.

## Findings

No independent fresh-context findings have been recorded yet. Suggested review focus:

- Confirm `broker check` supports text and JSON output.
- Confirm allowed resources return `allowed: true` with the expected reason.
- Confirm forbidden and outside-scope resources return `allowed: false`.
- Confirm check does not execute actions or create broker evidence.
- Confirm existing mock and sandbox broker behavior still passes.

## Verification Reviewed

Pending fresh-context reviewer verification. Implementation evidence currently includes:

- `python3 -m py_compile adapters/broker/mock_broker.py`
- `bash -n lib/palari/broker.bash tests/run-broker-mock.sh`
- `./tests/run-broker-mock.sh`

## Required Changes

None recorded yet; pending fresh-context review.

## Recommendation

Pending fresh-context review before acceptance.

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
