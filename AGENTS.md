# Palari Orchestration Agent Template

Use this file as the adopting repository's agent operating contract.

Core spine:

```text
packet-first
git-true
risk-tiered
reviewed-before-accepted
repo-is-law
```

The repository is authoritative for tickets, reports, product docs, and git
state. Chat memory, external notes, and delegated summaries are advisory when
they conflict with repo files.

## Role Authority

- Human/founder: owns product judgment, risk acceptance, and final direction.
  Only the human/founder or an explicitly authorized reviewer may accept work.
- Orchestrator: selects or creates tickets, runs clean/context gates, prepares
  worktrees, emits packets, routes specialists/reviewers, and integrates
  evidence.
- Specialist: executes one bounded ticket inside allowed paths, verifies work,
  writes a technical report, and moves ready work to `in-review`.
- Reviewer: reviews with fresh context. Checks correctness, scope,
  verification, completion contract, and regression risk. Does not implement
  fixes by default.
- Product-feel reviewer: where applicable, reviews rendered UI, copy, workflow
  clarity, and capability-boundary honesty from fresh context.
- Mediator: frames options when scope, access, authority, or risk blocks work.

## Ticket Workflow

1. Refresh repository state with `git status --short --branch` and
   `palari status`.
2. Create or select a ticket with risk, allowed paths, forbidden paths,
   verification, review gates, and human gates.
3. Commit accepted ticket setup before creating the worktree.
4. Run `palari worktree TICKET-ID`.
5. Generate packets with `palari packet TICKET-ID specialist` and, when ready,
   `palari packet TICKET-ID reviewer`.
6. Execute only inside ticket scope. Stop on missing authority, forbidden paths,
   higher real risk, secrets, production, live services, deploys, Docker,
   database mutation, destructive commands, or unclear acceptance criteria.
7. Record evidence in reports and run `palari scope-check TICKET-ID`.
8. Move implementation to `in-review`. Acceptance remains a separate human or
   authorized-reviewer gate.

## Fast Lane And Governed Lane

Use a compact gate for R0/R1 read/check/coordination or tiny exact edits:

```text
Authority:
Refresh:
Context:
```

Use the governed lane for R2+, visible UI/runtime work, source-of-truth changes,
process authority, broad edits, review-required work, or human-confirmation
work. Governed work needs a ticket, packet, verification, report evidence, and
review before acceptance.

## Closeout

Meaningful closeout should say:

```text
What changed
What did not change
Verification
Changed paths
Risks / follow-ups
Next action
```
