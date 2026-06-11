# POS-0048 Reviewer Note

Fresh-context review of commit 0c83f7f (Codex executor adapter and codex
doctor) on branch combine/plugin-import. Reviewer did not implement this
work.

## Review Result

Accept. The commit delivers exactly what the ticket scopes: Codex as a
governed executor riding the shared POS-0047 lifecycle, the entire CLI
contract isolated in `executor_codex_describe`/`executor_codex_run` in
`lib/palari/agents_review_scope.bash`, a dry-run path that works without the
Codex CLI, and a `palari codex doctor`/`install` readiness surface. All
verification commands re-ran clean from a fresh context, and the claimed
CLI contract was independently re-verified against the installed
codex-cli 0.138.0.

## Findings

- CLI contract verified, not guessed: I ran `codex exec --help` myself
  (codex-cli 0.138.0). All five flags the shim uses exist with the exact
  spellings used: `-C, --cd <DIR>`, `-s, --sandbox <SANDBOX_MODE>` with
  `workspace-write` as a documented value, `-m, --model <MODEL>`, `--json`
  (JSONL events to stdout, matching the `run.jsonl` capture), and
  `-o, --output-last-message <FILE>`. No real `codex exec` was run.
- Shim isolation holds: `codex` appears in exactly two execution sites
  (`executor_codex_describe` for the plan, `executor_codex_run` for the real
  call), both sharing `codex_full_prompt`. The describe path's
  last-message location (`$worktree/$EVIDENCE_DIR/$ticket_id/executor/codex/
  last-message.txt`) matches the run path's `$evidence_dir/last-message.txt`
  given how `cmd_agent_run` constructs `evidence_dir`.
- Scope: every path in the commit (.github/workflows/*, CHANGELOG.md,
  README.md, adapters/codex/README.md, bin/palari,
  lib/palari/agents_review_scope.bash, reports/**, tests/run-agent-codex.sh,
  tickets/open/POS-0048-*) is inside the ticket's allowed_paths; no
  forbidden paths touched.
- Definition of done met: dry-run works without the CLI and writes
  command.txt to evidence (test-covered); a real run shells out through the
  single shim only; doctor reports each readiness check with tests covering
  the warn->ok prompt cycle and the hard AGENTS.md failure.
- Minor (non-blocking): the doctor's final "ok executor support" line is an
  unconditional informational print, not an actual check of the entry point;
  the adapters/codex README implies it is "reported" like the others.
- Minor (non-blocking): the technical report says scope-check passed with
  "10 changed paths" while the committed verification.log records 13; a
  prose/evidence drift from re-running at different times, not a gate issue.
- Minor (non-blocking): the missing-CLI real-run test case auto-skips on
  machines where codex is installed (including this one), so that branch is
  exercised only on codex-less environments such as CI runners. The skip is
  printed explicitly, which is honest.
- Minor (non-blocking): doctor's prompt-pack check hardcodes the four prompt
  names; this matches adapters/codex/prompts exactly today but must be kept
  in sync if the pack grows.

## Verification Reviewed

- `tests/run-agent-codex.sh` re-run from repo root: `agent-codex: ok`
  (exit 0; "codex CLI present; skipping missing-CLI check" noted).
- `codex exec --help` (codex-cli 0.138.0): confirmed `--cd`,
  `--sandbox workspace-write`, `--model`, `--json`,
  `--output-last-message` all exist. No real `codex exec` invoked.
- `CODEX_PROMPTS_DIR=<empty temp dir> ./bin/palari codex doctor`: exits 0
  with `warning codex prompts not installed; run palari codex install` and
  final `codex doctor: ok` - matches the documented warning-only behavior.
- `shellcheck -x bin/palari lib/palari/agents_review_scope.bash
  adapters/codex/install.sh tests/run-agent-codex.sh`: clean. `shfmt -d` on
  the changed shell files: clean.
- `./bin/palari lint`: all gates ok except `report-lint: POS-0048: missing
  fresh-context reviewer note`, which this note satisfies.
- Changed paths checked manually against ticket allowed_paths/forbidden
  paths: all in scope.

## Required Changes

None blocking. Optional follow-ups for a future ticket: make the doctor's
"executor support" line a real check (e.g., grep the dispatch table or probe
`agent run --help`), and reconcile the changed-path count between the
technical report and verification.log.

## Recommendation

Accept. The work matches the ticket's goal, scope, and definition of done;
verification reproduces cleanly from a fresh context; the residual risk
(first live Codex run unobserved) is correctly disclosed in the technical
report and should be watched by a human on first real use, as the report
already recommends.
