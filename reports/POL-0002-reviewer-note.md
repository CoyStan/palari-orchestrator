# POL-0002 Reviewer Note

## Review Result

Decision: implementation review pending final CI.

## Findings

- `palari policy candidates` inspects decided decisions and linked ticket
  metadata.
- The command only suggests candidates after at least three repeated R0-R2
  decisions with the same risk, kind, and recommended/chosen option pattern.
- R4 decisions are excluded in the focused test, and R3/R4/R5 are excluded by
  the implementation's low-risk allowlist.
- The command does not create policy files or mutate repository state.

## Verification Reviewed

Passed during implementation:

- `bash -n lib/palari/policies.bash`
- `bash -n bin/palari`
- `python3 -m py_compile adapters/planning/policy_candidates.py`
- `./tests/run-policy-candidates.sh`
- `./tests/run-decisions.sh`

Final ticket gates and CI are still pending in this draft note.

## Required Changes

None identified so far.

## Risks

- The heuristic is deliberately simple. It should not be treated as real policy
  authority.
- Richer candidate scoring should wait for outcome records and more evidence.

## Recommendation

Run final CI/evidence. If green, update this review to accept-ready.
