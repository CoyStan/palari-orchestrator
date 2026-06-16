# POS-0098 Human Report

## Why This Mattered

The first POS-0098 attempt had the right instinct but the wrong base. It told
future agents to continue from `ticket/POS-0097`, but that stack has now merged
to `main` and the old local worktree was cleaned up. Leaving that guidance
around would make a fresh or compacted agent start from stale instructions.

## What Changed

- Added a current-main dogfooding workflow note.
- Recorded that new Palari Orchestrator work should start from clean synced
  `main` unless a human explicitly chooses another branch.
- Recorded that `ticket/POS-0097` is historical after the merge, not the
  current base.
- Recorded what a fresh agent should run after context compaction.
- Recorded the current ticket loop: create, claim, isolate, refresh evidence,
  review, accept, then commit/push/merge only when explicitly asked.
- Updated `palari prompt long-run` so fresh agents see the state-map and
  dry-run orientation steps in generated prompts.
- Updated the prompt smoke test.

## What I Should Know

- This does not accept, merge, push, or deploy anything.
- This does not change Palari acceptance rules, broker behavior, policy
  behavior, human quorum behavior, secrets, dependencies, runtime state, or
  external side effects.
- This does not delete remote branches or pilot workspaces.
- The old stale POS-0098 branch was preserved locally as
  `stale/POS-0098-pre-main`; the useful idea was reimplemented on fresh main.

## What To Check

- `docs/autonomy/dogfooding-workflow.md`
- `STATE.md`
- `lib/palari/prompt.bash`
- `tests/run-prompt.sh`
- `./bin/palari status --next`

## Recommended Next Move

Run verification and fresh-context review. If the reviewer agrees, POS-0098 can
move to founder acceptance later; do not self-accept.

## Founder Acceptance

- Accepted by founder on 2026-06-16 after accept-ready fresh-context review.
