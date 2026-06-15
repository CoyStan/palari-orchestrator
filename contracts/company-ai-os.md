# Company AI OS Contract

This contract records Palari's company AI OS direction without changing
runtime behavior. Palari remains a repo-native authority layer for AI-assisted
work. It is not an agent runner, a hosted task system, or an automatic
acceptance bot.

## Doctrine

Palari governs the boundary around work:

- Palari is the authority layer, not the agent. Models, executor adapters,
  memory systems, and tool providers are replaceable workers or subsystems.
- The repository remains the source of truth. Goals, workflows, tickets,
  decisions, policies, human governance profiles, evidence, and outcomes must
  be inspectable repo artifacts before they become product features.
- Humans govern the boundary. Humans set goals, values, risk appetite, policy,
  exceptions, and acceptance posture. AI may plan, draft, review, and gather
  evidence inside those boundaries.
- Human Governance Load is first-class. Palari should forecast how much human
  judgment a workflow needs, which skills are required, and who may become a
  bottleneck.
- Workflows sit above tickets. A workflow represents a business or company
  process, and tickets remain the scoped implementation units beneath it.
- Every workflow needs an autonomy ceiling. Palari should say whether work can
  run as research, draft, branch/PR, staging, policy-simulated, human-led, or
  blocked.
- Policy acceptance starts as simulation. A policy may explain what it would
  accept, but it must not mutate lifecycle state until later safeguards exist
  and humans explicitly authorize that posture.
- A broker controls side effects. Agents should not own credentials or direct
  external writes. A broker checks policy, performs or refuses the action, and
  records evidence. Initial broker work must be mock/read-only.
- R5 protects Palari governance itself. Changes to policy authority, role
  authority, broker behavior, ForgeGate, model allowlists, credential/tool
  permissions, risk definitions, or autonomous acceptance rules are
  governance/kernel changes.
- Read-only first and fail-closed always. Planning, scoring, simulation, and
  dashboard visibility land before autonomous execution or real side effects.

The product sentence is:

> Palari plans not only the work AI will do, but the human judgment the company
> must reserve.

## Target Shape

The company AI OS layer builds above the existing Palari governance spine:

```text
Goal
  -> Workflow
    -> Work Units / Tickets / Decisions
      -> Evidence
        -> Review
          -> Human or Policy Acceptance
            -> Outcome
```

The current ticket lifecycle remains intact:

```text
goal -> proposal -> ticket -> worktree -> packet -> scope-check -> ci evidence
  -> review -> decision -> accept
```

Company OS artifacts add planning context; they do not grant authority by
themselves.

## Initial Artifact Families

Future tickets may add these repo-native artifact families:

- `workflows/**`: company or business processes above tickets.
- `humans/**`: human governance coverage, skills, capacity, and constraints.
- `policies/**`: simulation-only policy acceptance rules until real acceptance
  is explicitly authorized.
- `reports/evidence/**/broker/**`: broker-observed evidence, starting with
  mock local observations.
- `outcomes/**`: records of what happened after work, including predicted vs
  actual risk and Human Governance Load.

Each family must be documented, lintable, deterministic, and safe when absent.

## Risk And Authority Boundary

R5 is reserved for Palari governing itself and the company's operating
boundary. AI may draft or propose R5 work. R5 work must be review-gated,
human-gated, and routed conservatively. AI must not silently enact,
policy-accept, or self-approve R5 work.

R5 includes:

- policy changes
- role authority changes
- human approval threshold changes
- broker behavior changes
- ForgeGate changes
- model allowlist changes
- credential or tool permission changes
- autonomous acceptance rules
- risk-tier definitions
- Palari kernel changes that weaken enforcement

Until later tickets add explicit R5 enforcement, all Company OS work must stay
conservative: simulation before mutation, mock broker before real side
effects, and human acceptance before any authority expansion.

## Human Governance Load

Human Governance Load is Palari's estimate of the human judgment required by a
workflow. It should account for:

- risk tier
- novelty
- ambiguity
- irreversibility
- context required
- skill scarcity
- evidence quality

The goal is not mathematical sophistication. The goal is to make scarce human
judgment visible, planned, reducible, and reserved for the decisions that
actually need it.

## Policy Simulation

Policy is how repeated human judgment becomes a rule. Policy acceptance must
begin in simulation-only mode:

- `policy simulate` may explain whether a ticket would meet a policy.
- Unknown evidence or unknown conditions must produce `would_not_accept`.
- No policy command may move tickets, accept work, merge, push, deploy, or
  replace human judgment in this batch.
- R5 must remain ineligible for policy acceptance.

## Broker Boundary

The broker is the boundary between agents and company side effects.

Batch-one broker work must remain mock/local:

- no real credentials
- no real Slack, email, Stripe, GitHub, cloud, or customer writes
- no hosted calls
- no secret storage
- no production mutation

Broker evidence must distinguish what was observed by the broker from what was
claimed by an agent, signed by ForgeGate, accepted by a human, or simulated by
a policy.

## Non-Goals For The First Company OS Batch

Do not build these until the supporting safeguards exist and a later ticket
explicitly authorizes them:

- real external broker connectors
- real autonomous acceptance
- browser buttons that mutate tickets, policies, broker actions, PRs,
  deployments, or acceptance state
- hosted Palari service behavior
- a generic memory system or generic agent framework
- employee productivity surveillance
- claims that Palari has proven safety or productivity improvements beyond
  tested evidence

## Acceptance Standard

The Company OS roadmap is acceptable only if it preserves the existing Palari
core:

- visible scoped work
- repo artifacts as source of truth
- evidence before acceptance
- fresh-context review
- explicit human gates
- fail-closed behavior
- no secrets in repo artifacts or evidence
- no side-effecting capability without dry-run or simulation mode first
