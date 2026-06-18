# Palari Orchestrator Redesign Target

Status: target-model hypothesis only. This document is not approved
implementation scope. It proposes a direction to review before deciding what
to change.

## Why A Redesign Might Be Needed

Palari Orchestrator has valuable primitives:

- tickets
- path scope
- claims
- worktrees
- evidence bundles
- technical and human reports
- fresh-context reviews
- human acceptance
- branch/merge discipline
- human governance profiles

The problem is not that those primitives are useless. The problem is that the
operator experience can become too heavy. A founder or agent may have to
reconcile ticket status, branch status, worktree status, evidence freshness,
review notes, report lint, claim leases, and acceptance rules before knowing
what to do next.

The redesign target is to make Palari feel more like an operational control
board and less like a filing cabinet.

## Design Principles

- Keep files as inspectable artifacts, but make generated status the working
  interface.
- Separate ticket definition, execution attempts, evidence runs, review
  decisions, and acceptance.
- Prefer one truthful next action over many partial hints.
- Treat evidence as a run tied to a head SHA.
- Treat review as findings plus verdict, not ceremony.
- Keep high-risk governance strong while making low-risk maintenance fast.
- Make context-compaction recovery boring.
- Do not make dashboards authoritative for destructive or governance actions.
- Add external maintainer mode as a deliberate path for Palari Orchestrator
  internals.

## Core Objects

### Ticket

The ticket is the scoped intent:

- id and title
- goal
- risk
- allowed and forbidden paths
- verification expectations
- target branch
- required review / required human confirmation
- lifecycle status

The ticket should not be forced to carry every execution detail forever.

### Execution Attempt

An execution attempt is a concrete work session:

- branch
- worktree
- starting base
- agent/human
- timestamps
- changed files
- commits
- current cleanliness

This helps distinguish "the ticket" from "this attempt to implement it."

### Evidence Run

An evidence run is proof attached to a specific head:

- ticket id
- head SHA
- base ref
- commands
- pass/fail/skip state
- logs
- artifacts
- created timestamp
- generated summary

Evidence freshness should be computed by comparing the evidence head with the
ticket branch or reviewed head.

### Review Decision

A review decision should be structured:

- ticket id
- reviewed head SHA
- reviewer identity
- verdict: accept-ready, request-changes, needs-human, blocked
- findings
- residual risks
- checks inspected

The Markdown reviewer note can remain the human-readable representation, but
the command should be able to reason about the decision.

### Acceptance Decision

Acceptance is a human/governance decision:

- accepted ticket id
- accepted head SHA
- accepting human profile
- optional co-approvers depending on quorum config
- timestamp
- evidence/review references

Acceptance should fail closed if the reviewed/evidence head no longer matches
the branch being accepted.

### Timeline Event

A timeline event records lifecycle facts:

- created
- routed
- claimed
- worktree created
- commit added
- evidence run
- review requested
- review finding
- reopened
- accepted
- merged

This does not need to become a full workflow engine. It only needs enough
truth to let a fresh agent reorient quickly.

## Proposed Surfaces

### 1. Queue

Problem it solves:

The founder and agents need to know what needs attention now without opening
every ticket and report.

Information it should show:

- ticket id and title
- risk
- status
- owner/claim
- branch/worktree summary
- next action
- blocker category
- evidence freshness
- review verdict
- acceptance readiness
- merge readiness

Actions it should support:

- show next command
- filter by ready/blocked/stale/unreviewed/dirty
- inspect ticket detail
- run read-only diagnostics
- optionally generate a safe action plan

Complexity it might simplify:

- `status --next`
- `run --dry-run`
- `ticket audit`
- scattered evidence score checks
- manual branch/worktree reconciliation

Open questions:

- Should this be a CLI table, JSON command, terminal UI, or web dashboard?
- Should queue state be fully derived, or should timeline events contribute?
- How much should it explain versus simply point to the next command?

