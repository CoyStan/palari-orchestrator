# DSF-GOV-01 Checks

Condition: Baseline

## Required Objective Checks

- `tests/run-agent-wrapper.sh`
  - Result: passed
- `bash -n bin/palari lib/palari/*.bash`
  - Result: passed
- `grep -q 'missing' tests/run-agent-wrapper.sh`
  - Result: passed
- `git diff --check`
  - Result: passed

## Scope Notes

- Changed files: `lib/palari/agents_review_scope.bash`, `tests/run-agent-wrapper.sh`
- The changed files are in POS-0030 allowed paths.
- No forbidden paths were changed.

## Run Outcome

- opencode exit code: `0`
- No rerun was attempted.
- No skipped checks.
- Integration note: raw model diff used an em dash in the diagnostic; ticket worktree integration normalized that punctuation to ASCII while preserving the diagnostic meaning.
