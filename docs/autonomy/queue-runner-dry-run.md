# Queue Runner Dry-Run Specification

## Purpose

`palari run --dry-run --until blocked` should answer one question before any
agent is allowed to work:

What would Palari do next if it were asked to keep working until a real human
gate blocks progress?

Dry-run mode is intentionally read-only. It plans the queue; it does not claim
tickets, create worktrees, spawn agents, accept work, commit, push, merge,
deploy, or mutate lifecycle state.

## Inputs

- Repository root.
- `palari snapshot --json`.
- Active tickets and their `next_action` values.
- Authority profile.
- Optional goal text.
- Optional maximum ticket count or time budget.
- Optional starting ticket.

## Output

Dry-run output should be a structured run plan with:

- selected ticket id and title,
- reason the ticket was selected,
- role lens to use,
- safe command that would be copied or run in supervised mode,
- expected checks and evidence,
- stop reason if the runner must not proceed,
- tickets skipped and why,
- human decisions required before further progress.

The output should be both human-readable and machine-readable. A future command
may support:

```bash
./bin/palari run --dry-run --until blocked
./bin/palari run --dry-run --until blocked --goal "Build the Play Store MVP"
./bin/palari run --dry-run --until blocked --json
```

## Ticket Selection

The dry-run planner should prioritize:

1. Human gates first, but only as stop items.
2. Blocked/evidence issues that can be repaired without new authority.
3. Open or reopened tickets that can be claimed and isolated.
4. Claimed tickets with active leases and missing evidence.
5. Review tickets needing reviewer notes.

It should skip tickets when:

- scope overlaps another active ticket,
- claim lease ownership is unclear,
- allowed paths are missing or too broad for the stated goal,
- verification commands require credentials or production access,
- next action is accept, merge, push, deploy, or publication,
- the ticket is outside the current goal.

## Stop Reasons

Dry-run must stop or mark blocked when the next safe action requires:

- human acceptance,
- product/founder decision,
- credentials, secrets, signing keys, paid services, or external accounts,
- production access or deploy,
- commit, push, merge, release publication, or destructive git commands,
- unclear authority, scope, ownership, or risk,
- failed checks that cannot be fixed inside ticket scope,
- no meaningful unblocked work remaining.

## Role Lenses

The planner may recommend role lenses, but it must not grant authority. Useful
lenses include:

- Product Lead for prioritization and ticket shaping.
- Design Lead for operator-facing UI polish.
- QA Lead for regression and evidence checks.
- Release Lead for CI, packaging, and external blockers.
- Autonomy Coordinator for queue routing and stop decisions.
- Specialist for scoped implementation.
- Reviewer for fresh-context review.

## Supervised Mode Boundary

A future supervised runner may execute a selected plan only after dry-run mode
is proven useful. Supervised mode must still:

- claim and isolate one ticket at a time,
- keep browser/dashboard actions copy-only unless explicitly approved,
- run checks and `palari ci`,
- write reports and evidence,
- move tickets to review only after evidence passes,
- stop before accept, merge, push, deploy, credentials, or production access.

## Non-Goals

The dry-run planner must not:

- spawn agents,
- accept tickets,
- merge branches,
- push to remotes,
- deploy,
- create credentials,
- mutate production,
- bypass ForgeGate or evidence checks,
- hide failed or skipped tickets.

## First Implementation Slice

The safest first code slice should only print the dry-run plan. It can reuse
the same next-action and inbox categories used by the operator console. Once the
plan is trusted, later tickets can add supervised execution behind explicit
flags and stronger evidence capture.