### 2. Ticket Detail

Problem it solves:

One ticket currently spreads across a ticket file, branch, worktree, reports,
evidence, reviewer note, and git state. The detail surface should assemble
that into one coherent view.

Information it should show:

- ticket definition
- current lifecycle state
- current branch and target branch
- current worktree path
- changed paths
- scope result
- verification expectations
- latest evidence run
- latest review decision
- human acceptance requirement
- mergeability
- timeline summary

Actions it should support:

- create/claim/worktree packet commands in governance mode
- run focused diagnostics
- copy safe next command
- explain why a ticket is blocked
- show stale or missing artifacts

Complexity it might simplify:

- opening ticket/report/evidence/reviewer files manually
- guessing whether `worktree` frontmatter, generated paths, and git worktrees
  agree
- remembering which command to run next after context compaction

Open questions:

- Should ticket detail become a generated Markdown report or a command output?
- Should machine-readable detail be saved to disk?
- Should it include a compact diff summary?

### 3. Checks / Evidence

Problem it solves:

Evidence should prove what ran, where, and against which commit. It should not
feel like paperwork that can go stale silently.

Information it should show:

- evidence runs by recency
- ticket id
- head SHA
- base ref
- commands
- pass/fail status
- skipped checks
- artifacts
- lint/scope/report status
- freshness against current branch head

Actions it should support:

- run focused checks
- rerun failed checks
- score evidence
- explain missing evidence
- archive superseded runs

Complexity it might simplify:

- evidence score ambiguity
- stale evidence claims
- manually reading `verification.log`
- confusing CI artifacts with reviewer approval

Open questions:

- Should evidence be immutable once created?
- Should evidence run ids be separate from ticket ids?
- How should stacked branches report evidence: per ticket, stack head, or both?

### 4. Review

Problem it solves:

Fresh-context review is valuable, but it can become ritual. The review surface
should make findings and verdict explicit.

Information it should show:

- reviewed head SHA
- reviewer identity/model/human
- reviewed scope
- findings by severity
- required fixes
- checks inspected
- residual risks
- verdict

Actions it should support:

- request review
- record review verdict
- reopen from concrete findings
- mark accept-ready for human acceptance
- compare current branch head to reviewed head

Complexity it might simplify:

- long reviewer notes with unclear verdicts
- fake or placeholder reviews
- accept-ready claims that do not match current code

Open questions:

- Should the review note remain freeform Markdown, structured frontmatter, or
  both?
- What is the minimum acceptable review for R1/R2 work?
- When is a second review required?

### 5. History

Problem it solves:

After compaction or a long-running stack, agents need to know what happened
without relying on chat memory.

Information it should show:

- chronological ticket events
- commits
- evidence runs
- reviews
- reopens
- acceptances
- merges
- cleanup actions

Actions it should support:

- show timeline for one ticket
- show stack timeline
- explain why a ticket reopened
- identify the last safe continuation point

Complexity it might simplify:

- reading old chat summaries
- losing track of which evidence was replaced
- confusing old worktrees/branches with current work

Open questions:

- Can history be derived from git commits and files, or does Palari need an
  explicit event log?
- Should event logs be append-only?
- How much history should survive branch cleanup?

### 6. Admin

Problem it solves:

Configuration, humans, policy, and local machine state need one safe place to
inspect and diagnose. They should not be mixed into daily ticket execution.

Information it should show:

- Palari config
- default branch
- worktree base
- active human profiles
- approval quorum
- policy simulation state
- broker/sandbox status
- local worktrees
- stale branches and cleanup candidates

Actions it should support:

- validate config
- list human profiles
- explain acceptance requirements
- inspect worktree base resolution
- run cleanup audits
- show dangerous actions as commands requiring explicit human approval

Complexity it might simplify:

- hidden config assumptions
- worktree base surprises
- repeated branch cleanup audits
- confusion between policy simulation and real acceptance

