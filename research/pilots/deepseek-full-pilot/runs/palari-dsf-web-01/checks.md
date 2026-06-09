# DSF-WEB-01 Checks

Condition: Palari-governed

## Required Objective Checks

- `tests/run-dashboard-rubric.sh`
  - Result: passed (`dashboard-rubric: ok (static layout checks + contrast)`)
- `node --check adapters/web/static/app.js`
  - Result: passed
- `python3 -m py_compile adapters/web/server.py`
  - Result: passed
- `git diff --check`
  - Result: passed

## Palari-Governed Checks

Wave-level Palari checks are recorded in the POS-0029 technical report and
`reports/evidence/POS-0029/` after all three slots are integrated.

## Scope Notes

- Changed file: `adapters/web/static/app.js`
- The changed file is in POS-0029 `allowed_paths`.
- No forbidden paths were changed.

## Run Outcome

- Final opencode exit code: `0`
- Attempt 1: exit `0`, no patch, path-root failure recorded in
  `attempt-1-*` artifacts.
- Rerun: exit `0`, patch produced and checks passed.
