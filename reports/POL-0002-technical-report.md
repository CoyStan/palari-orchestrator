# POL-0002 Technical Report

## Files Changed

- `adapters/planning/policy_candidates.py`
  - Adds read-only candidate detection from decided decisions and linked ticket
    metadata.
- `lib/palari/policies.bash`, `bin/palari`
  - Adds `palari policy candidates [--json]`.
- `tests/run-policy-candidates.sh`
  - Covers low-risk candidate suggestion, R4 exclusion, JSON output,
    read-only behavior, no policy file creation, and empty-state output.
- `STATE.md`, `CHANGELOG.md`
  - Record the policy candidate capability and boundaries.
- `tickets/open/POL-0002-suggest-policy-candidates-from-repeated-decisions.md`
  - Replaces the generated body with the scoped completion contract.

## Verification

Passed during implementation:

- `bash -n lib/palari/policies.bash`
- `bash -n bin/palari`
- `python3 -m py_compile adapters/planning/policy_candidates.py`
- `./tests/run-policy-candidates.sh`
- `./tests/run-decisions.sh`

## CI Evidence

Pending final `palari ci POL-0002 --base ticket/POL-0001`.

## Risks / Follow-Ups

- Candidate detection is heuristic and intentionally conservative.
- It requires decided decisions linked to tickets so risk and stream/kind are
  inspectable.
- It suggests only simulation policy creation commands and never creates or
  activates policy files.
- Outcome-based candidate scoring remains out of scope until the outcome ledger
  exists.
