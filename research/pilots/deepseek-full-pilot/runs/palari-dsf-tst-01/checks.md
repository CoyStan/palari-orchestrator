# DSF-TST-01 Checks

## Required Objective Checks

- `tests/run-cli-structure.sh`: passed in the POS-0031 integration worktree.
- `tests/run-golden.sh`: passed in the POS-0031 integration worktree.
- `grep -q 'scope-overlaps' tests/run-cli-structure.sh`: passed.
- `git diff --check`: passed.

## Evidence Files

- `check-cli-structure.out`
- `check-cli-structure.err`
- `check-cli-structure.exit`
- `check-golden.out`
- `check-golden.err`
- `check-golden.exit`
- `check-grep.out`
- `check-grep.err`
- `check-grep.exit`
- `check-diff-check.out`
- `check-diff-check.err`
- `check-diff-check.exit`

## Notes

The model session also ran the required checks successfully before integration.
No skipped checks or reruns were recorded for this slot.
