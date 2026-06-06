<p align="center">
  <img src="assets/readme/palari-orchestrator-hero.png" alt="Abstract Palari Orchestrator workflow with tickets, worktrees, packets, scope checks, reviews, and acceptance gates." width="100%">
</p>

<h1 align="center">Palari Orchestrator</h1>

<p align="center">
  A small repo-native control layer for agent-led coding: tickets define scope, worktrees isolate execution, CI records evidence, and review plus acceptance closes the loop.
</p>

<p align="center">
  <img alt="workflow: worktree-first" src="https://img.shields.io/badge/workflow-worktree--first-12345C?style=flat-square">
  <img alt="scope checked" src="https://img.shields.io/badge/scope-checked-2B9968?style=flat-square">
  <img alt="fresh context review" src="https://img.shields.io/badge/review-fresh--context-5B4DFF?style=flat-square">
  <img alt="golden tests" src="https://img.shields.io/badge/tests-golden-F4B433?style=flat-square">
</p>

Palari Orchestrator turns an agent task from "please go change things" into a set of small primitives any repository can adopt. A ticket defines allowed paths and verification. A worktree isolates execution. A scope check blocks drift. CI records evidence. Review and accept close the loop.

The core is deliberately portable. Palari product preferences, founder taste, app routes, private screenshots, and live-workbench assumptions belong in adapters or examples, not in the reusable orchestration package.

## The Flow

![Palari Orchestrator workflow](assets/readme/orchestration-flow.svg)

The useful unit is a ticket. Every ticket has allowed paths, verification checks, lifecycle state, generated role packets, and required evidence. Ceremony scales with risk: R0/R1 tickets stay small, while R2+ work can carry the fuller completion contract and stricter report gates.

## Included In V1

- Ticket lifecycle: `open`, `claimed`, `blocked`, `needs-human`, `in-review`, `reopened`, `accepted`.
- Worktree-first execution with one branch and one worktree per ticket.
- Agent packet generation for specialists, reviewers, acceptors/humans, and custom review profiles.
- Allowed and forbidden path checks against changed files.
- Specialist reports, reviewer notes, custom required reports, human reports, and handoffs.
- Fresh-context review and human/founder acceptance gates.
- Generated GitHub CI/ruleset and local hook adapters for structural gates.
- CI evidence bundles with logs, JUnit XML, and SARIF output.
- Claim leases, heartbeat renewal, git claim refs, and path-overlap checks.
- Optional local Palari Console web dashboard backed by `palari snapshot --json`.
- Config schema, templates, contracts, adapter guidance, orchestrator skill guidance, and golden fixtures.
- Optional feature-contract skill scaffolding with `palari skill create`.

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
cp -R bin scripts templates contracts skills schemas adapters AGENTS.md palari.config.yaml /path/to/repo/
cd /path/to/repo
./bin/palari init
./bin/palari status
```

To also install optional governance adapters:

```bash
./bin/palari init --ci --hooks
```

This generates a GitHub Actions governance workflow, an importable ruleset
template, and a `lefthook.yml` for local advisory checks. The workflow alone
does not protect merges until the ruleset is installed:

```bash
palari github ruleset-command --repo OWNER/REPO
palari github install-ruleset --repo OWNER/REPO
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
| `palari snapshot --json` | Print the repo-native JSON state model used by adapters. |
| `palari tickets` | List active tickets by lifecycle state. |
| `palari ticket create ID TITLE` | Create a scoped ticket with allowed paths, risk, checks, and review requirements. |
| `palari ticket claim ID` | Mark a ticket as claimed before implementation work starts. |
| `palari ticket heartbeat ID` | Renew the ticket claim lease. |
| `palari ticket ready ID` | Move a ticket into review once implementation evidence exists. |
| `palari worktree ID` | Create or locate the ticket-specific git worktree. |
| `palari packet ID ROLE` | Generate the mission packet for a specialist, reviewer, acceptor/human, or custom review profile. |
| `palari ci ID --base REF` | Run scope/lint/report gates and write evidence artifacts. Fails closed without a ticket. |
| `palari ci --repo-only` | Run explicit non-merge-gate repository lint evidence. |
| `palari scope-check [ID]` | Compare changed files against allowed and forbidden path rules. |
| `palari scope-overlaps [ID]` | Detect overlapping active ticket write scopes. |
| `palari lint [ID]` | Validate ticket state, evidence, config, templates, and required reports. |
| `palari report-lint [ID]` | Validate specialist and reviewer report structure. |
| `palari skill create NAME` | Scaffold an optional feature-contract skill adapter. |
| `palari github ruleset-command` | Print the `gh api` command that activates required checks. |
| `palari github install-ruleset` | Install the GitHub ruleset through `gh api`. |
| `palari mcp manifest` | Print optional MCP tool metadata for wrapper adapters. |
| `palari web` | Run the optional local Palari Console dashboard. |
| `palari accept ID --by NAME` | Close the ticket only after the acceptance gate is satisfied. |

## Governance Integrations

Palari's core remains Bash, Markdown, and git. The heavier governance features
ship as adapters:

- GitHub Actions: `palari init --ci` writes `.github/workflows/palari.yml`.
- GitHub rulesets: `palari init --ci` writes `.github/palari-required-checks.ruleset.json`.
- Local hooks: `palari init --hooks` writes `lefthook.yml` for fast advisory checks.
- Trusted evidence: `palari ci` writes `reports/evidence/<ticket>/verification.log`, `junit.xml`, and `palari.sarif`; the GitHub adapter uploads and attests `palari-evidence.tgz`.
- Concurrency: `ticket claim` records lease metadata, `ticket heartbeat` renews it, and `scope-overlaps` blocks path-scope collisions by default.
- MCP: `palari mcp manifest` exposes a thin command manifest for optional MCP wrappers.
- Web console: `palari web` starts a local dashboard that renders `palari snapshot --json` and shows tickets, claims, evidence, scope overlaps, workflow health, and copyable next commands.

## Portable Core

Keep these concepts in the reusable package:

- role authority boundaries
- ticket lifecycle
- risk and report gates
- packet-first execution
- worktree isolation
- path scope checks
- fresh-context review
- custom required reports such as `product-feel` for rendered UI, copy, and workflow
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
adapters/                         Optional GitHub, hooks, MCP, and web integration templates
skills/orchestrator/SKILL.md      Orchestrator usage guidance
tests/golden/                     Fixtures that prove the flow works
```

## Tests

```bash
tests/run-golden.sh
```

The golden test creates a temporary repository, initializes the orchestrator, creates a ticket, prepares a worktree, checks packet output, simulates specialist and review evidence, runs scope/lint checks, and exercises the acceptance gate.
