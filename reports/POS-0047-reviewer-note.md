# POS-0047 Reviewer Note

## Review Result

Accept. Commit 1661236 delivers the deterministic mock executor as specified:
`cmd_agent_run` is refactored into a shared lifecycle (worktree, packet,
evidence dir, command.txt, gates, summary) with per-executor `describe`/`run`
shims, the mock executor covers all three scenarios, failures never advance
ticket state, and the opencode contract survived the refactor byte-compatible.
All changed paths are inside the ticket's `allowed_paths`; no forbidden paths
were touched.

## Findings

- Opencode contract preserved (highest-risk area, verified line-by-line
  against the pre-refactor code): `executor_opencode_describe` and
  `executor_opencode_run` are verbatim moves of the old inline code.
  command.txt content, the denied-commands line, dry-run output lines
  (`executor: %s` resolves to the identical `executor: opencode`), the
  `opencode exit: N` summary line, run.jsonl/run.stderr/session.id/
  session-export.* evidence files, the `OPENCODE_*` env vars, and exit-code
  semantics are all byte-identical for opencode.
- `--model` only when set: confirmed. `executor_opencode_run` keeps the exact
  old if/else (`--model "$model"` only in the non-empty branch), and
  `executor_opencode_describe` keeps the old conditional command substitution
  for the command.txt line. No behavior change.
- `run.exit` written for both executors: confirmed. The write moved into the
  shared lifecycle (`printf '%s\n' "$executor_code" >"$evidence_dir/run.exit"`)
  after the run-shim case, so opencode, mock (and future executors) all get
  it. Minor nuance: for opencode it is now written after session export
  completes rather than immediately after the opencode process exits, so a
  kill during `opencode export` would leave run.exit absent where it formerly
  existed. Low severity; normal-path behavior identical.
- Mock `cd "$worktree"` subshell: no state leak. The `( cd ...; ... )`
  parentheses create a subshell, so the directory change and any shell state
  are confined; redirections target absolute evidence paths in the parent.
  The function is invoked with `|| executor_code=$?`, so a failing scenario
  edit is captured rather than aborting under errexit.
- Minor (non-blocking): `tests/run-agent-mock.sh` asserts
  `grep -Fq "0" .../run.exit`, a substring match that would also pass for
  exit codes 10 or 130. `grep -Fxq "0"` would be exact.
- Minor (informational): the test's "ticket state must not advance" check is
  a weak invariant since `agent run` never mutates ticket frontmatter on any
  path; it guards regressions rather than current behavior. Acceptable.
- The new `scope-check: refused the change; evidence preserved, ticket state
  not advanced` line is additive (failure path only) and has no analogous
  message for a ci-gate failure; cosmetic asymmetry only.
- Hygiene note: the working tree on `combine/plugin-import` already carries
  uncommitted POS-0048 codex changes in the same file
  (`lib/palari/agents_review_scope.bash`), so this review re-ran verification
  against a pristine `git archive` extract of commit 1661236 in addition to
  the repo root.

## Verification Reviewed

- `tests/run-agent-mock.sh` from the repo root: `agent-mock: ok` (exit 0).
- `tests/run-agent-wrapper.sh` from the repo root: `agent-wrapper: ok`
  (exit 0) - the opencode regression contract holds post-refactor.
- Both suites re-run against a pristine extract of commit 1661236 (isolating
  out the uncommitted POS-0048 drift): both pass (exit 0).
- `shellcheck -x bin/palari lib/palari/agents_review_scope.bash
  tests/run-agent-mock.sh`: clean.
- Allowed-paths audit: changed files (.github/workflows/static-analysis.yml,
  .github/workflows/test.yml, CHANGELOG.md, README.md, bin/palari,
  lib/palari/agents_review_scope.bash, reports/POS-0047-technical-report.md,
  reports/evidence/POS-0047/*, tests/run-agent-mock.sh,
  tickets/open/POS-0047-*.md) all match the ticket's allowed_paths; no
  forbidden paths touched.
- CI wiring confirmed: run-agent-mock.sh added to test.yml (`bash -n` plus a
  "Mock executor" run step) and to the shellcheck/shfmt lists in
  static-analysis.yml.
- Technical report cross-checked against the diff; claims (6 test cases,
  byte-compatible opencode contract, evidence bundle) are accurate.

## Required Changes

None blocking. Suggested (non-blocking, may ride along with POS-0048):
tighten `grep -Fq "0"` to `grep -Fxq "0"` for the run.exit assertion in
`tests/run-agent-mock.sh`.

## Recommendation

Accept. Definition of Done is met: all three scenarios behave as specified
with evidence written, no network or AI CLI required, and the opencode path
is unchanged with existing tests passing.
