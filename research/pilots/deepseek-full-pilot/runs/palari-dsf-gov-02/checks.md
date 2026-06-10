# DSF-GOV-02 Checks

## Required Objective Checks

- `tests/run-golden.sh`: passed in the POS-0031 integration worktree.
- `tests/run-cli-structure.sh`: passed in the POS-0031 integration worktree.
- `grep -q 'Next required action' tests/golden/status.contains.txt`: passed.
- `git diff --check`: passed.

## Evidence Files

- `check-golden.out`
- `check-golden.err`
- `check-golden.exit`
- `check-cli-structure.out`
- `check-cli-structure.err`
- `check-cli-structure.exit`
- `check-grep.out`
- `check-grep.err`
- `check-grep.exit`
- `check-diff-check.out`
- `check-diff-check.err`
- `check-diff-check.exit`

## Notes

Attempt 1 exited `0` but produced no patch after resolving paths under the
prompt folder and hitting opencode external-directory auto-rejections. Attempt
2 used an explicit repository-root instruction and produced the integrated
patch.
