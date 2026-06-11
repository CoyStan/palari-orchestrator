<p align="center">
  <img src="assets/readme/palari-orchestrator-hero-general.png" alt="A calm Palari workflow moving from ticket intake through scoped work, evidence, review, and human acceptance." width="100%">
</p>

<h1 align="center">Palari Orchestrator</h1>

<p align="center">
  Repo-native governance for AI coding agents: scoped tickets, isolated work, evidence, fresh review, and explicit human acceptance.
</p>

<p align="center">
  <img alt="workflow: worktree-first" src="https://img.shields.io/badge/workflow-worktree--first-12345C?style=flat-square">
  <img alt="scope checked" src="https://img.shields.io/badge/scope-checked-2B9968?style=flat-square">
  <img alt="fresh context review" src="https://img.shields.io/badge/review-fresh--context-5B4DFF?style=flat-square">
  <img alt="golden tests" src="https://img.shields.io/badge/tests-golden-F4B433?style=flat-square">
  <img alt="license: MIT" src="https://img.shields.io/badge/license-MIT-111111?style=flat-square">
</p>

<p align="center">
  <a href="#why-palari">Why Palari</a> ·
  <a href="#5-minute-demo">5-minute demo</a> ·
  <a href="#how-palari-compares">Compare</a> ·
  <a href="#how-it-works">How it works</a> ·
  <a href="#quick-start">Quick start</a> ·
  <a href="#optional-console">Console</a> ·
  <a href="#command-reference">Commands</a>
</p>

Palari Orchestrator is the portable software-repo version of the Palari idea:
give an AI coworker a named job, approved sources, visible records, and a
permission moment before anything important moves.

```text
goal -> proposal -> ticket -> worktree -> packet -> scope-check -> ci evidence -> review -> decision -> accept
```

It is built for founders, operators, product people, and small technical teams
who want AI-assisted coding to feel controlled instead of mysterious. The repo
stays the source of truth. Agents get clear boundaries. Humans keep acceptance
authority.

## At a Glance

| Question | Answer |
| --- | --- |
| Who is it for? | Teams delegating coding work to agents while keeping human review and repository control. |
| What is the core? | Bash, Markdown, git, templates, and checks that can move into almost any repo. |
| What does it enforce? | Proposal adoption, ticket lifecycle, allowed/forbidden paths, evidence bundles, fresh-context review, and acceptance gates. |
| What is optional? | GitHub rulesets, hooks, MCP wrappers, opencode execution, local sandboxes, the console, and repo-memory adapters. |
| What is it not? | A hosted agent platform, product-specific Palari app code, or a replacement for human judgment. |

## Why Now / Why Palari

AI coding agents are getting easier to launch in parallel. That creates a new
operator problem: the work may be fast, but the source of truth, scope,
evidence, reviewer context, and final permission moment can become scattered
across chat threads, local worktrees, PR comments, and tool-specific dashboards.

Palari is the repo-native control layer for that moment. It does not try to be
the agent, the IDE, or the hosted platform. It gives agent-led coding work the
same kind of operational shape a careful human team expects: a ticket queue,
bounded workspaces, role authority, review packets, evidence bundles, and a
human acceptance gate that is explicit in the repository.

| Without a control layer | With Palari |
| --- | --- |
| The agent remembers the task in chat. | The ticket lives in the repo. |
| Scope drift is noticed late. | Allowed and forbidden paths are checked. |
| Work happens in the main checkout. | Work starts in a ticket worktree. |
| Roles are vibes or prompt text. | Role authority is visible and linted. |
| Review depends on summaries. | Review gets packets, reports, and CI evidence. |
| "Done" can be vague. | Acceptance is explicit and recorded. |

Palari is not a generic multi-agent platform. It is a few repo-native primitives
that make agent-led coding easier to delegate, inspect, and stop.

## 5-Minute Demo

The fastest way to evaluate Palari is to create local demo fixtures and open the
operator console. No external agent, hosted service, package install, or network
access is required.

```bash
git clone https://github.com/CoyStan/palari-orchestrator.git
cd palari-orchestrator
./bin/palari demo
./bin/palari web
```

Then open `http://127.0.0.1:8765`.

The demo writes two sample tickets:

| Ticket | What it shows |
| --- | --- |
| `DEM-0001` | A role-delegated ticket in review with reports and evidence, ready for human acceptance. |
| `DEM-0002` | A higher-risk ticket stopped at `needs-human` until an operator approves the gate. |

