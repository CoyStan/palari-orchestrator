# Human Governance Profiles

Human governance profiles model decision coverage, skills, authority ceilings,
capacity, and constraints. They are not employee surveillance, task tracking,
or a way to grant agents authority.

Profiles live under:

```text
humans/proposed/
humans/active/
humans/revoked/
```

Agents may propose profiles. A human adopts a proposed profile into active use
and may revoke an active profile when it no longer describes the governance
boundary.

## Frontmatter

Important fields:

- `id`: `HUMAN-ALICE` or `HUMAN-0001`
- `name`: human-readable name
- `status`: `proposed`, `active`, or `revoked`
- `roles`: governance roles such as `product_governor`
- `skills`: `skill:L1` through `skill:L5`
- `authority_max_risk`: one of Palari's risk tiers
- `weekly_hgl_budget`: approximate weekly Human Governance Load capacity
- `current_weekly_hgl`: currently open estimated HGL for that human
- `max_concurrent_r3`, `max_concurrent_r4`, `max_concurrent_r5`: concurrent
  high-risk decision capacity by risk tier
- `current_open_r3`, `current_open_r4`, `current_open_r5`: currently open
  high-risk decision counts by risk tier
- `capacity_weekly_hgl`, `capacity_open_r3`, `capacity_open_r4`,
  `capacity_open_r5`: legacy compatibility fields from early profile versions;
  new profiles should prefer the operational fields above
- `constraints`: free-form limits such as `cannot_self_review_own_work`

R5 authority requires `may_approve_policy_changes: true`. That flag only makes
the profile lintable; it does not bypass ticket, evidence, review, or
acceptance gates.

For R5 ticket acceptance, an active human profile is also the authority source.
When `governance.r5_requires_dual_human: true`, `palari accept` requires
`--by HUMAN-ONE --co-by HUMAN-TWO`; both profiles must be active, distinct,
authorized to R5, and allowed to approve policy/governance changes. Neither
human may be the ticket claimant or implementer.

Human Governance Load coverage requires skill, authority, and available
risk-specific capacity. Skill alone is insufficient: a human with
`privacy:L5` and `authority_max_risk: R2` cannot cover an R5 privacy decision.

Capacity constraints are linted:

- `current_weekly_hgl` must not exceed `weekly_hgl_budget`
- `current_open_r3` must not exceed `max_concurrent_r3`
- `current_open_r4` must not exceed `max_concurrent_r4`
- `current_open_r5` must not exceed `max_concurrent_r5`

Workflow planning treats available weekly HGL as
`weekly_hgl_budget - current_weekly_hgl`. A workflow whose estimated HGL exceeds
available weekly capacity must not look launch-ready.

## CLI

```bash
palari human create HUMAN-ALICE Alice --skill product_strategy:L5 --role product_governor --capacity-hgl 60
palari human list
palari human show HUMAN-ALICE
palari human lint
palari human adopt HUMAN-ALICE --by founder
palari human revoke HUMAN-ALICE --by founder
palari human org-plan
palari human org-plan --json
```

`human org-plan` is a read-only planner for the minimum viable human company
needed by active workflows. It derives required roles and skills from workflow
expected decisions, reports missing or thin coverage, and calls out
concentration risk when one human covers too much high-risk governance. It
does not create profiles, adopt humans, change capacity, accept work, or grant
agent authority.

## Non-Authority

Human profiles do not create agent identities, grant executor permissions, or
authorize lifecycle mutation. They are inputs for later Human Governance Load
coverage and planning.
