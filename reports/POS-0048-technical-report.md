# POS-0048 Technical Report

## Session

- Ticket: POS-0048
- Role: specialist (claude)
- Branch: combine/plugin-import
- Result: in-review

## Files Changed

```text
lib/palari/agents_review_scope.bash
bin/palari
adapters/codex/README.md
tests/run-agent-codex.sh
README.md
.github/workflows/test.yml
.github/workflows/static-analysis.yml
CHANGELOG.md
tickets/open/POS-0048-codex-executor-adapter-and-codex-doctor.md
```

## Outcome

- What changed: Codex is a governed executor on the POS-0047 shims.
  `executor_codex_describe`/`executor_codex_run` own the entire CLI contract:
  `codex exec --cd <worktree> --sandbox workspace-write [--model M] --json
  --output-last-message <evidence>/last-message.txt <prompt>`, where the
  prompt points Codex at the mission packet. The contract was VERIFIED
  against the installed codex-cli 0.138.0 (`codex exec --help`), not guessed:
  all five flags exist with those spellings. New `palari codex doctor`
  (errors: AGENTS.md, bin/palari, config; warnings: CLI on PATH, prompts
  installed; honors CODEX_PROMPTS_DIR) and `palari codex install` wrapping
  the existing prompt installer.
- What did not change: no live Codex invocation was made (network/quota);
  gates, evidence layout, and the one-run-per-clean-worktree rule are
  inherited unchanged from the shared lifecycle.

## Verification

- `tests/run-agent-codex.sh` -> `agent-codex: ok` (5 cases: dry-run without
  CLI dependency, real-run requires CLI [auto-skipped when codex present],
  --scenario rejected, doctor warn->ok cycle via install, doctor fails
  without AGENTS.md)
- `tests/run-agent-mock.sh`, `tests/run-cli-structure.sh`,
  `tests/run-plugin-structure.sh` -> ok (regressions)
- `./bin/palari scope-check POS-0048` -> ok (10 changed paths)
- `shellcheck -x` / `shfmt -d` on changed shell files -> clean
- `codex exec --help` (codex-cli 0.138.0) -> all shim flags confirmed

## CI Evidence

- `./bin/palari ci POS-0048` -> ok
- Bundle: `reports/evidence/POS-0048/`

## Risks / Follow-Ups

- A live end-to-end Codex run has not been exercised; first real run should
  be observed by a human (it spends OpenAI quota).
- If the Codex CLI changes flags, only the two codex shims change.