Open questions:

- Which admin actions should be read-only by default?
- Should destructive cleanup require a separate confirmation token?
- How much local machine state should be committed versus ignored?

### 7. External Maintainer Mode

Problem it solves:

Palari Orchestrator cannot always be safely or efficiently modified through
its own full governance workflow. Building the plane while flying it creates
recursive overhead: tickets for ticket commands, evidence for evidence
commands, worktrees for worktree bugs.

Information it should show:

- current branch
- divergence from origin
- dirty files
- focused changed paths
- tests run
- risks
- whether the branch is ready for normal review

Actions it should support:

- create a normal git branch
- make bounded changes
- run focused tests
- produce a plain engineering summary
- optionally wrap a finished change into Palari governance later

Complexity it might simplify:

- self-referential Palari tickets
- nested worktree failure modes
- evidence/review churn while changing evidence/review code
- excessive latency for small orchestrator repairs

Open questions:

- Should external maintainer mode be documented only, or supported by a
  command?
- Which files are allowed in this mode?
- When must a finished external-maintainer fix be converted into a formal
  Palari ticket before merge?
- How should this mode avoid becoming a loophole around governance?

## Possible Future Status Model

This is a candidate, not a decision.

Primary ticket states:

- proposed
- open
- claimed
- in progress
- in review
- reopened
- accepted
- closed/canceled

Derived operational states:

- needs routing
- needs worktree
- dirty worktree
- scope failed
- checks failed
- evidence stale
- missing review
- changes requested
- accept-ready
- needs human acceptance
- ready to merge
- merged
- cleanup candidate

The primary state should remain simple. The derived state should answer the
operator's next-action question.

## Possible Command Families

This is exploratory naming only:

```bash
./bin/palari queue
./bin/palari ticket detail POS-XXXX
./bin/palari checks POS-XXXX
./bin/palari review status POS-XXXX
./bin/palari history POS-XXXX
./bin/palari admin status
./bin/palari maintainer status
```

The important design question is not the exact command names. It is whether
each command has a clear job and avoids mutating state unless explicitly
intended.

## What This Might Replace Or Reduce

Candidates for simplification:

- repeated manual evidence refresh instructions
- ambiguous "status --next" output when branch/evidence/review disagree
- manual worktree path debugging
- stale reviewer note archaeology
- all-purpose CI runs where focused checks would do
- founder needing to ask "what is safe to accept?"

Things not to remove lightly:

- explicit human acceptance
- path scope checks
- forbidden path rules
- review-gated work for higher risk tickets
- evidence artifacts for real changes
- branch and worktree isolation for normal governed work

## Non-Goals For The First Redesign Decision

- Do not build a web app just because the model has surfaces.
- Do not remove governance gates before replacing them with clearer gates.
- Do not turn policy simulation into real acceptance.
- Do not hide evidence.
- Do not make external maintainer mode the default for product or high-risk
  work.
- Do not add more statuses unless they reduce operator confusion.

## Review Questions Before Implementation

- Which current pain is most expensive: speed, stale evidence, review quality,
  worktree confusion, or acceptance uncertainty?
- Should the first implementation be a single `queue`/`detail` command rather
  than a full redesign?
- What should be the canonical "ready to accept" computation?
- What must be true for external maintainer mode to be safe?
- Which parts of current reports should become generated summaries?
- Should Palari have an append-only event log?
- How should stacked work be represented without recreating nested complexity?

## Suggested Decision Sequence

1. Review the landscape and target model with the current repo in mind.
2. Decide which pain to solve first.
3. Write a narrow architecture decision record.
4. Implement one thin command or doc change that reduces ambiguity.
5. Test it against a real recent failure, such as nested worktrees or stale
   evidence.
6. Only then consider larger UI/dashboard work.

The safest first move is likely not a new dashboard. It is a better computed
answer to: "What exactly needs attention next, and why?"
