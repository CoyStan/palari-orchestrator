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
