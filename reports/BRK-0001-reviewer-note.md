# BRK-0001 Reviewer Note

## Review Result

Decision: accept-ready.

## Findings

- Broker status reports `real_side_effects_enabled: false`.
- `broker run` requires `--mock` and an existing ticket.
- Mock runs write evidence under `reports/evidence/TICKET/broker/RUN-*`.
- Evidence includes command, cwd, exit code, stdout/stderr hashes, observed
  changed paths, and refusal posture.
- Dangerous command patterns are refused before execution, while refusal
  evidence is still preserved.
- CI evidence passed and evidence quality scored 100/100.

## Verification Reviewed

Passed during implementation:

- `bash -n lib/palari/broker.bash`
- `bash -n bin/palari`
- `python3 -m py_compile adapters/broker/mock_broker.py`
- `./tests/run-broker-mock.sh`
- `./tests/run-evidence-quality.sh`

- `./bin/palari scope-check BRK-0001 --base ticket/POL-0002`
- `./bin/palari ci BRK-0001 --base ticket/POL-0002`
- `./bin/palari evidence score BRK-0001`

## Required Changes

None identified so far.

## Risks

- This is not a sandbox and does not prove security for arbitrary commands.
- Real side effects, credentials, and policy authorization are intentionally
  out of scope.

## Recommendation

Accept BRK-0001.
