# OUT-0001 Reviewer Note

## Review Result

Decision: implementation review pending final CI.

## Findings

- Outcome artifacts can be created in `outcomes/open` and recorded into
  `outcomes/recorded`.
- Outcome lint checks linked workflow, goal, ticket, decision, and evidence
  references when present.
- `outcome record` requires `--by NAME` and does not accept work.
- Policy candidates now include linked recorded outcome counts/details when
  outcomes reference source tickets or decisions.

## Verification Reviewed

Passed during implementation:

- `bash -n lib/palari/outcomes.bash`
- `bash -n bin/palari`
- `python3 -m py_compile adapters/planning/policy_candidates.py`
- `./tests/run-outcomes.sh`
- `./tests/run-policy-candidates.sh`

Final ticket gates and CI are still pending in this draft note.

## Required Changes

None identified so far.

## Risks

- Outcome records can be low quality if humans do not link evidence.
- Candidate citation of outcomes is contextual, not authority-granting.

## Recommendation

Run final CI/evidence. If green, update this review to accept-ready.
