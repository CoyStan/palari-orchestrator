# POS-0072 Reviewer Note

## Review Result

Accept-ready for POS-0072 after final fresh-context re-review.

## Findings

Initial and repair re-review findings are recorded below.

## Verification Reviewed

Pending fresh-context reviewer verification. Implementation evidence currently includes:

- `python3 -m py_compile adapters/broker/mock_broker.py`
- `bash -n lib/palari/broker.bash tests/run-broker-mock.sh tests/run-sandbox.sh`
- `./tests/run-broker-mock.sh`
- `./tests/run-sandbox.sh`
- `./bin/palari broker status`

## Required Changes

None remaining.

## Recommendation

Proceed with normal human/authorized acceptance after stack-order tickets ahead
of POS-0072 are accepted.

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

## Repair Re-review Finding

Popper subagent re-reviewed the first repair on 2026-06-15 and found POS-0072
still not accept-ready.

- Finding: sandbox command targets containing `..` path segments could still be
  normalized into an otherwise allowed path and execute as `observed_allowed`.
- Repro:
  `./bin/palari broker sandbox POS-0072 -- sh -c 'printf "traversal\n" > adapters/../contracts/broker.md'`
- Impact: this violated the intended fail-closed sandbox command policy. Path
  traversal should be refused before execution, even when normalization would
  remain inside the repository.

## Second Repair Applied

- Sandbox command parsing now rejects any raw `..` path segment before
  normalization or execution.
- Regression coverage verifies
  `./bin/palari broker sandbox BRK-0100 -- sh -c 'printf "traversal\n" > tests/../README.md'`
  is denied before execution.
- The regression uses `tests/../README.md` because it normalizes to an otherwise
  allowed file for the fixture, proving the denial is traversal-based rather
  than only scope-based.
- The regression checks `executed: false`, `decision: denied`,
  `decision_reason: sandbox_command_refused`, nonzero broker exit, unchanged
  README content, and empty `changed_paths`.

## Second Repair Verification

- `python3 -m py_compile adapters/broker/mock_broker.py`
- `bash -n lib/palari/broker.bash tests/run-broker-mock.sh tests/run-sandbox.sh`
- `./tests/run-broker-mock.sh`
- `./tests/run-sandbox.sh`
- Direct traversal repro against `tests/../README.md`: denied before execution.
- `./bin/palari ci POS-0072`: passed.
- `./bin/palari evidence score POS-0072 --strict`: passed, `100/100`.
- `./bin/palari scope-check POS-0072`: passed.
- `./bin/palari report-lint POS-0072`: passed.

## Second Repair Re-review Finding

Kierkegaard subagent re-reviewed POS-0072 after the second repair on
2026-06-15 and found no POS-0072 code/security finding, but did not mark the
ticket accept-ready because the live worktree had unrelated uncommitted
reviewer-note edits for POS-0070, POS-0071, and POS-0073.

- Confirmed sandbox repair rejects raw `..` before execution.
- Confirmed regression coverage checks traversal is denied with
  `executed: false`.
- Confirmed a temp-copy direct traversal repro for
  `adapters/../contracts/broker.md` was denied before execution, left the target
  unchanged, and reported `changed_paths: []`.
- Confirmed `./tests/run-broker-mock.sh`, `./tests/run-sandbox.sh`,
  `./bin/palari evidence score POS-0072 --strict`,
  `./bin/palari report-lint POS-0072`,
  `./tests/run-policy-simulation.sh`, and
  `bats tests/palari_acceptance.bats` passed.
- Blocking caveat: final live `./bin/palari scope-check POS-0072` failed only
  because out-of-scope POS-0070/POS-0071/POS-0073 reviewer-note edits were dirty
  at the same time.

Required cleanup: commit the cross-ticket reviewer-note bookkeeping, rerun
`./bin/palari scope-check POS-0072` from a clean tree, and run final POS-0072
re-review.

## Final Repair Re-review

Kierkegaard subagent re-reviewed POS-0072 again after the dirty-tree blocker was
resolved on 2026-06-15 and found POS-0072 accept-ready with no findings.

- Confirmed the worktree was clean on `ticket/POS-0097`.
- Confirmed `./bin/palari scope-check POS-0072` passed with
  `0 changed path(s)`.
- Confirmed `./bin/palari report-lint POS-0072` passed.
- Confirmed `./bin/palari evidence score POS-0072 --strict` passed at
  `100/100`, ready.
- Confirmed `./tests/run-broker-mock.sh` and `./tests/run-sandbox.sh` passed.
- Confirmed a direct temp-copy traversal repro for
  `adapters/../contracts/broker.md` was denied before execution, left the target
  unchanged, and reported `changed_paths: []`.
- Confirmed `./bin/palari broker status` still reports mock/local-only posture:
  real side effects disabled, credentials unavailable to agents, no hosted or
  network API access, and no network isolation claim.

Recommendation: proceed with normal authorized human acceptance for POS-0072.
