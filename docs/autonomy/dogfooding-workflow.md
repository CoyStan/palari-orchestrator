# Dogfooding The Current Palari Workflow

Status: POS-0098 guidance for Palari Orchestrator work after POS-0097 merged
to main. This note is for agents and collaborators who need to continue the
repository without falling back to stale branch, worktree, or context-window
memory.

## Current Base

The current base is main. Start new Palari Orchestrator work from clean synced
`main` or `origin/main` unless a human explicitly names another branch.

`ticket/POS-0097` was the integrated review stack branch. It has now been
merged through the GitHub PR path, and the old POS-0097 local worktree was
removed during cleanup. Treat POS-0097 as historical context, not as the
starting point for new work.

Before editing, verify:

- `git status --short --branch` shows the expected branch.
- `./bin/palari status --next` reports the current gate.
- The ticket `target_branch` matches the intended base.
- Any worktree named in older reports still exists before following that path.

## First Reorientation After Context Compaction

Use this sequence after context compaction, after a long pause, or whenever
the branch/base relationship is unclear.

Run these commands before editing:

```bash
cd /home/quetza/palari-orchestrator
git status --short --branch
git branch --show-current
git fetch origin --prune
git status --short --branch
./bin/palari status --next
./bin/palari state
./bin/palari run --dry-run --until blocked
./bin/palari ticket audit
```

If you are already inside a ticket worktree, stay there long enough to inspect
it, then compare its ticket `target_branch` against the expected base. If the
worktree references a deleted or superseded branch, stop and report the
staleness before editing.

## Canonical Ticket Loop

Use Palari commands for lifecycle state. Do not hand-edit status fields or move
ticket files except through the accept gate.

1. Confirm the base and next gate:

   ```bash
   git status --short --branch
   ./bin/palari status --next
   ./bin/palari ticket audit
   ```

2. Create or route a scoped ticket with explicit paths and checks:

   ```bash
   ./bin/palari ticket create POS-XXXX "Small scoped title" \
     --goal GOAL-0200 \
     --target-branch main \
     --allowed "PATH/**" \
     --allowed "tickets/open/POS-XXXX-*" \
     --allowed "tickets/closed/POS-XXXX-*" \
     --allowed "reports/POS-XXXX-technical-report.md" \
     --allowed "reports/POS-XXXX-reviewer-note.md" \
     --allowed "reports/human/POS-XXXX-human-report.md" \
     --allowed "reports/evidence/POS-XXXX/**" \
     --verify "FOCUSED-CHECK" \
     --review
   ```

3. Claim and isolate before implementation:

   ```bash
   ./bin/palari ticket claim POS-XXXX AGENT-NAME
   ./bin/palari worktree POS-XXXX
   cd /home/quetza/palari-orchestrator-worktrees/POS-XXXX
   ./bin/palari packet POS-XXXX specialist
   ```

4. Implement only inside allowed paths, then refresh local evidence. For
   uncommitted work, omit `--base` so local modified and untracked paths are
   inspected:

   ```bash
   ./bin/palari scope-check POS-XXXX
   ./bin/palari lint POS-XXXX
   ./bin/palari report-lint POS-XXXX
   ./bin/palari ci POS-XXXX
   ./bin/palari evidence score POS-XXXX
   ```

   Use the base form after the ticket branch has commits or inside PR/merge
   checks:

   ```bash
   ./bin/palari scope-check POS-XXXX --base main
   ./bin/palari ci POS-XXXX --base main
   ```

5. Move ready work to review:

   ```bash
   ./bin/palari ticket ready POS-XXXX
   ./bin/palari packet POS-XXXX reviewer
   ```

6. Fresh-context review writes `reports/POS-XXXX-reviewer-note.md`, then reruns
   the relevant lint/scope/CI evidence. The implementer must not self-accept.

7. Human acceptance remains explicit:

   ```bash
   ./bin/palari accept POS-XXXX --by HUMAN-ADMIN
   ```

   Use `--co-by` only when the configured risk tier requires multiple distinct
   humans.

8. Commit, push, and merge only after the human explicitly asks. Stage only the
   accepted ticket artifacts and preserve unrelated dirty files.

## What Not To Do Manually

- Do not rely on memory of old root checkouts, deleted worktrees, old branches,
  aliases, or stale local scripts when `./bin/palari` has a current command.
- Do not manually mark tickets accepted, edit `accepted_by`, or move tickets to
  `tickets/closed`.
- Do not use the dashboard as an authority surface. It may show and copy
  commands, but acceptance, push, merge, deploy, and production actions remain
  explicit human-gated commands.
- Do not treat `palari run --dry-run` as an executor. It plans; it does not
  claim, edit, accept, commit, push, merge, deploy, or call services.
- Do not hide failed checks, stale evidence, skipped reviews, branch-base
  mismatches, or overlap acknowledgements.

## Current Answer To The Dogfood Questions

- Current Palari commands are the authority for new tickets, review evidence,
  acceptance, and status tracking.
- Older manual habits to avoid are hand-editing lifecycle fields, moving ticket
  files directly, accepting from memory, treating the dashboard as a mutating
  control surface, or continuing from the wrong checkout.
- `ticket/POS-0097` is no longer the current base. It was merged into main and
  its local worktree was removed.
- Future POS tickets should start from updated `main` or `origin/main` unless a
  human explicitly chooses another integration branch.
- After context compaction, run the reorientation commands above before
  editing.
- A fresh agent should first inspect branch, Palari next action, state map,
  dry-run plan, and ticket audit; then it should either continue the assigned
  ticket or ask for the human gate that `status --next` reports.
