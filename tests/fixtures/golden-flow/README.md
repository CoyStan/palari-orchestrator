# Golden Flow Fixture

The executable fixture lives in `tests/run-golden.sh`.

It creates a temporary repository, initializes Palari Orchestration, creates and
claims a ticket, prepares the ticket worktree, generates a packet, edits only
allowed paths, writes reports, runs scope/lint checks, and exercises the named
acceptance gate.
