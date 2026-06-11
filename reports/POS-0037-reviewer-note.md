# POS-0037 Reviewer Note

## Review Result

Reviewed. POS-0037 is suitable for human acceptance after final lint and scope
checks pass.

## Findings

- No blocking scope, safety, or evidence issues found.
- `palari prompt` is read-only: the implementation inspects ticket/repo state
  and prints prompts, but does not claim tickets, mutate lifecycle state,
  accept, commit, push, merge, deploy, or run agents.
- The generated `prompt ticket` output includes ticket status, next action,
  allowed paths, forbidden paths, verification commands, evidence expectations,
  and stop rules.
- The generated `prompt long-run` output addresses the observed user problem:
  it tells an agent to continue through meaningful unblocked Palari work while
  stopping at human acceptance, credentials, production authority, unclear
  scope, failing checks, or merge/push/deploy gates.
- Role guidance is useful without pretending Palari has implemented a process
  supervisor: Product Manager, UX/UI Lead, QA Lead, Release Lead,
  Backend/Platform Architect, Security/Governance Reviewer, and Integrator are
  included as simulated operating lenses.
- Tests cover no-active-ticket output, specific-ticket output, long-run output,
  help output, missing `--goal`, unknown subcommand failure, CLI module wiring,
  and golden/adoption inclusion.
- The implementation keeps Palari's existing Bash/module style and does not add
  dependencies.

## Verification Reviewed

Reviewed and reran:

- `tests/run-prompt.sh`
- `tests/run-cli-structure.sh`
- `tests/run-golden.sh`
- `shellcheck -x bin/palari lib/palari/prompt.bash tests/run-prompt.sh`
- `bash -n bin/palari lib/palari/*.bash tests/run-prompt.sh`
- `git diff --check`

Reviewed existing POS-0037 evidence:

- `reports/evidence/POS-0037/verification.log`
- `reports/evidence/POS-0037/junit.xml`
- `reports/evidence/POS-0037/manifest.json`
- `reports/evidence/POS-0037/palari.sarif`

## Required Changes

None.

## Residual Risk

This ticket intentionally does not implement the future `palari run --until
blocked` execution loop. It improves handoff quality immediately, but actual
agent spawning, queue scheduling, policy enforcement, and dashboard Founder
Inbox should remain separate scoped tickets.

## Recommendation

Accept POS-0037 if final Palari lint/scope checks pass.
