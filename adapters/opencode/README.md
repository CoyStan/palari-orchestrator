# Palari opencode Adapter

This adapter keeps opencode as the coding executor and Palari as the governance
layer.

```bash
palari agent run TICKET-ID --executor opencode
```

The command:

- prepares the ticket worktree
- generates a specialist packet
- attaches that packet to `opencode run`
- stores opencode stdout, stderr, command details, exit code, and session export
  under `reports/evidence/TICKET-ID/executor/opencode/`
- runs Palari `scope-check` and `ci` after execution

It does not move the ticket to `in-review`, accept work, merge, push, deploy, or
replace a reviewer.

Tickets that use this wrapper should allow `reports/**`; Palari writes the
packet and executor evidence there before running scope and CI gates.

## Dry Run

Use `--dry-run` to prove the command contract without requiring opencode
credentials:

```bash
palari agent run TICKET-ID --executor opencode --dry-run
```

## Permission Boundary

The wrapper passes an opencode config that denies lifecycle and repository
authority commands:

- `palari *`
- `./bin/palari *`
- `bin/palari *`
- `git commit*`
- `git push*`
- `rm *`

The executor may edit scoped files. Palari still decides whether the result is
admissible through scope, evidence, review, and acceptance gates.

## Local Sandboxes

`palari sandbox create TICKET-ID` creates a disposable local repo copy outside
the canonical checkout under the configured worktree base. It is useful for
testing executor behavior without dirtying the source checkout.

The first opencode wrapper runs in the ticket worktree so the existing packet,
scope, and evidence commands remain the source of truth. Container or remote VM
sandboxing should be added only as a later adapter when the local contract is
stable.
