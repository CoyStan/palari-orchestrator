# POS-0037 Technical Report

## Summary

POS-0037 adds `palari prompt`, a read-only prompt generator for handing Palari
work to fresh agents. The command helps founders/operators create safer,
longer-running prompts without manually remembering ticket lifecycle rules,
roles, evidence requirements, and stopping conditions.

This is a prompt-generation slice only. It does not spawn agents, accept work,
merge, push, deploy, or weaken existing authority gates.

## Changes

- Added `lib/palari/prompt.bash`.
- Added CLI wiring for `./bin/palari prompt`.
- Added adoption doctor coverage for the new prompt module.
- Added `tests/run-prompt.sh`.
- Updated CLI structure and golden tests to include the prompt module.
- Tightened POS-0037 ticket scope and completion contract.

## Files Changed

- `bin/palari`
- `lib/palari/prompt.bash`
- `lib/palari/init_adopt.bash`
- `tests/run-prompt.sh`
- `tests/run-cli-structure.sh`
- `tests/run-golden.sh`
- `tickets/open/POS-0037-prompt-generator-for-long-run-agent-work.md`
- `reports/POS-0037-technical-report.md`

## User-Facing Commands

- `./bin/palari prompt next`
- `./bin/palari prompt ticket TICKET-ID`
- `./bin/palari prompt long-run --goal "..." [--ticket TICKET-ID]`

## Behavior

`prompt next` prints a handoff prompt for the first active ticket, including the
actual ticket next action, scope, verification commands, evidence expectations,
and stop rules.

`prompt ticket TICKET-ID` prints a focused prompt for a specific ticket.

`prompt long-run --goal "..."` prints a longer operating prompt with simulated
roles, an autonomous execution loop, and explicit stopping rules so agents can
continue through safe unblocked work without bypassing human gates.

## Safety Boundaries

- The command is read-only.
- Generated prompts explicitly forbid accept, commit, push, merge, deploy, and
  destructive actions unless the human explicitly asks.
- Generated prompts preserve human acceptance as final authority.
- Generated prompts instruct agents to respect allowed/forbidden paths and
  stop when scope, risk, authority, credentials, or production access are
  unclear.

## Verification

Commands run during implementation:

- `bash -n bin/palari lib/palari/*.bash tests/run-prompt.sh tests/run-cli-structure.sh tests/run-golden.sh`
- `shellcheck -x bin/palari lib/palari/prompt.bash tests/run-prompt.sh`
- `tests/run-prompt.sh`
- `tests/run-cli-structure.sh`
- `git diff --check`
- `./bin/palari scope-check POS-0037`
- `tests/run-golden.sh`

## CI Evidence

Palari CI evidence is expected under:

- `reports/evidence/POS-0037/verification.log`
- `reports/evidence/POS-0037/junit.xml`
- `reports/evidence/POS-0037/manifest.json`
- `reports/evidence/POS-0037/palari.sarif`

## Risks / Follow-Ups

This is the right first step toward the broader autonomous queue-runner idea:
it gives the user a high-quality prompt immediately while keeping actual agent
execution, scheduling, dashboard inboxes, and policy automation for later
tickets.

Follow-up candidates:

- `palari run --until blocked` dry-run and then supervised execution mode.
- Founder Inbox dashboard surface for human decisions.
- Configurable role prompt templates and autonomy policies.