To see a deterministic agent-refusal fixture:

```bash
./bin/palari demo --agent-refusal
```

That writes `DEM-0003`, a blocked ticket with preserved mock-executor evidence
showing a forbidden `.env` write attempt refused by scope-check.

Use `./bin/palari demo --force` to replace the selected demo fixtures. The command
does not run an agent, change production paths, merge, push, or accept work.
It exists so a founder, operator, or reviewer can see the queue, role boundary,
evidence surface, and human gate immediately.

## Install In Your Agent

Palari is executor-agnostic, and the fastest path in is whichever agent you
already use.

**Claude Code** (one-command plugin: skill, slash commands, and role agents):

```text
/plugin marketplace add CoyStan/palari-orchestrator
/plugin install palari-orchestrator@palari
```

Then in any repo: `/palari-orchestrator:adopt`, `:status`, `:next`,
`:ticket`, `:review`, `:decide`. The plugin ships a `palari-specialist`
executor agent and a `palari-reviewer` fresh-context review agent that
respect the authority model (no self-acceptance, no self-review). Details in
[plugin/README.md](plugin/README.md).

**Codex and other AGENTS.md-aware agents**: adopt the repo and the contract
installs itself, since `palari adopt` writes `AGENTS.md`, which Codex reads
natively. Optional Codex prompt files:
`./adapters/codex/install.sh` (see [adapters/codex/](adapters/codex/)).

**Any agent, manually**: tell it
"clone palari-orchestrator, run `bin/palari adopt` on this repo, then read
AGENTS.md". The repo is the contract; no runtime dependency on any vendor.

## How Palari Compares

Most popular agent tools are optimized for running agents. Palari is optimized
for governing agent work after a human decides to delegate it.

