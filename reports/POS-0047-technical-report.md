# POS-0047 Technical Report

## Session

- Ticket: POS-0047
- Role: specialist (claude)
- Branch: combine/plugin-import
- Result: in-review

## Files Changed

```text
lib/palari/agents_review_scope.bash
bin/palari
tests/run-agent-mock.sh
README.md
.github/workflows/test.yml
.github/workflows/static-analysis.yml
CHANGELOG.md
tickets/open/POS-0047-deterministic-mock-executor-for-demos-and-tests.md
```

## Outcome

- What changed: `cmd_agent_run` was refactored into a shared lifecycle
  (worktree, packet, evidence dir, command.txt, gates, summary) with two
  shims per executor: `executor_<name>_describe` and `executor_<name>_run`.
  New mock executor: `--executor mock --scenario safe|forbidden-path|
  outside-scope` performs a scripted local edit (append to
  `docs/mock-executor.md`, `.env`, or `mock-executor-outside.txt`) instead of
  invoking an AI tool. Failed scope-check now prints "refused the change;
  evidence preserved, ticket state not advanced". `--scenario` is rejected
  for non-mock executors; unknown scenarios are rejected.
- What did not change: the opencode contract - dry-run output lines,
  command.txt content, denied-commands list, evidence layout, session export,
  and exit-code semantics are byte-compatible (`tests/run-agent-wrapper.sh`
  passes unchanged). One run per clean worktree remains the rule.

## Verification

- `tests/run-agent-mock.sh` -> `agent-mock: ok` (6 cases: dry-run without AI
  tool, safe passes gates, forbidden-path refused with `.env` named in
  scope-check.err and ticket state still open, outside-scope refused,
  --scenario rejected for opencode, unknown scenario rejected)
- `tests/run-agent-wrapper.sh` -> ok (opencode regression)
- `tests/run-cli-structure.sh` -> ok
- `./bin/palari scope-check POS-0047` -> ok (8 changed paths)
- `shellcheck -x` / `shfmt -d` on changed shell files -> clean

## CI Evidence

- `./bin/palari ci POS-0047` -> ok
- Bundle: `reports/evidence/POS-0047/`

## Risks / Follow-Ups

- Mock scenario target paths are fixed by contract; demo/test tickets must
  scope `docs/**` for the safe scenario.
- POS-0048 adds the codex executor onto these shims.
