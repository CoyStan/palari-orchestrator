# Founder Operator Role Proposals

These roles are proposed, not active. They describe a stronger long-running
workflow shape for autonomous founder/operator work without granting authority
until a human adopts them.

## Role Set

- `ROLE-PRODUCT-LEAD`: turns founder intent into ranked tickets, roadmap
  slices, and tradeoffs.
- `ROLE-DESIGN-LEAD`: reviews operator-facing UI for clarity, accessibility,
  hierarchy, mobile behavior, and professional polish.
- `ROLE-QA-LEAD`: plans and runs regression, edge-case, evidence, and release
  readiness checks.
- `ROLE-RELEASE-LEAD`: tracks CI, rulesets, release notes, packaging, and
  external-account blockers.
- `ROLE-AUTONOMY-COORDINATOR`: keeps the autonomous queue moving by creating
  scoped follow-on tickets and stopping at human gates.

## Authority Boundary

All proposed roles keep `may_accept_tickets: false`. They do not merge, push,
deploy, publish, create credentials, touch secrets, or mutate production.

The intended operating pattern is:

1. A human defines a high-level goal.
2. The Product Lead or Autonomy Coordinator creates scoped tickets.
3. Specialist roles execute one ticket at a time.
4. Reviewer roles inspect fresh evidence.
5. A human accepts, reopens, merges, or makes blocked decisions.

## Adoption Notes

Adopt roles only when their allowed paths and escalation rules fit the target
repository. For customer apps, narrow paths to the app's actual source, tests,
docs, release, and design surfaces before adoption.

These roles are intentionally conservative. They make it easier for agents to
continue working for longer, but they do not remove Palari's human gates.
