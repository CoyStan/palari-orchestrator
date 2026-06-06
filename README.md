<p align="center">
  <img src="assets/readme/palari-orchestrator-hero-general.png" alt="A calm operator workspace showing an AI coding workflow moving through ticket intake, isolated work, evidence, review, and human acceptance." width="100%">
</p>

<h1 align="center">Palari Orchestrator</h1>

<p align="center">
  A small safety layer for letting AI coding agents work in your repo without losing the thread, the scope, or the final human say.
</p>

<p align="center">
  <img alt="workflow: worktree-first" src="https://img.shields.io/badge/workflow-worktree--first-12345C?style=flat-square">
  <img alt="scope checked" src="https://img.shields.io/badge/scope-checked-2B9968?style=flat-square">
  <img alt="fresh context review" src="https://img.shields.io/badge/review-fresh--context-5B4DFF?style=flat-square">
  <img alt="golden tests" src="https://img.shields.io/badge/tests-golden-F4B433?style=flat-square">
</p>

<p align="center">
  <a href="#why-palari">Why Palari</a> ·
  <a href="#how-it-works">How it works</a> ·
  <a href="#quick-start">Quick start</a> ·
  <a href="#optional-console">Console</a> ·
  <a href="#command-reference">Commands</a>
</p>

Palari turns "let the agent handle it" into a visible, reviewable workflow:

```text
ticket -> worktree -> packet -> scope-check -> ci evidence -> review -> accept
```

It is built for founders, operators, product people, and small teams who want
AI-assisted coding to feel controlled instead of mysterious. The repo stays the
source of truth. Agents get clear boundaries. Humans keep acceptance authority.

## Why Palari

| Without a control layer | With Palari |
| --- | --- |
| The agent remembers the task in chat. | The ticket lives in the repo. |
| Scope drift is noticed late. | Allowed and forbidden paths are checked. |
| Work happens in the main checkout. | Work starts in a ticket worktree. |
| Review depends on summaries. | Review gets packets, reports, and CI evidence. |
| "Done" can be vague. | Acceptance is explicit and recorded. |

Palari is not a generic multi-agent platform. It is a few repo-native primitives
that make agent-led coding easier to delegate, inspect, and stop.

## How It Works

![Palari Orchestrator workflow](assets/readme/orchestration-flow.svg)

1. Create a ticket with the goal, allowed paths, forbidden paths, and checks.
2. Give the agent a clean worktree and a packet that says exactly what it can do.
3. Run scope checks and CI evidence before review.
4. Review with fresh context.
5. Accept only when the evidence, scope, and authority gates pass.

Ceremony scales with risk. Small R0/R1 tasks stay short. R2+ work gets stronger
review and evidence gates. R3/R4 work requires human confirmation.

## What You Get

| Primitive | What it protects |
| --- | --- |
| Scoped tickets | The agent knows where it may work and what must be verified. |
| Worktree-first execution | Each ticket gets isolated from the main checkout. |
| Agent packets | Specialists, reviewers, and acceptors get the right context. |
| Scope checks | Changed files are compared against allowed and forbidden paths. |
| CI evidence | Logs, JUnit, SARIF, and a manifest are written for the ticket. |
| Human acceptance | `palari accept` refuses missing gates and records who accepted. |

## Quick Start

Try Palari in this repo:

```bash
git clone https://github.com/CoyStan/palari-orchestrator.git
cd palari-orchestrator
./bin/palari init
./bin/palari status
tests/run-golden.sh
```

Adopt it in another repo:

```bash
cp -R bin scripts templates contracts skills schemas adapters examples AGENTS.md palari.config.yaml /path/to/repo/
cd /path/to/repo
./bin/palari init
./bin/palari status
```

Add optional GitHub and local hook adapters:

```bash
./bin/palari init --ci --hooks
```

The workflow file alone does not protect merges. Install the ruleset when you
want GitHub to require the Palari check:

```bash
palari github install-ruleset --repo OWNER/REPO
```

