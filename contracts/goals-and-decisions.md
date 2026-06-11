# Goals And Decisions

This contract defines the two artifacts that close the loop between a human
who sets direction and agents that self-organize inside it: goals (intent in)
and decisions (judgment out). The repository remains the source of truth for
both.

## Goals

A goal is a first-class repo artifact under `goals/active`, `goals/proposed`,
or `goals/closed`. It carries an id (`GOAL-0001`), an owner, success
criteria, an optional due date, and an optional parent goal.

Rules:

- Goals make intent machine-readable. They never grant authority. A goal can
  not widen allowed paths, raise risk ceilings, or substitute for a role.
- Proposals and tickets link to a goal with `serves_goal: GOAL-ID`. The link
  is how "why is this the next ticket" becomes answerable from repo state.
- `require_serves_goal` in `palari.config.yaml` controls enforcement: `off`,
  `warn` (default; lint warns on unlinked active tickets), or `strict`
  (ticket creation without `--goal` fails).
- Agents may propose goals (`palari goal create ... --proposed`). Only a
  human adopts (`goal adopt --by NAME`), achieves, or drops a goal.
- The queue runner uses goals to filter and prioritize. Work serving no goal
  is legal under `warn` but should be the exception, not the norm.

## Decisions

A decision is the structured artifact an agent brings to the human instead of
a vague `needs-human` ticket. It lives under `decisions/open` until a human
records it, then moves to `decisions/decided` and is mirrored into
`memory/decisions/` so future packets can cite it.

A well-formed decision contains:

- one question, stated in a single sentence,
- two or more options, each with explicit tradeoffs,
- a recommended option with a short evidence-backed rationale,
- a respond-by date,
- an explicit default: either a safe option that proceeds, or "linked work
  pauses".

Rules:

- Agents draft decisions. Only a human records an outcome
  (`palari decide record DEC-ID --choice N --by NAME`).
- The default option may never include accept, merge, push, deploy, spend,
  credential creation, production access, or any other human-gated action.
  Defaults exist to keep low-risk work moving, not to launder authority.
- Open decisions are stop items: they surface at the top of
  `palari run --dry-run` output and in the snapshot operator inbox, ahead of
  all plannable work.
- A decision with one option is a notification, not a decision; the tooling
  rejects it.

## Claim Lease Honesty

Ticket claims use short git-ref leases with heartbeats. This works for one
operator and a small number of executors sharing one machine or one remote.
Git refs do not provide cross-machine atomicity: two executors racing the
same remote can, in rare interleavings, both believe they hold a claim. Treat
the lease as a coordination convention, not a lock. For multi-machine fleets,
route claims through a single orchestrator process, and keep
`scope_overlap_policy: block` so a lost race is caught at scope-check rather
than at merge.
