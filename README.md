# Palari Orchestrator

A small, portable orchestration spine for agent-led repository work.

This repository extracts the reusable workflow from Palari v05 without carrying
Palari product-specific application preferences into the core. The package is
Markdown-led and tool-checked: tickets define scope, work happens in per-ticket
worktrees, agents receive mission packets, reports preserve evidence, reviewers
inspect with fresh context, and human or authorized-reviewer acceptance remains
an explicit gate.

## What Is Included

- Ticket lifecycle: `open`, `claimed`, `blocked`, `needs-human`, `in-review`,
  `reopened`, `accepted`.
- Worktree-first execution with one branch/worktree per ticket.
- Agent packet generation for specialists, reviewers, product-feel reviewers,
  and mediators.
- Allowed and forbidden path scope checks against changed files.
- Specialist technical reports, reviewer notes, product-feel review templates,
  human-readable reports, and handoffs.
- Acceptance gate that requires `--by NAME` and refuses tickets that have not
  reached `in-review` or are missing required evidence.
- Config, schema, templates, contracts, skill guidance, and golden tests.
- Feature-contract skill scaffolding with `palari skill create`.

## Install In A Repo

Copy this repository's `bin/`, `scripts/`, `templates/`, `contracts/`,
`skills/`, `schemas/`, `AGENTS.md`, and `palari.config.yaml` into the target
repo, then run:

```bash
./bin/palari init
./bin/palari status
```

Optional shell alias:

```bash
alias palari="$PWD/bin/palari"
```

## Minimal Flow

```bash
palari ticket create APP-0001 "first scoped slice" \
  --stream app \
  --risk R1 \
  --allowed "src/**" \
  --allowed "tests/**" \
  --allowed "tickets/**" \
  --allowed "reports/**" \
  --verify "npm test" \
  --review

git add tickets palari.config.yaml AGENTS.md
git commit -m "Add APP-0001 ticket"

palari worktree APP-0001
palari packet APP-0001 specialist
palari skill create auth-workspaces --description "Preserve local auth and workspace isolation contracts."
```

The specialist works inside the printed worktree, edits only allowed paths,
runs verification, writes a technical report, and then:

```bash
palari scope-check APP-0001
palari ticket ready APP-0001
palari packet APP-0001 reviewer
```

The reviewer inspects with fresh context and writes a reviewer note. When the
ticket is ready:

```bash
palari lint APP-0001
palari accept APP-0001 --by founder
```

`accept` moves the ticket to `tickets/closed/` and records the acceptor. It does
not merge, push, deploy, or bless missing evidence.

## Portable Versus Palari-Specific

Portable core:

- role authority boundaries
- ticket lifecycle
- risk and report gates
- packet-first execution
- worktree isolation
- path scope checks
- fresh-context review
- optional product-feel review for rendered UI/copy/workflow
- human or authorized-reviewer acceptance

Palari-specific adapters should live outside the core:

- product vocabulary and visual taste
- app-specific routes, screenshots, fixtures, and browser flows
- founder names, private workbench assumptions, outreach material, and live
  connector behavior
- project-specific danger zones beyond the configurable defaults

## Commands

```bash
palari init
palari status
palari tickets
palari ticket create ID TITLE --allowed "path/**" --verify "check"
palari ticket claim ID
palari ticket ready ID
palari worktree ID
palari packet ID specialist
palari packet ID reviewer
palari packet ID product-feel-reviewer
palari skill create NAME --description "When to use this feature contract."
palari lint [ID]
palari report-lint [ID]
palari scope-check [ID]
palari accept ID --by NAME
```

## Tests

```bash
tests/run-golden.sh
```

The golden test creates a temporary repo, initializes the orchestrator, creates a
ticket, prepares a ticket worktree, checks packet output, simulates specialist
and review evidence, runs scope/lint, and exercises the acceptance gate.
