# POS-0072 Reviewer Note

## Review Result

Pending fresh-context review.

## Findings

No independent fresh-context findings have been recorded yet. Suggested review focus:

- Confirm sandbox broker mode runs commands in a disposable repo copy and does not copy changes back.
- Confirm allowed scoped changes produce `decision: observed_allowed`.
- Confirm forbidden or outside-scope changes produce `decision: denied_or_violation` and a nonzero broker exit.
- Confirm evidence includes changed paths, forbidden path changes, and `patch.diff`.
- Confirm docs/status do not claim network isolation or real side-effect authority.

## Verification Reviewed

Pending fresh-context reviewer verification. Implementation evidence currently includes:

- `python3 -m py_compile adapters/broker/mock_broker.py`
- `bash -n lib/palari/broker.bash tests/run-broker-mock.sh tests/run-sandbox.sh`
- `./tests/run-broker-mock.sh`
- `./tests/run-sandbox.sh`
- `./bin/palari broker status`

## Required Changes

None recorded yet; pending fresh-context review.

## Recommendation

Pending fresh-context review before acceptance.

## Evidence Notes

- `tests/run-broker-mock.sh` verifies allowed README changes stay inside sandbox evidence and do not mutate the real README.
- The same test verifies a sandbox `.env` write returns nonzero and remains outside the real repo.
- `broker status` says `network_isolation_enforced: false`.

## Fresh Review Finding

Initial fresh-context review by Dirac subagent on 2026-06-15 found POS-0072
not accept-ready.

- Finding: sandbox mode ran requested commands as normal host subprocesses with
  only `cwd` set to the disposable repo and a scrubbed environment, then only
  checked `git status` inside that temp repo. A command could still write
  absolute host paths, read host credential files, or use network-capable tools
  not caught by the dangerous-snippet list, while returning
  `decision: observed_allowed` if the temp repo changes were allowed.
- Impact: this conflicted with the claimed ticket-scoped boundary and with
  evidence fields saying credentials/network/side effects were unavailable.

## Repair Applied

- Sandbox execution is now fail-closed to a narrow repo-file write subset:
  `sh -c 'printf ... > relative-repo-path'`.
- Absolute paths, path traversal, shell expansion, command chaining, pipes,
  redirects from files, and commands outside that subset are refused before
  execution.
- Sandbox commands now run with temporary `HOME` and `TMPDIR` values.
- Evidence records `sandbox_command_policy: simple_printf_redirect_only`.
- Regression coverage verifies an absolute host-path write is denied before
  execution and does not create the host file.

## Repair Verification

- `python3 -m py_compile adapters/broker/mock_broker.py`
- `bash -n lib/palari/broker.bash tests/run-broker-mock.sh tests/run-sandbox.sh`
- `./tests/run-broker-mock.sh`
- `./tests/run-sandbox.sh`
- `./tests/run-company-os-snapshot.sh`
- `./tests/run-risks.sh`
- `./tests/run-policy-simulation.sh`
- `bats tests/palari_acceptance.bats`
