# DSF-EVD-01 Checks

Condition: Baseline

## Required Objective Checks

- `grep -q 'local evidence is review evidence' research/evidence-matrix.md`
  - Result: passed
- `grep -q 'trusted remote CI' research/evidence-matrix.md`
  - Result: passed
- `git diff --check`
  - Result: passed

## Scope Notes

- Changed file: `research/evidence-matrix.md`
- The changed file is in POS-0030 allowed paths.
- No forbidden paths were changed.

## Run Outcome

- opencode exit code: `0`
- No rerun was attempted.
- No skipped checks.
- Integration note: raw model diff used em dashes; ticket worktree integration normalized those separators to ASCII while preserving the claim boundaries.
