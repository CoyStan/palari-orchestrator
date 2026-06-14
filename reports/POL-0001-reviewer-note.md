# POL-0001 Reviewer Note

## Review Result

Decision: accept-ready.

## Findings

- Policy artifacts are introduced under proposed, active, and revoked queues.
- New policy commands are simulation-only and do not provide an acceptance
  command path.
- `palari policy simulate` reads ticket, policy, decision, report, and evidence
  state and reports `would_accept` or `would_not_accept`.
- R5 tickets are refused by the simulator, and policy `risk_max: R5` is linted
  and creation-refused.
- Unknown conditions are permitted in artifacts but fail closed during
  simulation with a visible reason.
- CI evidence passed and evidence quality scored 100/100.

## Verification Reviewed

Passed during implementation:

- `bash -n lib/palari/policies.bash`
- `bash -n bin/palari`
- `python3 -m py_compile adapters/planning/policy_simulation.py`
- `./tests/run-policy-simulation.sh`
- `./tests/run-evidence-quality.sh`

- `./bin/palari scope-check POL-0001 --base ticket/DSH-0001`
- `./bin/palari ci POL-0001 --base ticket/DSH-0001`
- `./bin/palari evidence score POL-0001`

## Required Changes

None identified so far.

## Risks

- This is R5 governance infrastructure, so future expansion must keep real
  acceptance behind a separate human-approved ticket.
- Simulation uses repo evidence and reports; it is not a credential, broker, or
  production side-effect boundary.

## Recommendation

Accept POL-0001.
