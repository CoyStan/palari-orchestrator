# Palari Console

Palari Console is an optional local web dashboard for Palari Orchestrator. It is
the easiest way for a founder, operator, or reviewer to understand what agents
are doing without reading every Markdown file by hand.

It is intentionally an adapter:

- the repository remains the source of truth
- dashboard state comes from `palari snapshot --json`
- commands are shown as copyable CLI actions
- acceptance authority stays in `palari accept`
- no database, package manager, or frontend build step is required
- read-only proof surface; does not accept, merge, push, or mutate critical lifecycle state

## Run

For a first look with sample data:

```bash
./bin/palari demo
./bin/palari web
```

For an existing Palari repo:

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

The server is a local stdlib viewer. It refuses non-loopback hosts unless
`--unsafe-bind` is set and is not a production web service.

## What It Shows

- operator queue with the next allowed action
- split queue/review workbench where selecting a ticket updates the proof surface
- searchable ticket queue by ticket, owner, role, path, and artifact
- selected-ticket review focus with readiness, lifecycle, scope, and artifacts
- lifecycle ticket board with owners, roles, and progress
- active role authority and delegation summary
- claim lease and heartbeat state
- path-scope overlap findings
- CI evidence bundle presence
- human decision and acceptance surface
- GitHub workflow/ruleset/attestation signals
- Palari and git status output
- copyable next-step commands
- light/dark operator theme toggle

For non-technical operators, the console should read as a control room:

| Operator question | Console answer |
| --- | --- |
| What work is active? | Queue rows group tickets by status, risk, priority, and stream; search narrows the view without hiding the source-of-truth ticket. |
| Who is responsible? | Role and claim fields show the delegated role, claimant, and heartbeat. |
| Is there proof? | Evidence, report, readiness, and artifact views show whether logs, JUnit, SARIF, manifests, and reviewer notes exist. |
| What needs me? | Human-gate surfaces call out `needs-human`, missing evidence, stale claims, and acceptance readiness. |
| What do I do next? | Command chips copy the next Palari action without granting browser-side authority. |
| Why did a panel move? | The first screen is now a queue plus selected-ticket review surface; roles, evidence, scope, human gates, and repo status are supporting proof below it. |

## Design Notes

The console borrows product principles from modern operational tools:

- split queue/review workbench instead of section-jump navigation
- accessible tables for ticket ledgers
- search-first queue filtering and selected-ticket review focus
- readiness grids and lifecycle timelines for quick decision scans
- row-based operational surfaces instead of heavy card stacks
- evidence-first and human-decision-first workflow surfaces
- plain-language status labels for non-technical operators
- reduced-motion support

The visual layer is deliberately self-contained so adopters can replace it
without touching the Palari core.

## Professional Rubric

Run the dashboard rubric check before changing the console:

```bash
tests/run-dashboard-rubric.sh
```

The check guards the baseline product standard: clear purpose, app-shell
structure, accessible refresh/status behavior, visible focus, semantic health
states, action-linked warnings, missing-evidence visibility, responsive reflow,
reduced-motion support, and lightweight adapter performance.
