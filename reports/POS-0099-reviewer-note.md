# POS-0099 Fresh-Context Reviewer Note

## Review Result

- Ticket: POS-0099
- Branch: ticket/POS-0099
- Base: main
- Scope reviewed: governed adoption lifecycle, adoption plan generation,
  approval validation, source/target drift checks, ignored target file and
  directory handling, path manifest integrity, and ticket scope.
- Result: accept-ready after bounded repair and focused fresh-context
  re-review.

## Reviewer Trail

Earlier fresh-context review passes found concrete adoption-plan bypasses and
each was repaired before this note was finalized:

- Missing validation for `excluded_foreign_governance_artifacts`.
- Source copied-content drift after approval was not detected.
- Command flags such as `--force`, `--ci`, and hooks were not bound to the
  reviewed plan.
- Blank approval metadata could pass.
- The path manifest did not enumerate every write class.
- Source tree mutations and copied symlink changes after approval could bypass
  the reviewed plan.
- Target `HEAD` drift after plan generation could bypass review.
- Custom target Palari directory config could make the reviewed path manifest
  inaccurate.
- A truncated path manifest could still allow writes.
- Ignored target files under planned write paths could bypass the clean
  worktree check.
- Empty target repositories with unborn `HEAD` values recorded malformed
  target-head text.

## Findings

Final full review before this note found one remaining bounded issue, now
repaired:

- `codex review --base main` found that ignored parent directories such as
  `tickets/` could hide governance files under planned child write paths. Those
  files became active after adoption.

Repair:

- Commit `a8bd7e3 fix: reject ignored parent adoption drift` changed
  `adoption_target_path_in_plan` to treat overlap in both directions and added
  regression coverage for ignored `tickets/` hiding `tickets/open/MAL-0001.md`.

## Final Re-Review

`codex review --base main` could not be rerun after the repair because the
Codex account hit its usage limit before review began. A broad Claude fallback
timed out without producing a verdict, so it is not counted as review evidence.

A focused independent Claude re-review was then run against the final repair
delta:

```text
timeout 180 claude --model sonnet --permission-mode bypassPermissions --max-budget-usd 2 -p "Fresh-context focused re-review for POS-0099 after the last repair commit..."
```

The re-review checked the final `HEAD~1..HEAD` delta, the nearby ignored-target
overlap logic, and `./tests/run-adoption.sh`.

Verdict:

```text
ACCEPT-READY
```

Reviewer conclusion:

- The ignored parent directory bypass is fixed.
- The new regression directly exercises the repaired path.
- `./tests/run-adoption.sh` passed.
- No new issue was introduced by the final delta.

No remaining blocking findings were reported by the final focused independent
re-review.

## Verification Reviewed

- `bash -n bin/palari lib/palari/init_adopt.bash tests/run-adoption.sh tests/run-cli-structure.sh`
- `shellcheck -x bin/palari scripts/palari tests/run-adoption.sh lib/palari/init_adopt.bash`
- `shfmt -d bin/palari lib/palari/init_adopt.bash tests/run-adoption.sh tests/run-cli-structure.sh`
- `./tests/run-adoption.sh`
- `./tests/run-cli-structure.sh`
- `./tests/run-golden.sh`
- `./bin/palari ci POS-0099`
- `./bin/palari scope-check POS-0099`
- `./bin/palari report-lint POS-0099`

## Required Changes

- Required change from final full review: reject ignored parent directories
  that can hide files under planned adoption writes.
- Status: completed in commit `a8bd7e3`.
- Regression: `tests/run-adoption.sh` now covers ignored `tickets/` hiding
  `tickets/open/MAL-0001.md`.

## Recommendation

POS-0099 is accept-ready for founder review after final evidence scoring and
ticket transition to `in-review`.
