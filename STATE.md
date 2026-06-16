# Palari Current State

This file is the quick orientation map for collaborators and agents. Read it
before building a feature that might already exist.

Last refreshed: POS-0098, after POS-0097 merged into `origin/main`.

Palari is repo-native governance for AI coding agents. It is not a generic
agent framework, a hosted task runner, or an automatic merge bot. The core
promise is visible, scoped, reviewable work with explicit human gates.

## How To Orient

1. Run `./bin/palari status --next` to see the current gate.
2. Run `./bin/palari state` to print this capability map.
3. Read `docs/autonomy/dogfooding-workflow.md` before starting new Palari
   Orchestrator work after context compaction or branch cleanup.
4. Check `CHANGELOG.md` for recent landed tickets.
5. Check the relevant contract under `contracts/` before changing authority,
   scope, lifecycle, signed acceptance, or adapters.
6. Create or claim a scoped ticket before implementation.

## Shipped

### Ticket Governance

- Scoped Markdown tickets with `allowed_paths`, `forbidden_paths`, risk,
  priority, status, verification commands, and required reports.
- R5 is a first-class governance/kernel risk tier. R5 tickets require review
  and human confirmation, route conservatively, and are reserved for authority,
  policy, broker, ForgeGate, model allowlist, credential/tool, autonomous
  acceptance, and risk-definition changes.
- Claim leases, heartbeats, review state, reopening, blocking, needs-human
  state, and human/authorized acceptance.
- Scope checks for local and PR-diff paths.
- Ticket audit and queue planning with `palari run --dry-run`.

### Workflow Planning

- Workflow artifacts under `workflows/proposed`, `workflows/active`, and
  `workflows/closed` model company or business processes above tickets.
- `palari workflow create|list|show|lint|adopt|close` manages workflow
  lifecycle without running agents or accepting work.
- Workflow lint validates linked goals, risk ceilings, work units, expected
  decisions, and R3/R4/R5 skill requirements.
- `palari workflow plan WF-ID [--json]` combines workflow fields with Human
  Governance Load and active human coverage to show launch gate, autonomy
  ceiling, allowed modes, blocked modes, required skills, missing skills,
  bottlenecks, and recommended next actions without mutating lifecycle state.

### Human Governance

- Human governance profiles under `humans/proposed`, `humans/active`, and
  `humans/revoked` model skills, authority ceilings, capacity, and constraints.
- `palari human create|list|show|lint|adopt|revoke` manages profile lifecycle
  without granting agent authority or tracking worker productivity.
- Human lint validates skill levels, capacity numbers, authority risk, and the
  explicit policy-approval flag required for R5 authority.

### Human Governance Load

- `palari burden score WF-ID [--json]` computes deterministic, read-only Human
  Governance Load from workflow expected decisions and active human profiles.
- `palari human coverage WF-ID [--json]` shows required skills, missing or
  underleveled skills, covering humans, and bottleneck roles for a workflow.
- HGL output includes R0-R5 expected-decision counts, total burden, launch gate,
  and autonomy ceiling. It does not move workflows, accept tickets, activate
  policies, run agents, or perform side effects.

### Policy Simulation

- Policy artifacts under `policies/proposed`, `policies/active`, and
  `policies/revoked` model acceptance rules before they receive any authority.
- `palari policy create|list|show|lint` manages simulation-only policy
  artifacts.
- `palari policy simulate TICKET-ID [--json]` explains `would_accept` or
  `would_not_accept` from policy conditions, ticket risk, open decisions, and
  CI evidence without accepting or moving anything.
- `palari policy candidates [--json]` suggests conservative simulation policy
  candidates from repeated decided R0-R2 decisions where the human chose the
  recommended option.
- R5 tickets are never policy-eligible, and policy `risk_max: R5` is invalid.
- Unknown policy conditions fail closed during simulation.
- Candidate detection never creates or activates policy files automatically,
  and it excludes R3/R4/R5 decision classes from auto-accept suggestions.

### Broker Boundary

- `palari broker run TICKET-ID --mock -- COMMAND [ARGS...]` captures
  mock broker observed-command evidence under `reports/evidence/TICKET/broker/`.
- `palari broker evidence TICKET-ID [--json]` lists broker evidence.
- `palari broker status` reports the current broker posture:
  `real_side_effects_enabled: false`.
- Broker support is mock-only. It does not load credentials, call hosted APIs,
  enable network side effects, or grant agents direct external-write authority.
- Obvious dangerous command patterns are refused before execution, with refusal
  evidence preserved.

### Company OS Demo

- `palari demo --company-os` writes deterministic local fixtures for the
  Company AI OS shape: active workflow, human governance coverage, missing
  skill, policy-candidate signal, mock broker evidence, recorded outcome, and
  snapshot/web inspection.
- The demo is local-only and does not run agents, access network services,
  accept tickets, push, merge, deploy, or enable broker side effects.
- README and `docs/autonomy/company-ai-os-infrastructure.md` document the
  expanded direction while preserving the no-overclaim boundary.

### Outcome Ledger

- Outcome artifacts under `outcomes/open` and `outcomes/recorded` record what
  happened after governed work.
- `palari outcome create|list|show|lint|record` manages outcome records.
- Outcomes do not accept work and do not prove business impact unless evidence
  is linked.
- Outcome lint checks linked workflow, goal, ticket, decision, and evidence
  references when present.
- Policy candidates can cite recorded outcomes linked to their source tickets
  or decisions.

### Secure Governance Doctor

- `palari doctor secure` and `palari doctor governance` print the local
  governance posture without mutating lifecycle state.