## First Ticket

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
```

Then hand the agent its workspace and mission:

```bash
palari worktree APP-0001
palari packet APP-0001 specialist
```

Before acceptance:

```bash
palari scope-check APP-0001
palari ci APP-0001 --base main
palari ticket ready APP-0001
palari packet APP-0001 reviewer
palari accept APP-0001 --by founder
```

`accept` moves the ticket to `tickets/closed/`. It does not merge, push, deploy,
or bless missing evidence.

## Optional Console

The local console is a read-only view over `palari snapshot --json`. It helps
non-programmers see tickets, evidence, scope health, and the next command
without turning Palari into a web app.

```bash
palari web
```

![Palari Console dashboard showing ticket health, evidence status, scope partitions, and copyable commands.](assets/readme/palari-console-preview.png)

## Design Principles

- **Repo is law:** tickets, reports, evidence, and config live in the repository.
- **Small core:** Bash, Markdown, and git remain enough for the portable loop.
- **Adapters stay optional:** GitHub, MCP, hooks, console, and skills do not own acceptance.
- **Humans keep authority:** review can recommend; acceptance is explicit.
- **No product lock-in:** product-feel and app-specific preferences are examples or adapters.

## Command Reference

<details>
<summary>Core, adapter, and experimental commands</summary>

### Core Commands

| Command | Purpose |
| --- | --- |
| `palari init` | Create the ticket, report, and handoff directories expected by the workflow. |
| `palari status` | Show current tickets and workflow health at a glance. |
| `palari snapshot --json` | Print the repo-native JSON state model used by adapters. |
| `palari ticket create ID TITLE` | Create a scoped ticket with allowed paths, risk, checks, and review requirements. |
| `palari ticket claim ID` | Mark a ticket as claimed before implementation work starts. |
| `palari ticket heartbeat ID` | Renew the ticket claim lease. |
| `palari ticket ready ID` | Move a ticket into review once implementation evidence exists. |
| `palari ticket block ID` | Mark scoped work blocked. |
| `palari ticket needs-human ID` | Mark work that needs human authority or product judgment. |
| `palari ticket reopen ID` | Move an in-review ticket back to implementation. |
| `palari worktree ID` | Create or locate the ticket-specific git worktree. |
| `palari packet ID ROLE` | Generate the mission packet for a specialist, reviewer, acceptor/human, or custom review profile. |
| `palari ci ID --base REF` | Run scope/lint/report gates and write evidence artifacts. Fails closed without a ticket. |
| `palari ci --repo-only` | Run explicit non-merge-gate repository lint evidence. |
| `palari scope-check [ID]` | Compare changed files against allowed and forbidden path rules. |
| `palari scope-overlaps [ID]` | Detect overlapping active ticket write scopes. |
| `palari lint [ID]` | Validate ticket state and required reports. |
| `palari report-lint [ID]` | Validate specialist and reviewer report structure. |
| `palari accept ID --by NAME` | Close the ticket only after the acceptance gate is satisfied. |

### Adapter Commands

| Command | Purpose |
| --- | --- |
| `palari github ruleset-command` | Print the `gh api` command that activates required checks. |
| `palari github install-ruleset` | Install the GitHub ruleset through `gh api`. |
| `palari mcp manifest` | Print optional MCP tool metadata for wrapper adapters. |
| `palari web` | Run the optional local Palari Console dashboard. |

### Experimental Commands

| Command | Purpose |
| --- | --- |
| `palari skill create NAME` | Scaffold an optional feature-contract skill adapter. |

</details>

## Governance Details

Palari's core remains Bash, Markdown, and git. The heavier governance features
ship as adapters:

- GitHub Actions: `palari init --ci` writes `.github/workflows/palari.yml`.
- GitHub rulesets: `palari init --ci` writes `.github/palari-required-checks.ruleset.json`.
- Local hooks: `palari init --hooks` writes `lefthook.yml` for fast advisory checks.
- Trusted evidence: `palari ci` writes `reports/evidence/<ticket>/verification.log`, `junit.xml`, `palari.sarif`, and `manifest.json`; the GitHub adapter uploads and attests `palari-evidence.tgz`.
- Concurrency: `ticket claim` records lease metadata, `ticket heartbeat` renews it, and `scope-overlaps` blocks path-scope collisions by default.
- MCP: `palari mcp manifest` exposes a thin command manifest for optional MCP wrappers.
- Web console: `palari web` starts a local dashboard that renders `palari snapshot --json` and shows tickets, claims, evidence, scope overlaps, workflow health, and copyable next commands.

## Portable Core Boundary

Keep these concepts in the reusable package:

- role authority boundaries
- ticket lifecycle
- risk and report gates
- packet-first execution
- worktree isolation
- path scope checks
- fresh-context review
- custom required reports named by the adopting repository
- human or authorized-reviewer acceptance

Keep these concepts in repo-specific adapters or examples:

- product vocabulary and visual taste
- app-specific routes, screenshots, fixtures, and browser flows
- founder names, private workbench assumptions, outreach material, and live connector behavior
- project-specific danger zones beyond the configurable defaults

## Repository Map

<details>
<summary>Files and folders</summary>

```text
AGENTS.md                         Agent operating template for adopters
bin/palari                        Main CLI entrypoint
palari.config.yaml                Example config for lifecycle, paths, roles, and gates
schemas/palari.config.schema.json Config schema
templates/                        Human report, handoff, and feature-contract templates
examples/                         Optional adopter examples such as product-feel review
contracts/                        Portable workflow contracts
adapters/                         Optional GitHub, hooks, MCP, and web integration templates
skills/orchestrator/SKILL.md      Orchestrator usage guidance
tests/golden/                     Fixtures that prove the flow works
```

</details>

## Confidence Checks

```bash
tests/run-golden.sh
```

The golden test creates a temporary repository, initializes the orchestrator, creates a ticket, prepares a worktree, checks packet output, simulates specialist and review evidence, runs scope/lint checks, and exercises the acceptance gate.
