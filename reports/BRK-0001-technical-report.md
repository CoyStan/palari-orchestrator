# BRK-0001 Technical Report

## Files Changed

- `contracts/broker.md`
  - Defines the mock-only broker evidence boundary.
- `adapters/broker/mock_broker.py`
  - Captures observed-command evidence with stdout/stderr hashes, exit code,
    cwd, command, observed changed paths, and side-effect posture.
- `lib/palari/broker.bash`, `bin/palari`
  - Adds `palari broker run`, `palari broker evidence`, and
    `palari broker status`.
- `tests/run-broker-mock.sh`
  - Covers successful mock evidence, missing `--mock`, missing ticket,
    dangerous command refusal, text/JSON evidence listing, and broker status.
- `STATE.md`, `CHANGELOG.md`
  - Record the mock broker boundary capability.
- `tickets/open/BRK-0001-add-mock-broker-evidence-boundary.md`
  - Replaces the generated body with the scoped completion contract.

## Verification

Passed during implementation:

- `bash -n lib/palari/broker.bash`
- `bash -n bin/palari`
- `python3 -m py_compile adapters/broker/mock_broker.py`
- `./tests/run-broker-mock.sh`
- `./tests/run-evidence-quality.sh`

## CI Evidence

Pending final `palari ci BRK-0001 --base ticket/POL-0002`.

## Risks / Follow-Ups

- This is mock evidence only. Real broker side effects require a separate R5
  ticket and stronger authorization/security checks.
- The dangerous-command filter is intentionally simple and conservative; it is
  not a sandbox or security boundary.
- The broker currently records evidence but does not yet feed snapshot counts.
