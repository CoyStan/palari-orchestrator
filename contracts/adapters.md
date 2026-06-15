# Adapter Boundary

Palari Orchestrator keeps the reusable core small:

- Bash CLI
- Markdown tickets and reports
- git worktrees and refs
- path scope checks
- role packets
- lifecycle, review, and acceptance gates

Adapters may add ecosystem-specific enforcement or ergonomics, but they must not
become required for the core workflow to run.

## GitHub Adapter

The GitHub adapter may generate:

- `.github/workflows/palari.yml`
- `.github/palari-required-checks.ruleset.json`
- required status-check documentation
- artifact upload steps for Palari evidence
- SARIF upload steps for Palari findings
- artifact attestation for `palari-evidence.tgz`

The workflow should call the CLI. It should not reimplement ticket parsing,
scope checks, lifecycle rules, or acceptance policy.

The ruleset JSON is inert until installed in GitHub. Use:

```bash
palari github ruleset-command --repo OWNER/REPO
palari github install-ruleset --repo OWNER/REPO
```

The workflow is a check producer. The ruleset is the merge authority.

## Local Hook Adapter

Local hooks are fast feedback only. They can run `palari lint` and
`palari scope-overlaps`, but they are not an authority boundary because users
can skip hooks.

## Adoption Adapter

Adoption is a copy-and-check flow, not a package manager or hosted installer.
Use:

```bash
palari adopt /path/to/repo
palari doctor
```

The adoption flow copies the portable package into an existing git repository,
runs `palari init`, and prints next commands. It must keep existing files by
default, write `AGENTS.palari.md` instead of overwriting an existing
`AGENTS.md`, and keep GitHub workflows/hooks opt-in.

## Evidence Adapter

CI evidence belongs under `reports/evidence/`. The standard bundle is:

- `verification.log`
- `junit.xml`
- `palari.sarif`

The GitHub adapter packages this directory into `palari-evidence.tgz`, uploads
it as an artifact, and uses `actions/attest` when repository permissions allow
attestations. Human-authored reports remain separate from machine-produced
evidence.

## MCP Adapter

MCP is a delivery protocol for agents. It may expose Palari commands as tools,
but the CLI remains the source of truth and `accept` remains a human or
authorized-reviewer gate.

## Executor Adapters

Executor adapters run a stronger coding agent inside a Palari ticket contract.
The first supported executor is opencode:

```bash
palari agent run TICKET-ID --executor opencode
```

Executor adapters may invoke external agents, capture their logs, and run
Palari gates. They must not accept work, push, deploy, or own lifecycle
authority. Palari remains responsible for ticket scope, evidence, review, and
acceptance.

Use:

```bash
palari sandbox create TICKET-ID
```

when you need a disposable local repository copy for executor experiments.
Worktrees still remain the default execution surface for the first wrapper
because existing packet and evidence commands already understand them.

Isolation vocabulary: a worktree is normal ticket isolation; a local sandbox
is a disposable repo copy that protects the canonical checkout from accidental
dirtying; a hardened sandbox (container, VM, or remote runtime) does not exist
yet and may only arrive as a later adapter. A local sandbox is not a security
boundary, and adapters must not describe it as one. Containment of untrusted
executors comes from scope-check, evidence, review, and human acceptance.

## Company OS Worker Adapter Contract

Company OS worker adapters connect Palari-governed work to replaceable
workers. This contract covers future Hermes, GBrain, OpenRouter, Codex, local
agents, and human delegates before any one of them receives special authority.

Worker types may include:

- `coding_agent`
- `research_agent`
- `review_agent`
- `memory_provider`
- `model_provider`
- `workflow_executor`
- `human_delegate`

External workers may:

- receive scoped work packets created by Palari
- produce outputs, logs, reports, patches, and evidence
- request broker actions using explicit ticket, risk, tool, action, and
  resource context
- return structured status that Palari can attach to tickets, workflows,
  broker evidence, or outcome records

External workers must:

- declare their worker type, provider, model, runtime, version, and execution
  environment
- make their inputs, outputs, logs, and evidence auditable by Palari
- run inside a ticket, workflow, broker, or human-delegation boundary that
  Palari can inspect
- treat Palari repo-native artifacts as the authority source for scope,
  evidence, review, and acceptance

External workers must not:

- hold company credentials directly
- accept work, close tickets, or satisfy human acceptance gates
- merge, deploy, send, charge, refund, or mutate production/customer systems
  unless a broker permits and records the action
- bypass path scope, risk tier, R5, policy simulation, broker, or review gates
- convert policy simulation into real acceptance authority
- hide network access, hosted API calls, tool permissions, prompts, model
  identity, or runtime identity from Palari evidence

Broker requests are not permission grants. A worker may ask for a broker
action, but the broker boundary decides whether the action is observed, denied,
or eventually performed under a later R5-approved real-side-effect design. In
this repo version, company OS worker adapters are contract-only and must not add
real network dependencies, credentials, hosted services, or side-effecting
connectors.

## Lead Planner Adapters

Lead planner adapters turn founder intent into proposals, not implementation.
They may read repository context, selected memory, skills, and contracts, then
write proposal artifacts under `tickets/proposed/**` and planning notes under
`reports/planning/**`.

The first stable boundary is repository-native:

```bash
palari propose create POS-PROP-0001 "Plan the next slice" \
  --planner openclaude \
  --model deepseek/deepseek-v4-flash
palari propose packet POS-PROP-0001
palari propose adopt POS-PROP-0001 --ticket POS-0013 ...
```

Lead adapters must not edit source files, run implementation, accept tickets,
push, commit, deploy, or rewrite governance. OpenClaude and opencode can both
consume the lead packet if configured, but the proposal/adoption boundary stays
in Palari.

## Web Adapter

The web adapter is an operator console. It should render `palari snapshot
--json`, then present copyable CLI commands and health signals.

It must not become a separate source of truth:

- no separate ticket database
- no duplicate ticket/report/scope parser
- no acceptance bypass
- no hidden mutation path around `palari`
- no product-specific Palari app assumptions in the portable console

`palari web` binds to `127.0.0.1` by default and runs from the stdlib Python
server in `adapters/web/`.

## Repo-Specific Adapters

Product vocabulary, private app routes, screenshots, founder preferences,
browser scripts, live connectors, and project-specific danger zones belong in
adopters' repositories, not in the portable core.
