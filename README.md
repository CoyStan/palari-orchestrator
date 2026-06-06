<p align="center">
  <img src="assets/readme/palari-orchestrator-hero.png" alt="Abstract Palari Orchestrator workflow with tickets, worktrees, packets, scope checks, reviews, and acceptance gates." width="100%">
</p>

<h1 align="center">Palari Orchestrator</h1>

<p align="center">
  A portable operating layer for agent-led repository work: scoped tickets, isolated worktrees, mission packets, review evidence, and explicit human acceptance.
</p>

<p align="center">
  <img alt="workflow: worktree-first" src="https://img.shields.io/badge/workflow-worktree--first-12345C?style=flat-square">
  <img alt="scope checked" src="https://img.shields.io/badge/scope-checked-2B9968?style=flat-square">
  <img alt="fresh context review" src="https://img.shields.io/badge/review-fresh--context-5B4DFF?style=flat-square">
  <img alt="golden tests" src="https://img.shields.io/badge/tests-golden-F4B433?style=flat-square">
</p>

Palari Orchestrator turns an agent task from "please go change things" into a traceable workflow any repository can adopt. It is Markdown-led and tool-checked: tickets define the scope, agents work in per-ticket worktrees, packets tell each role what matters, reports preserve evidence, reviewers inspect from fresh context, and acceptance stays an explicit gate.

The core is deliberately portable. Palari product preferences, founder taste, app routes, private screenshots, and live-workbench assumptions belong in adapters or examples, not in the reusable orchestration package.

## The Flow

![Palari Orchestrator workflow](assets/readme/orchestration-flow.svg)

The useful unit is a ticket. Every ticket has allowed paths, verification commands, lifecycle state, generated role packets, and required evidence. The result is simple enough to adopt in a small repo, but structured enough to keep multi-agent work from becoming folklore.

## Included In V1

- Ticket lifecycle: `open`, `claimed`, `blocked`, `needs-human`, `in-review`, `reopened`, `accepted`.
- Worktree-first execution with one branch and one worktree per ticket.
- Agent packet generation for specialists, reviewers, product-feel reviewers, and mediators.
- Allowed and forbidden path checks against changed files.
- Specialist reports, reviewer notes, product-feel review templates, human reports, and handoffs.
- Fresh-context review and human/founder acceptance gates.
- Config schema, templates, contracts, orchestrator skill guidance, and golden fixtures.
- Feature-contract skill scaffolding with `palari skill create`.

## Quick Start

```bash
git clone https://github.com/CoyStan/palari-orchestrator.git
cd palari-orchestrator
./bin/palari init
./bin/palari status
tests/run-golden.sh
```

To adopt the orchestrator in another repository, copy the portable package files into that repo:

```bash
cp -R bin scripts templates contracts skills schemas AGENTS.md palari.config.yaml /path/to/repo/
cd /path/to/repo
./bin/palari init
./bin/palari status
```

Optional shell alias:

```bash
alias palari="$PWD/bin/palari"
```

## Minimal Ticket

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

The specialist works inside the printed worktree, edits only allowed paths, runs verification, and writes a technical report.

```bash
palari scope-check APP-0001
palari ticket ready APP-0001
palari packet APP-0001 reviewer
```

The reviewer inspects with fresh context and writes a reviewer note. When the ticket is ready:

```bash
palari lint APP-0001
palari accept APP-0001 --by founder
```

`accept` moves the ticket to `tickets/closed/` and records the acceptor. It does not merge, push, deploy, or bless missing evidence.

## Command Surface

| Command | Purpose |
| --- | --- |
| `palari init` | Create the ticket, report, and handoff directories expected by the workflow. |
| `palari status` | Show current tickets and workflow health at a glance. |
| `palari tickets` | List active tickets by lifecycle state. |
| `palari ticket create ID TITLE` | Create a scoped ticket with allowed paths, risk, checks, and review requirements. |
| `palari ticket claim ID` | Mark a ticket as claimed before implementation work starts. |
| `palari ticket ready ID` | Move a ticket into review once implementation evidence exists. |
| `palari worktree ID` | Create or locate the ticket-specific git worktree. |
| `palari packet ID ROLE` | Generate the mission packet for a specialist, reviewer, product-feel reviewer, or mediator. |
| `palari scope-check [ID]` | Compare changed files against allowed and forbidden path rules. |
| `palari lint [ID]` | Validate ticket state, evidence, config, templates, and required reports. |
| `palari report-lint [ID]` | Validate specialist and reviewer report structure. |
| `palari skill create NAME` | Scaffold a portable feature-contract skill. |
| `palari accept ID --by NAME` | Close the ticket only after the acceptance gate is satisfied. |

## Portable Core

Keep these concepts in the reusable package:

- role authority boundaries
- ticket lifecycle
- risk and report gates
- packet-first execution
- worktree isolation
- path scope checks
- fresh-context review
- optional product-feel review for rendered UI, copy, and workflow
- human or authorized-reviewer acceptance

Keep these concepts in repo-specific adapters or examples:

- product vocabulary and visual taste
- app-specific routes, screenshots, fixtures, and browser flows
- founder names, private workbench assumptions, outreach material, and live connector behavior
- project-specific danger zones beyond the configurable defaults

## Repository Map

```text
AGENTS.md                         Agent operating template for adopters
bin/palari                        Main CLI entrypoint
palari.config.yaml                Example config for lifecycle, paths, roles, and gates
schemas/palari.config.schema.json Config schema
templates/                        Ticket, packet, report, handoff, and skill templates
contracts/                        Portable workflow contracts
skills/orchestrator/SKILL.md      Orchestrator usage guidance
tests/golden/                     Fixtures that prove the flow works
```

## Tests

```bash
tests/run-golden.sh
```

The golden test creates a temporary repository, initializes the orchestrator, creates a ticket, prepares a worktree, checks packet output, simulates specialist and review evidence, runs scope/lint checks, and exercises the acceptance gate.
