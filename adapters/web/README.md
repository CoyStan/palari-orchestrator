# Palari Console

Palari Console is an optional local web dashboard for Palari Orchestrator.

It is intentionally an adapter:

- the repository remains the source of truth
- dashboard state comes from `palari snapshot --json`
- commands are shown as copyable CLI actions
- acceptance authority stays in `palari accept`
- no database, package manager, or frontend build step is required

## Run

```bash
./bin/palari web
```

Then open:

```text
http://127.0.0.1:8765
```

Options:

```bash
./bin/palari web --host 127.0.0.1 --port 8765
./bin/palari web --check
```

`--check` prints the same JSON produced by `palari snapshot --json`. It is
useful for tests, CI, and debugging adapter reads.

## What It Shows

- lifecycle ticket board
- claim lease and heartbeat state
- path-scope overlap findings
- CI evidence bundle presence
- GitHub workflow/ruleset/attestation signals
- Palari and git status output
- copyable next-step commands

## Design Notes

The console borrows product principles from modern developer tools:

- compact navigation and calm consistency
- fast-feeling transitions
- dense but scannable operational panels
- evidence-first workflow surfaces
- reduced-motion support

The visual layer is deliberately self-contained so adopters can replace it
without touching the Palari core.
