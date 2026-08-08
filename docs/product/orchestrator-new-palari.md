# The New Palari Orchestrator

Status: product direction document. This is a guide for redesigning Palari
Orchestrator. It is not an implementation ticket, not a release commitment,
and not a replacement for the current contracts until specific changes are
implemented and accepted.

## One Sentence

Palari Orchestrator is a company AI operating system that lets humans set
intent, delegate bounded work to AI roles, prove what happened, preserve human
authority, and learn from outcomes without drowning the operator in ceremony.

## The Core Shift

The current Palari has strong primitives but too much visible ceremony.

The new Palari should keep the serious parts:

- goals
- decisions
- human authority
- AI role packets
- scoped work
- work isolation
- evidence
- review
- acceptance
- outcomes
- memory
- policy and broker boundaries

But it should stop making the operator manually reconcile every artifact.

The daily product should feel less like:

```text
Find ticket -> inspect claim -> inspect worktree -> inspect reports -> inspect
evidence -> inspect reviewer note -> inspect branch -> infer next command.
```

And more like:

```text
Open queue -> see what needs attention -> inspect one item -> approve, review,
repair, merge, or continue.
```

## Product Loop

The essential Palari loop is:

```text
Human intent
  -> AI preparation
    -> bounded work
      -> evidence
        -> review
          -> human decision
            -> outcome and learning
```

Everything in the repo should serve this loop. If a command, file, report, or
status does not help that loop, it should be hidden, simplified, derived, or
removed.

## Default Surface

The default surface should be the Queue.

The Queue answers:

- What needs attention now?
- Why does it matter?
- Who or what should act next?
- Is this safe for an agent?
- Is this waiting on a human?
- Is evidence fresh?
- Is review fresh?
- Is it ready to accept?
- Is it ready to merge?
- What is the exact next command or action?

The Queue should be goal-aware. Work should not appear as isolated tickets
floating in space. It should be grouped or annotated by goal, decision,
workflow, owner, risk, and next action.

## Main Surfaces

### Queue

The operational home. It shows work by attention state:

- needs routing
- ready for agent work
- active
- blocked
- needs evidence
- needs review
- changes requested
- accept-ready
- ready to merge
- stale or dirty
- needs human decision

The Queue is a read model. It should not secretly mutate state.

### Work Item Detail

One coherent view of one scoped unit of work.

It should assemble:

- intent
- goal linkage
- risk
- scope
- branch
- attempt/worktree
- changed files
- evidence runs
- review verdict
- acceptance requirement
- merge readiness
- timeline
- next action

The operator should not need to open five files to answer whether work is
ready.

### Evidence Runs

Evidence should be modeled as runs tied to a head SHA.

Each run should clearly show:

- commands run
- pass/fail/skip state
- timestamp
- head SHA
- base ref
- artifacts
- summary
- whether it is still fresh

Evidence is proof, not prose.

### Review

Review should be smaller and more real.

A review should contain:

- reviewed head
- reviewer identity
- findings
- severity
- checks inspected
- verdict
- residual risk

The verdict should be easy to reason about:

- accept-ready
- changes requested
- needs human decision
- blocked

Long reviewer notes are optional. Findings and verdict are not.

### Decisions

Decisions are the main way AI asks humans for judgment.

They should be more visible than they are today. A decision should include:

- the question
- options
- tradeoffs
- recommendation
- safe default
- respond-by date if relevant
- linked goal or work item

Decisions should not be hidden inside chat, reports, or ticket prose.

### Goals

Goals are founder/company intent.

They should remain first-class and should shape the Queue. Palari should make
unlinked work visible without making every small maintenance task painful.

### History

History should let a fresh agent or human resume without chat archaeology.

It should show:

- created
- routed
- claimed or attempted
- commits
- evidence runs
- review verdicts
- repairs
- acceptance
- merge
- cleanup

History should be concise. It exists to answer "what happened?" and "where do
we resume?"

### Admin

Admin is where complex governance state belongs.

It should show:

- config
- active humans
- authority/quorum
- policies
- broker state
- model routing
- worktree base
- branch/worktree cleanup candidates
- local machine diagnostics

Admin should make dangerous actions explicit. It should not mix daily work
with governance configuration.

### External Maintainer Mode

External Maintainer Mode is for Palari Orchestrator itself.

It exists because Palari cannot always repair its own ticket, evidence, or
worktree machinery by going through the full version of that machinery.

It allows:

- normal git branch
- bounded code change
- focused tests
- plain engineering summary
- GitHub PR and checks

It does not allow:

- bypassing human authority for high-risk work
- quiet policy or acceptance changes
- secrets, deploy, runtime, or production changes without explicit approval
- replacing the governed workflow for normal product/company work

This mode should be documented and supported, not left as an informal loophole.

## Adaptive Intensity

Palari should not force every task into the same amount of ceremony.

The amount of structure should depend on:

- risk
- ambiguity
- blast radius
- external side effects
- production/deploy impact
- authority changes
- policy or broker impact
- number of people/teams affected
- model capability
- prior outcomes for similar work

Default intensity levels:

### Light

For clear, low-risk maintenance.

Expected proof:

- clear scope
- normal branch
- focused tests
- concise summary
- PR/checks if merging to protected main

### Standard

For normal governed work.

Expected proof:

- scoped work item
- branch/work isolation
- evidence run
- review verdict
- human acceptance if required
- merge readiness check

### High

For production, security, policy, broker, R5, external side effects, or
cross-team authority changes.

Expected proof:

- explicit goal/decision linkage
- stronger scope checks
- fresh evidence
- fresh review
- human quorum
- fail-closed acceptance
- clear residual-risk statement

The user should not have to constantly choose intensity. Palari should
recommend it and explain why. Humans can always raise intensity.

## Model Capability Should Matter

Palari should not over-break work into subtickets just because earlier models
needed smaller tasks.

If a more capable model can safely complete a larger task from:

- a clear goal
- explicit boundaries
- known risks
- verification expectations
- a defined acceptance target

then Palari should allow a larger work item.

Splitting should happen when it improves safety, reviewability, or ownership.
It should not happen as ritual.

## Team Compatibility

The new Palari must work for more than one founder and one agent.

It should support:

- multiple humans
- multiple teams
- multiple AI roles
- shared standards
- shared memory
- shared decisions
- different authority levels
- different review responsibilities
- cross-repo or cross-function work
- capacity and governance-load planning

Human profiles and AI roles must remain distinct:

- Humans own authority, accountability, taste, risk, and final judgment.
- AI roles prepare, draft, inspect, execute bounded work, and propose
  decisions.

Palari's advantage is coordinating these roles without confusing capability
for authority.

## Source Of Truth

Repo artifacts remain the source of truth.

Memory and chat are context, not authority.

Generated views are projections, not hidden state.

Mutation requires explicit commands.

Acceptance, push, merge, deploy, policy activation, broker side effects, and
secrets remain separate explicit actions.

## What To Simplify First

The first redesign phase should avoid changing deep lifecycle semantics.

Start by creating a better read model:

1. A single operator-state JSON shape.
2. A Queue view over that state.
3. A Work Item Detail view over that state.
4. Clear Evidence Run and Review Verdict summaries.
5. External Maintainer Mode documentation.

This reduces ceremony without weakening the authority model.

## Non-Goals

The redesign should not:

- turn Palari into a generic issue tracker
- remove human authority
- make policy simulation real authority
- enable broker side effects casually
- hide evidence failures
- make dashboards authoritative mutation surfaces
- require every small task to become a stack of subtickets
- make external maintainer mode a loophole for risky work
- replace repo artifacts with chat memory

## Design Standard

The new Palari should feel:

- clear
- strict where it matters
- light where it is safe
- honest about uncertainty
- fast to reorient after context compaction
- comfortable for one founder today
- expandable to a team tomorrow

The product test is simple:

```text
Can a human understand what matters, what happened, what is safe, what needs
judgment, and what to do next without reading the whole repo?
```

If yes, Palari is becoming the right thing.