- The doctor reports ForgeGate, broker side-effect posture, broker
  observations, policy acceptance posture, branch-protection verification
  limits, and R5 human approval configuration.
- Hosted branch protection is not verified locally; the doctor says so instead
  of claiming remote protections are active.
- Conservative config defaults keep policy acceptance simulation-only and
  broker real side effects disabled.

### Work Isolation

- Ticket branches and worktrees for isolated work.
- Local disposable sandboxes with `sandbox create|list|inspect|destroy`.
- Sandbox docs state clearly that local sandboxes are not a security boundary.
- Sandbox destroy refuses paths without the Palari sandbox marker.

### Executors

- `mock` executor for deterministic demos/tests, including safe and refused
  path scenarios.
- `opencode` executor wiring through the common `agent run` lifecycle.
- `codex` executor wiring and Codex prompt/doctor support.
- `openrouter` text-artifact executor, added in POS-0056.

Executor runs produce evidence under `reports/evidence/TICKET/executor/`.
Evidence records stdout, stderr, exit code, gate results, and resolved model
metadata where available.

### OpenRouter And Model Routing

- Risk-tiered model routing maps tickets to `fast`, `balanced`, or `frontier`
  classes.
- Inspect routing with `palari model routes` and `palari model show TICKET`.
- Tickets can request `model_hint` as a class or exact model.
- `agent run --model` still wins over routing.
- OpenRouter is disabled by default.
- OpenRouter reads the API key from the configured environment variable and
  never stores it in the repository.
- OpenRouter enforces `openrouter_allowed_models` fail-closed.
- OpenRouter tests use dry-run/offline transport and do not require a real key
  or network call.
- Optional `openrouter:advisor` configuration exists for a stronger advisor
  model, but real usage requires human spend/key approval.

### Dashboard And Snapshot

- Optional stdlib web console in `adapters/web/`.
- Dashboard reads `palari snapshot --json` state and shows tickets, roles,
  evidence, reports, progress, next actions, and human gates.
- Console Company Governance cards render the `company_os` snapshot section:
  workflow counts, open HGL, R3/R4/R5 decision counts, missing skills, and
  active workflow launch gates.
- Executor evidence and scope/CI refusal evidence surface in custody rows.
- Fast stdlib Python snapshot adapter serves `snapshot --json`, `status`, and
  `web --check`, with Bash fallback through full/legacy controls.
- `snapshot --json` includes a compact `company_os` section with workflow
  counts, human governance counts, open HGL estimate, R3/R4/R5 decision counts,
  missing skills, bottlenecks, autonomy gate distribution, simulation-only
  policy posture, and broker side-effect posture.

### Evidence And Reports

- Standard Palari CI evidence includes `verification.log`, `junit.xml`,
  `palari.sarif`, and `manifest.json`.
- Technical reports and reviewer notes are linted for required headings.
- Evidence quality scoring exists for completeness checks.
- Refused executor work is preserved as evidence instead of erased.

### Signed Acceptance / ForgeGate

- ForgeGate signed acceptance artifacts are imported under `gate/`.
- Signed gates are available as explicit gate commands and contracts.
- Human acceptance remains the authority boundary.

### Plugins, Skills, Roles, Prompts

- Claude plugin packaging is present under `plugin/` and `.claude-plugin/`.
- Agent skills are machine-discoverable and linted.
- Role files and packets support authority visibility and delegation.
- Prompt generation supports next, ticket, and long-run handoffs.

### Research

- DeepSeek pilot artifacts exist under `research/pilots/deepseek-full-pilot/`.
- The pilot measured governance visibility, scope control, reviewability,
  evidence capture, and human acceptance discipline.
- The pilot does not prove safety, speed, productivity, performance, or model
  quality improvements.

## Experimental / Opt-In

- Real OpenRouter execution. Enable only with `openrouter_enabled: true`, an
  approved model allowlist, and a human-provided API key.
- OpenRouter advisor routing. Treat this as spend-sensitive and review the
  request/evidence behavior before use.
- ForgeGate signed acceptance in day-to-day workflows. The kernel exists, but
  teams should decide where it is mandatory.
- Fast snapshot as the default read model. It is intended for operator views;
  full diagnostics still belong to lint, doctor, and full snapshot paths.

## Planned

- Company AI OS infrastructure: policy simulation, mock broker evidence,
  outcome records, and secure governance posture checks. See
  `contracts/company-ai-os.md`,
  `contracts/human-governance-load.md`, and
  `docs/autonomy/workflow-planning.md`.
- A richer collaborator orientation surface that can be regenerated or checked
  against shipped files.
- Stronger stale-worktree and stale-branch recovery guidance.
- More explicit founder/operator inbox decisions in the dashboard.
- More pilot studies comparing old and newer Palari workflows.

## Intentionally Not Supported

- Browser-side accept, merge, push, or deploy buttons.
- Silent acceptance, merge, push, or production mutation by an agent.
- Secret storage in the repository or evidence bundles.
- Treating local sandboxes as a security boundary.
- Claims that Palari has proven safety, speed, productivity, performance, or
  model-quality gains from the current pilot evidence.
- Heavy frontend/package-manager dependencies for the built-in dashboard.

## Before Building Something New

If your idea touches tickets, executors, OpenRouter, dashboard state, evidence,
signed gates, skills, roles, or prompts, first check:

- `STATE.md`
- `CHANGELOG.md`
- `contracts/`
- `./bin/palari status --next`
- `./bin/palari model routes`
- `./bin/palari run --dry-run`

When in doubt, create a small scoped ticket and preserve the decision trail.