| Tool or pattern | Primary job | Where Palari fits |
| --- | --- | --- |
| [Emdash](https://docs.emdash.sh/) | Agent development environment with parallel agents, isolated git worktrees, Kanban, and review surfaces. | Palari can govern the repository contract around those worktrees: scoped tickets, evidence, review packets, and acceptance. |
| [Conductor](https://www.ycombinator.com/companies/conductor) | App for running and reviewing multiple coding agents in isolated workspaces. | Palari provides a portable repo record that survives outside the app: ticket lifecycle, authority profiles, and evidence gates. |
| [gstack](https://github.com/garrytan/gstack) | Role and skill structure for Claude Code-style engineering teams. | Palari turns role boundaries into lintable Markdown authority files tied to tickets and acceptance. |
| [OpenHands](https://www.openhands.one/) | Full agent platform for launching software development agents. | Palari stays executor-agnostic and checks whether the resulting work is scoped, evidenced, reviewed, and accepted. |
| [LangGraph](https://www.langchain.com/langgraph) | Framework for building controllable agent workflows and applications. | Palari governs the code repository lifecycle around agent output rather than the internal graph. |
| Generic coding agents | Fast code edits from a prompt. | Palari adds queue discipline, path boundaries, fresh review, evidence, and an explicit human "yes." |
| Honor-system evidence bundles | Artifacts prove a run happened. | Palari's embedded forgegate kernel proves who had the authority to produce them: signed attestations, narrowing delegation tokens, dual control by distinct keys, and commit binding. |

Palari should feel complementary to agent runners, IDEs, and hosted coding
platforms. The sharper distinction is simple: they help produce work; Palari
helps decide whether that work was allowed, reviewed, evidenced, and accepted.

## How It Works

![Palari Orchestrator workflow](assets/readme/orchestration-flow.svg)

1. Create a ticket with the goal, allowed paths, forbidden paths, and checks.
2. Give the agent a clean worktree and a packet that says exactly what it can do.
3. Run scope checks and CI evidence before review.
4. Review with fresh context.
5. Accept only when the evidence, scope, and authority gates pass.

Ceremony scales with risk. Small R0/R1 tasks stay short. R2+ work gets stronger
review and evidence gates. R3/R4 work requires human confirmation.

## The Operating Loop: Goals In, Decisions Out

Palari's larger purpose is letting a human direct a team of agents the way a
CEO directs a team: define roles and goals, let the work self-organize inside
visible boundaries, and receive decisions instead of status noise. Three
repo-native primitives close that loop.

**Goals** make intent machine-readable. A goal is a lintable artifact with an
owner, success criteria, and a due date. Tickets and proposals declare which
goal they serve (`serves_goal`), so "why is this the next ticket" is
answerable from repo state alone.

```bash
./bin/palari goal create GOAL-0001 "Ship the operator console v1" \
  --owner founder --success "Console renders the founder inbox" --due 2026-07-01
./bin/palari ticket create POS-0042 "Wire inbox filters" --goal GOAL-0001 \
  --allowed "adapters/web/**" --verify "node --check adapters/web/static/app.js"
```

**Decisions** are how agents bring judgment back. Instead of parking work as
a vague `needs-human` ticket, an agent drafts a decision: one question, two
or more options with tradeoffs, a recommendation, a respond-by date, and an
explicit default. Only a human records the outcome, and recorded decisions
flow into repo memory so future packets cite them.

```bash
./bin/palari decide create DEC-0001 "Pick console chart library" \
  --ticket POS-0042 --option "Chart.js (small, familiar)" \
  --option "D3 (flexible, heavier)" --recommend 1 --default 1 --respond-by 2026-06-20
./bin/palari decide record DEC-0001 --choice 1 --by founder
```

**The queue runner** answers "what happens next" without doing anything.
`palari run --dry-run` walks the queue in priority order, plans each safe
step, and stops at human gates. Open decisions surface first. Supervised and
autonomous modes do not exist yet; `palari run` without `--dry-run` fails
closed by design.

```bash
./bin/palari run --dry-run --goal GOAL-0001
./bin/palari run --dry-run --json
```

Defaults on decisions may never include accept, merge, push, deploy, spend,
or credential actions. The full rules live in
[contracts/goals-and-decisions.md](contracts/goals-and-decisions.md).

## Forge-Proof Acceptance (Signed Gate)

Agents are untrusted workloads. Evidence files and `--by NAME` strings answer
"does the work look done"; they cannot answer "who had the authority to say
so". The vendored [forgegate kernel](gate/README.md) answers that question
with cryptography, and `palari accept` enforces it when `gate.enabled: true`
in `palari.config.yaml`.

The gate refuses acceptance unless, for every step the layout requires:

- a signed attestation exists (exactly one; duplicates are ambiguity),
- its delegation token chain verifies to the repository root key with scope
  that only ever narrows,
- the signer is the token holder, so a stolen token is useless,
- hash flow holds byte for byte: the test step consumed the exact implement
  diff, review consumed the exact evidence,
- dual control holds: review is signed by a different key than implement
  and test,
- everything binds to the expected commit inside a freshness window.

```bash
./bin/palari gate init                  # once: root + orchestrator keys
./bin/palari gate setup-ticket T-42     # implement, test, review tokens
./bin/palari gate attest-implement T-42 # sign the exact diff bytes
./bin/palari ci T-42                    # evidence; auto-attests the test step
./bin/palari gate attest-review T-42    # a fresh key signs the review
./bin/palari accept T-42 --by founder   # gate verdict required
```

Tickets stay pure data: nothing written into a ticket can mint, widen, or
substitute for a token, so prompt injection in a ticket grants no authority.
The gate fails closed, refusals carry exact reasons, and the kernel ships
with its adversarial test suite in `gate/tests`. The boundary, threat model,
and replacement inventory are documented in
[contracts/signed-acceptance.md](contracts/signed-acceptance.md) and
[docs/integration/INTEGRATION.md](docs/integration/INTEGRATION.md).

## What You Get

| Primitive | What it protects |
| --- | --- |
| Goals | Founder intent becomes a lintable artifact tickets trace to, so prioritization is auditable. |
| Decisions | Agents bring structured options with a recommendation and a default; only humans record outcomes. |
| Queue dry-run | A read-only plan of every safe next step up to the next human gate. |
| Lead proposals | Messy founder intent becomes adoptable tickets without letting the planner implement. |
| Scoped tickets | The agent knows where it may work and what must be verified. |
| Worktree-first execution | Each ticket gets isolated from the main checkout. |
| Agent packets | Specialists, reviewers, and acceptors get the right context. |
| Scope checks | Changed files are compared against allowed and forbidden paths. |
| CI evidence | Logs, JUnit, SARIF, and an integrity manifest are written for the ticket. |
| Human acceptance | `palari accept` refuses missing, failed, or stale evidence and records who accepted. |
| Forge-proof gate (optional) | When enabled, acceptance requires Ed25519-signed implement, test, and review attestations that verify to the repository root key. |

## Quick Start

Try Palari in this repo:

```bash
git clone https://github.com/CoyStan/palari-orchestrator.git
cd palari-orchestrator
./bin/palari init
./bin/palari status
tests/run-golden.sh
```

For a guided first look, run `./bin/palari demo` before `./bin/palari web`.
That path creates sample operator-console data instead of asking you to invent a
real ticket first.

Adopt it in another repo:

```bash
./bin/palari adopt /path/to/repo
cd /path/to/repo
./bin/palari doctor
./bin/palari status
```

Add optional GitHub and local hook adapters:

```bash
./bin/palari adopt /path/to/repo --ci --hooks
```

The workflow file alone does not protect merges. Install the ruleset when you
want GitHub to require the Palari check:

```bash
palari github install-ruleset --repo OWNER/REPO
```

GitHub PRs are intentionally ticketed by default. The workflow calls
`palari github ci`, which resolves tickets from `PALARI_TICKET_ID`, a
`ticket/TICKET-ID` branch name, or changed ticket files. If none is found, the
check fails with instructions instead of silently running a weak gate. Use
`palari github ci --repo-only` only for explicit maintenance checks that are not
claiming ticket-governed agent work.

`adopt` refuses non-git targets, keeps existing files by default, writes
`AGENTS.palari.md` instead of overwriting an existing `AGENTS.md`, runs
`palari init`, and finishes with `palari doctor`.

## First Ticket

If the work is still fuzzy, start with a lead/planner proposal:

```bash
palari propose create APP-PROP-0001 "Improve onboarding" \
  --planner openclaude \
  --model deepseek/deepseek-v4-flash \
  --intent "Make the repository easier for non-programmers to understand."

palari propose packet APP-PROP-0001
palari propose adopt APP-PROP-0001 \
  --ticket APP-0001 \
  --allowed "src/**" \
  --allowed "tests/**" \
  --allowed "tickets/**" \
  --allowed "reports/**" \
  --verify "npm test" \
  --review
```

The lead can write `tickets/proposed/**` and `reports/planning/**`. It cannot
implement, accept, push, commit, or broaden authority. A human adopts the
proposal before executor work begins.

If the work is already clear, create the ticket directly:

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

## Authority Profiles

Palari separates human intent from autonomous agent authority. The default
profile is `team-safe`: agents can prepare branch work and PRs, but they cannot
merge main or accept tickets as done.

```bash
palari authority
palari authority check merge-main
palari status --next
palari doctor lifecycle
```

Adopters can switch profiles in `palari.config.yaml`:

| Profile | Good for | Agent authority |
| --- | --- | --- |
| `team-safe` | Public default and small teams | commit/push branch/open PR allowed; merge main and accept denied |
| `solo-founder` | A trusted single maintainer workflow | merge main allowed; accept requires an explicit user instruction |
| `strict` | Regulated or unfamiliar repos | no autonomous commit, push, PR, merge, or accept |

This is a policy signal for packets, wrappers, and human review. It does not
remove GitHub branch protection or repository rules; keep those as the hard
merge gate when the repo needs non-bypassable enforcement.

## Optional External Executors

Palari can wrap stronger coding agents without making them the authority. The
first wrapper targets opencode:

```bash
palari agent run APP-0001 --executor opencode
```

The wrapper prepares the Palari worktree and packet, runs opencode with Palari
lifecycle commands denied, captures executor evidence, then runs Palari scope
and CI gates. It does not accept, push, merge, or deploy.

OpenClaude can act as a restricted lead/planner when paired with
`palari propose packet`. DeepSeek models can be used through whichever executor
adapter supports them. Palari keeps the same boundary: planner proposes, executor
implements, reviewer checks, human accepts.

Use a disposable local copy when you want to test executor behavior away from
the canonical checkout:

```bash
palari sandbox create APP-0001
```

Palari distinguishes worktrees (normal ticket isolation), local sandboxes
(disposable repo copies for executor experiments), and hardened sandboxes
(container/VM/remote isolation, not yet shipped). A local sandbox protects the
canonical checkout from accidental dirtying; it is not a security boundary and
does not contain a malicious agent. Governance comes from scope, evidence,
review, and acceptance gates, not from the sandbox.

## Optional Console

The local console is the primary proof surface for non-technical operators. It
is a read-only view over `palari snapshot --json`, so the repository remains the
source of truth while the browser gives people a calm way to monitor work.

```bash
palari web
```

![Palari Console dashboard showing ticket health, evidence status, scope partitions, and copyable commands.](assets/readme/palari-console-preview.png)

The console gives one snapshot three surfaces: a triage queue, a pipeline
board grouped by lifecycle stage, and a full ledger table. Selecting a ticket
opens its dossier with a chain-of-custody rail that shows the implement, test,
and review seals, the signer key fingerprints, and the gate verdict with its
exact refusal reasons. It is keyboard-first (`/` search, `j`/`k` move,
`1`/`2`/`3` switch surfaces), refreshes itself quietly, ships light and dark
themes, and never fakes a green seal: with the gate disabled it says plainly
that acceptance is honor-system.

From an operator's point of view, the console answers six questions:

| Question | Console surface |
| --- | --- |
| What is waiting? | Ticket queue, status, priority, risk, and next allowed action. |
| Who or what owns it? | Active roles, delegated role, claimed-by, and live lease countdowns. |
| Is progress real? | Lifecycle state, reports, evidence files, and verification status. |
| Is the evidence forged? | The chain of custody: signed steps, key fingerprints, and the gate verdict. |
| Is scope safe? | Allowed paths, forbidden paths, overlap warnings, and stale claims. |
| Can a human accept it? | Review state, missing gates, and the exact `palari accept` command when ready. |

## Design Principles

- **Repo is law:** tickets, reports, evidence, and config live in the repository.
- **Small core:** Bash, Markdown, and git remain enough for the portable loop.
- **Adapters stay optional:** GitHub, MCP, hooks, console, and skills do not own acceptance.
- **Humans keep authority:** review can recommend; acceptance is explicit.
- **No product lock-in:** product-feel and app-specific preferences are examples or adapters.

## Optional Repo Memory

Palari can store repo-native memory under `memory/**/*.md`: accepted decisions,
path-level invariants, gotchas, failure patterns, and command knowledge.

Memory is source-controlled Markdown. SQLite FTS is only an optional generated
search cache under `.palari/cache/`. The orchestrator uses active memory to
enrich packets; specialists receive the selected memory in their packet and
should not browse the full memory directory unless blocked.

```bash
palari memory add invariant "Console stays read-only" \
  --truth-key web.console.mutation_boundary \
  --path "adapters/web/**" \
  --source-ticket WEB-0001

palari memory index
palari memory query --path adapters/web/server.py
palari packet WEB-0002 specialist
```

## Command Reference

<details>
<summary>Core, adapter, and experimental commands</summary>

### Core Commands

| Command | Purpose |
| --- | --- |
| `palari init` | Create the ticket, report, and handoff directories expected by the workflow. |
| `palari adopt /path/to/repo` | Copy Palari into an existing git repo, initialize it, and run the doctor. |
| `palari demo [--force] [--agent-refusal]` | Create local sample tickets, reports, and evidence for the operator console. |
| `palari doctor` | Check whether the current repo has the required Palari files and directories. |
| `palari doctor lifecycle` | Explain the next action for active tickets. |
| `palari status [--next]` | Show current tickets and optionally the next required lifecycle action. |
| `palari snapshot --json` | Print the repo-native JSON state model used by adapters. |
| `palari hygiene [--strict]` | Classify generated vs source dirty paths, stale claims, review gates, and unmerged ticket branches. |
| `palari authority` | Show the active agent authority profile. |
| `palari authority check ACTION` | Check whether an autonomous agent may commit, push, open a PR, merge main, or accept. |
| `palari role list` | List optional repo-native roles and their authority boundaries. |
| `palari role lint` | Validate that active roles only narrow authority from their parent roles. |
| `palari role packet ROLE-ID` | Generate a role authority packet for a planner, specialist, or reviewer. |
| `palari role propose ROLE TITLE --by-role PARENT` | Stage a child role proposal without activating it. |
| `palari role adopt ROLE --by ACTOR` | Activate a proposed role only after authority checks pass. |
| `palari propose create ID TITLE` | Create a restricted lead/planner proposal before executable ticket work exists. |
| `palari propose packet ID` | Print the restricted lead packet for a planner AI such as OpenClaude. |
| `palari propose adopt ID --ticket TICKET-ID` | Convert a human-approved proposal into a real scoped ticket. |
| `palari goal create ID TITLE --success TEXT` | Create a first-class founder goal with success criteria. |
| `palari goal list / show / lint` | Inspect goals and the tickets serving them; check serves_goal links. |
| `palari goal adopt / achieve / drop ID --by NAME` | Human goal lifecycle actions. |
| `palari decide create ID TITLE --option A --option B` | Draft a structured decision with options, recommendation, and default. |
| `palari decide record ID --choice N --by NAME` | Record the human outcome; archives it and mirrors it into repo memory. |
| `palari run --dry-run [--goal ID] [--json]` | Read-only queue plan up to the next human gate; fails closed without --dry-run. |
| `palari ticket create ID TITLE` | Create a scoped ticket with allowed paths, risk, checks, and review requirements. |
| `palari ticket claim ID` | Mark a ticket as claimed before implementation work starts. |
| `palari ticket audit` | Explain active ticket next actions. |
| `palari ticket heartbeat ID` | Renew the ticket claim lease. |
| `palari ticket ready ID` | Move a ticket into review once implementation evidence exists. |
| `palari ticket block ID` | Mark scoped work blocked. |
| `palari ticket needs-human ID` | Mark work that needs human authority or product judgment. |
| `palari ticket reopen ID` | Move an in-review ticket back to implementation. |
| `palari worktree ID` | Create or locate the ticket-specific git worktree. |
| `palari packet ID ROLE` | Generate the mission packet for a specialist, reviewer, acceptor/human, or custom review profile. |
| `palari sandbox create ID` | Create a disposable local repository copy for executor experiments. |
| `palari sandbox list` | List local sandboxes under the worktree base with dirty state. |
| `palari sandbox inspect ID` | Show sandbox metadata (`.palari/sandbox.json`), source commit, and changed paths. |
| `palari sandbox destroy ID` | Remove a Palari sandbox; refuses paths without the sandbox marker. |
| `palari agent run ID --executor opencode` | Run opencode from a Palari packet and record executor evidence without accepting work. |
| `palari memory ...` | Manage optional repo-native memory and generated search indexes. |
| `palari ci ID --base REF` | Run scope/lint/report gates and write evidence artifacts. Fails closed without a ticket. |
| `palari ci --repo-only` | Run explicit non-merge-gate repository lint evidence. |
| `palari scope-check [ID]` | Compare changed files against allowed and forbidden path rules. |
| `palari scope-overlaps [ID]` | Detect overlapping active ticket write scopes. |
| `palari lint [ID]` | Validate ticket state and required reports. |
| `palari report-lint [ID]` | Validate specialist and reviewer report structure. |
| `palari accept ID --by NAME` | Close the ticket only after the acceptance gate is satisfied. |
| `palari gate init` | Create the forge-proof gate root and orchestrator keys. |
| `palari gate setup-ticket ID` | Grant implement, test, and review step tokens for a ticket. |
| `palari gate attest-implement ID` | Sign the exact ticket diff with the implementer key. |
| `palari gate attest-test ID` | Sign the CI evidence bundle with the ci key. |
| `palari gate attest-review ID` | Sign the fresh review with the reviewer key. |
| `palari gate verify ID` | Run the cryptographic accept gate; ACCEPTED or REFUSED with reasons. |
| `palari gate status` | JSON gate status used by the snapshot and console. |

### Adapter Commands

| Command | Purpose |
| --- | --- |
| `palari github ci --base REF` | Discover PR tickets from env, branch, or changed ticket files, then run merge-gate CI. |
| `palari github ruleset-command` | Print the `gh api` command that activates required checks. |
| `palari github install-ruleset` | Install the GitHub ruleset through `gh api`. |
| `palari mcp manifest` | Print optional MCP tool metadata for wrapper adapters. |
| `palari web` | Run the optional local Palari Console dashboard. |

### Experimental Commands

| Command | Purpose |
| --- | --- |
| `palari skill create NAME` | Scaffold an optional feature-contract skill adapter. |
| `palari skill list` | List shipped, adopter, and plugin skills with descriptions. |
| `palari skill lint` | Validate skill frontmatter; refuse authority-claiming wording. |

</details>

## Governance Details

Palari's core remains Bash, Markdown, and git. The heavier governance features
ship as adapters:

- GitHub Actions: `palari init --ci` writes `.github/workflows/palari.yml`.
- GitHub rulesets: `palari init --ci` writes `.github/palari-required-checks.ruleset.json`.
- GitHub ticket discovery: `palari github ci` fails closed when no PR ticket is discoverable and prints the allowed ticketed and repo-only paths.
- Adoption: `palari adopt TARGET` copies the portable package into an existing git repository and runs `palari doctor`.
- Local demo: `palari demo` writes `DEM-0001` and `DEM-0002` sample fixtures so first-time users can inspect the console without an agent runner. `palari demo --agent-refusal` writes `DEM-0003`, a blocked mock-executor refusal fixture with preserved evidence.
- Local hooks: `palari init --hooks` writes `lefthook.yml` for fast advisory checks.
- Lead proposals: `palari propose create`, `palari propose packet`, and `palari propose adopt` separate planning authority from implementation authority.
- Authority profiles: `palari authority` makes agent commit, push, PR, merge, and accept permissions explicit per repository.
- Role-governed delegation: `palari role` lets a repo define root, lead, specialist, and reviewer authority as Markdown files. Role authority can only narrow as it flows from parent role to child role to ticket; unclear path containment escalates, and forbidden or invalid grants are rejected. Roles are local-mode authority artifacts. Signed provenance is not enforced in v1.
- Lifecycle visibility: `palari status --next`, `palari doctor lifecycle`, and `palari ticket audit` explain active tickets that are not closed yet.
- Autonomous hygiene: `palari hygiene` separates generated cache/build artifacts from source changes, highlights stale claims, and shows ticket branches with unintegrated work.
- Executor wrappers: `palari agent run TICKET-ID --executor opencode` invokes opencode from a Palari packet and records executor evidence.
- Mock executor: `palari agent run TICKET-ID --executor mock --scenario safe|forbidden-path|outside-scope` proves the governance loop deterministically - no AI tool, network, or credentials. The forbidden-path scenario shows an executor touching `.env`, scope-check refusing it, evidence preserved, and ticket state not advancing.
- Codex executor: `palari agent run TICKET-ID --executor codex [--dry-run]` runs Codex through the same governed lifecycle; `palari codex doctor` checks readiness and `palari codex install` adds the prompt pack. See [adapters/codex/](adapters/codex/).
- Local sandboxes: `palari sandbox create TICKET-ID` creates a disposable repository copy for executor experiments. Not a security boundary; scope and evidence gates remain the control layer.
- Evidence integrity: `palari ci` writes `reports/evidence/<ticket>/verification.log`, `junit.xml`, `palari.sarif`, and `manifest.json`; `accept` validates manifest status, current commit, and artifact hashes before closing a ticket.
- Trusted merge evidence: the GitHub adapter uploads and attests `palari-evidence.tgz` on trusted repository runs. GitHub rulesets must be installed before this protects merges.
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
bin/palari                        Thin CLI entrypoint and command dispatcher
lib/palari/                       Portable Bash modules behind the CLI
palari.config.yaml                Example config for lifecycle, paths, roles, and gates
schemas/palari.config.schema.json Config schema
templates/                        Human report, handoff, and feature-contract templates
examples/                         Optional adopter examples such as product-feel review
contracts/                        Portable workflow contracts
adapters/                         Optional GitHub, hooks, MCP, opencode, OpenClaude, and web templates
skills/orchestrator/SKILL.md      Orchestrator usage guidance
skills/planner/SKILL.md           Restricted lead/planner guidance
skills/adoption/SKILL.md          Install/adoption guidance and rubric
tickets/proposed/                 Human-adopted proposal staging area
reports/planning/                 Lead packets and planning notes
roles/active/                     Optional active repo authority roles
roles/proposed/                   Proposed roles awaiting adoption
roles/revoked/                    Revoked role records
tests/golden/                     Fixtures that prove the flow works
```

</details>

## Confidence Checks

```bash
tests/run-golden.sh
tests/run-demo.sh
tests/run-cli-structure.sh
tests/run-adoption.sh
tests/run-agent-wrapper.sh
tests/run-dashboard-rubric.sh
./bin/palari lint
shellcheck -x bin/palari scripts/palari tests/run-cli-structure.sh tests/run-agent-wrapper.sh
shfmt -d bin/palari scripts/palari lib/palari/*.bash tests/run-cli-structure.sh tests/run-agent-wrapper.sh
actionlint
python3 -m py_compile adapters/web/server.py
bats tests
```

The golden test creates a temporary repository, initializes the orchestrator, creates a ticket, prepares a worktree, checks packet output, simulates specialist and review evidence, runs scope/lint checks, and exercises the acceptance gate.
