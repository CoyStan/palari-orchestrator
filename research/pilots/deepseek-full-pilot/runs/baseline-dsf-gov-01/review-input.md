# DSF-GOV-01 Review Input

## Slot

- Slot: DSF-GOV-01
- Condition: Baseline
- Wave ticket: POS-0030
- Task title: Make report-lint missing-heading output more actionable
- Model: DeepSeek `deepseek/deepseek-v4-flash` through opencode
- Starting commit: `c5b9549` execution baseline; POS-0026 frozen baseline was
  `475b0d0`
- Worktree or branch:
  `/home/quetza/palari-pilot-workspaces/deepseek-full-baseline-dsf-gov-01`,
  detached at execution baseline
- Ticket integration worktree:
  `/home/quetza/palari-orchestrator-worktrees/POS-0030`,
  `ticket/POS-0030`

## Evidence

- Prompt: `prompt.md`
- Command: `command.txt`
- Stdout: `stdout.jsonl`, `stdout.txt`
- Stderr: `stderr.txt`
- Raw model diff: `diff.patch`
- Integrated ticket diff: `integration-diff.patch`
- Checks: `checks.md`
- Timing: `timing.md`

## Result

- Start timestamp: `2026-06-09T17:09:05Z`
- End timestamp: `2026-06-09T17:11:29Z`
- Exit code: `0`
- Changed files:
  - `lib/palari/agents_review_scope.bash`
  - `tests/run-agent-wrapper.sh`
- Objective checks: passed
- Missing evidence: no reviewer note yet

## Reviewer Notes

This is a Baseline-agent run. The prompt did not include Palari claim,
scope-check, CI, evidence-bundle, reviewer-packet, or lifecycle-transition
instructions. It did include general forbidden operations for safety.

The raw model diff improved the missing-heading diagnostic and added a
regression test. During ticket integration, an em dash in the diagnostic string
was normalized to ASCII punctuation while preserving the message meaning. Score
the raw diff and the integrated diff separately if that operator intervention
matters for POS-0032.
