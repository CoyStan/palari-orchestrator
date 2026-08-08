# Palari Orchestrator Redesign Session

Status: active working note for founder + Codex discussion. This is not an
approved implementation plan, not a Palari ticket, and not a governance
artifact. It exists so we can decide slowly and avoid redesigning away the
parts of Palari that matter.

## Goal

Redesign Palari Orchestrator so it feels like a clear company AI operating
system instead of a pile of ceremony.

The redesign should:

- preserve human authority, explicit intent, bounded AI work, evidence, review,
  and fail-closed gates
- remove or hide ritual that does not help the operator make a safer decision
- scale ceremony to the task's risk, ambiguity, and model capability instead
  of forcing every task into many small tickets
- make the next action obvious
- make internal Palari repairs possible without recursive bureaucracy
- remain compatible with future team use: multiple people, shared memory,
  shared standards, explicit ownership, and role-based authority
- keep repo files inspectable, but stop making humans read every file to know
  what is happening

## Working Principle

Palari should not be optimized for "more tickets." It should be optimized for:

```text
Human intent -> AI preparation -> bounded work -> evidence -> review -> human decision -> learning
```

Tickets are useful only insofar as they serve that loop.

## Adaptive Intensity

Palari should not assume every task needs the same amount of breakdown.

If a stronger model can safely complete a larger task from clear goals, scope,
constraints, and verification expectations, Palari should allow that. The
system should not over-split work just to satisfy ceremony.

Intensity should self-adjust from signals such as:

- risk level
- blast radius
- ambiguity
- affected authority surfaces
- external side effects
- deployment or production impact
- model capability and reliability
- prior outcomes for similar work
- whether the work crosses team or ownership boundaries

Possible operator-facing modes:

- Light: ordinary internal maintenance with clear scope and focused tests.
- Standard: normal governed work with evidence and review.
- High: sensitive, cross-boundary, production, policy, broker, security, or R5
  work with stronger gates and human quorum.

The user should not have to constantly choose this. Palari should recommend an
intensity and explain why, while still letting humans override upward or choose
a simpler external-maintainer path when appropriate.

## What Must Be Preserved

These are core product primitives, not ceremony:

- Goals: founder/company intent.
- Decisions: explicit human judgment requests.
- Human profiles and authority: humans approve, agents do not.
- AI role packets: agents get bounded context and capability.
- Scoped work units: allowed paths, forbidden paths, risk, verification.
- Work isolation: worktree or equivalent branch isolation for governed work.
- Evidence tied to a commit/head, not just prose.
- Fresh review separated from implementation.
- Human acceptance and quorum.
- Read-only queue/dry-run behavior.
- Fail-closed gates for scope, evidence, review, acceptance, policy, broker,
  push, merge, and deploy.
- Outcomes and memory as learning/context, not authority.

## Future Team Compatibility

The simplification must not make Palari a single-founder-only tool.

Future Palari should still support:

- multiple humans with different authority, skills, capacity, and ownership
- multiple AI roles with bounded capabilities
- shared team standards and reusable policies
- shared memory that cites source artifacts instead of becoming hidden
  authority
- decision records that survive chat history and context compaction
- role-specific packets for specialists, reviewers, maintainers, designers,
  product leads, safety reviewers, and release owners
- work crossing teams, repos, or functions without losing ownership and
  approval boundaries

The simplification target is therefore not "remove governance." It is "make
governance adaptive, legible, and mostly invisible until it matters."

## What Feels Like Ceremony Today

These may still be useful internally, but they should not dominate the operator
experience:

- manually reconciling ticket status, branch status, worktree status, claim
  leases, reports, evidence, reviewer notes, and acceptance readiness
- stale evidence and stale review claims
- long report files when the operator needs one verdict and the findings
- formal Palari ticket workflow for repairing Palari's own ticket/worktree/
  evidence machinery
- requiring founder attention for path/worktree cleanup details
- multiple similar commands that partially answer "what do I do next?"
- treating every small internal maintenance fix like high-risk governed work

## First Redesign Hypothesis

The first useful redesign is not a new lifecycle. It is a clearer operator
surface over the existing lifecycle.

Candidate surfaces:

1. Queue: what needs attention next.
2. Ticket Detail: one coherent view of one work item.
3. Evidence Runs: what was checked, at which head, with what result.
4. Review: findings and verdict, not ritual.
5. History: what happened and where to resume.
6. Admin: humans, config, policy/broker status, local cleanup.
7. External Maintainer Mode: bounded ordinary software maintenance for Palari
   Orchestrator internals.

## Directional Changes To Explore

### 1. Rename Around The Company Loop

Current language is ticket-heavy. Possible user-facing vocabulary:

- Work item instead of ticket, when speaking to operators.
- Run or Attempt instead of claim/worktree session.
- Evidence run instead of evidence bundle.
- Review verdict instead of reviewer note.
- Human decision instead of acceptance bookkeeping.
- Control board or queue instead of dashboard/status sprawl.

Open question: which terms feel clear without hiding the underlying file model?

### 2. Separate Definition From Attempts

Current ticket files carry too much:

- intent/scope
- status
- claim lease
- worktree hints
- acceptance metadata
- report/evidence pointers

Possible target:

- Work item definition: stable intent and boundaries.
- Attempt: branch/worktree/agent/session.
- Evidence run: check results for a head.
- Review verdict: review result for a head.
- Acceptance decision: human approval for a reviewed head.

Open question: do we need new files for these, or can the command/read model
derive most of it from existing files and git?

### 3. Make The Queue The Daily Interface

The queue should answer:

- What needs my attention?
- What is blocked?
- What can an agent safely work on?
- What is ready for review?
- What is ready for human acceptance?
- What is ready to merge?
- What is stale or dirty?

Open question: should the first version be a CLI command, generated Markdown,
JSON for future UI, or all three from the same read model?

### 4. Make Review Smaller And More Real

Review should have:

- reviewed head
- findings
- verdict
- checks inspected
- residual risks

It should not require a long essay when the finding is simple.

Open question: what is the minimum acceptable review for low-risk work?

### 5. Formalize External Maintainer Mode

External maintainer mode should exist because Palari cannot always repair
itself through the machinery being repaired.

It should allow:

- normal branch
- bounded code change
- focused tests
- plain engineering summary
- PR/checks

It should not allow:

- bypassing human authority for product/high-risk work
- secrets/deploy/runtime changes without explicit approval
- quiet changes to governance policy or acceptance gates

Open question: should this be documentation only, or a command such as
`palari maintainer start` that creates a simple branch and checklist?

## First Conversation Questions

1. When you open Palari Orchestrator, what do you want to see first:
   queue, goals, active work, or decisions?
2. Which current artifacts should become mostly invisible unless something
   fails?
3. For low-risk internal maintenance, what is enough proof before merge?
4. Where should the line be between "normal engineering branch" and "full
   governed Palari workflow"?
5. Should "ticket" remain the internal object name, or should the operator
   experience say "work item"?

## Initial Recommendation

Start with a read-model redesign before changing lifecycle semantics.

The safest first implementation later would be:

1. Define a single "operator state" JSON shape.
2. Build a concise `palari queue` or improved `palari status --next` from it.
3. Build one `palari detail ID` view that assembles ticket, branch, worktree,
   evidence, review, and acceptance readiness.
4. Document external maintainer mode clearly.

This would reduce ceremony without weakening the core authority model.
