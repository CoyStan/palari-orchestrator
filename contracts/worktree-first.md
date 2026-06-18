# Worktree-First Contract

Meaningful edits should happen in a ticket branch and ticket worktree.

The canonical repository stays clean and acts as the accepted baseline. A ticket
worktree gives each agent a scoped execution surface and keeps unrelated user or
agent work out of the lane.

Minimum gate:

```bash
git status --short --branch
palari status
palari worktree TICKET-ID
palari packet TICKET-ID specialist
```

Stop if:

- the canonical repo is dirty before worktree creation
- the ticket branch does not contain the target branch
- the worktree path exists but is not a git worktree
- the worktree is on the wrong branch
- the worktree is dirty before packet generation

Before moving a ticket to review, run the closeout readiness check from the
ticket worktree:

```bash
palari worktree closeout TICKET-ID
```

The closeout check is read-only. It reports the ticket ID, ticket branch, target
branch, current worktree path, branch-diff changed path count, scope status,
evidence status, report status, and the exact next command. It fails closed when
run from the canonical checkout or wrong branch, when the worktree is dirty, when
scope-check fails, or when evidence or required reports are missing.

Do not manually copy reports or evidence from a worktree into another checkout.
Use the ticket worktree as the source of truth, refresh evidence there, run
`palari worktree closeout TICKET-ID`, then move the ticket to review only when
the closeout state is ready.
