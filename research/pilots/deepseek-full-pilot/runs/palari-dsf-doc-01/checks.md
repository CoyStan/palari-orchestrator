# DSF-DOC-01 Checks

Condition: Palari-governed

## Required Objective Checks

- `grep -q 'read-only proof surface' adapters/web/README.md`
  - Result: passed
- `grep -q 'does not accept, merge, push, or mutate critical lifecycle state' adapters/web/README.md`
  - Result: passed
- `git diff --check`
  - Result: passed

## Palari-Governed Checks

Wave-level Palari checks are recorded in the POS-0029 technical report and
`reports/evidence/POS-0029/` after all three slots are integrated.

## Scope Notes

- Changed file: `adapters/web/README.md`
- The changed file is in POS-0029 `allowed_paths`.
- No forbidden paths were changed.

## Run Outcome

- Final opencode exit code: `0`
- Attempt 1: exit `0`, no patch, path-root failure recorded in
  `attempt-1-*` artifacts.
- Rerun: exit `0`, patch produced and checks passed.
