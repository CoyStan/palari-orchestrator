# Retrospective Governance

Retrospective governance is an audit-backfill lifecycle for work that already
landed before normal Palari governance controlled it.

It is not proof that the work was pre-governed. A retrospective ticket must make
that boundary visible to operators, reviewers, and future maintainers.

## Required Metadata

A retrospective ticket sets:

- `retrospective: true`
- `retrospective_original_commits`, with at least one original landed commit SHA
- `retrospective_bypass_reason`, explaining why normal governance was bypassed

The ticket may also use `lifecycle: retrospective` or
`lifecycle: audit-backfill`; those labels are treated as retrospective for
read-model purposes.

## High-Risk Rule

For `R3`, `R4`, and `R5` retrospective tickets:

- `requires_review` must remain `true`
- `requires_human_confirmation` must remain `true`
- report lint must see the same technical, reviewer, and human/founder evidence
  expected for high-risk work

High-risk retrospective work must fail closed if it tries to hide missing review
or founder evidence.

## Visibility

Packets and snapshots expose retrospective state, original commit references,
and bypass reason so normal accepted tickets remain distinguishable from
audit-backfilled tickets.

## Non-Goals

This lifecycle does not automatically backfill historical tickets, accept work,
merge branches, push remotes, or weaken normal ticket lifecycle gates.
