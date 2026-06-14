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
- `capacity_weekly_hgl`: approximate weekly Human Governance Load capacity
- `capacity_open_r3`, `capacity_open_r4`, `capacity_open_r5`: rough concurrent
  decision capacity
- `constraints`: free-form limits such as `cannot_self_review_own_work`

R5 authority requires `may_approve_policy_changes: true`. That flag only makes
the profile lintable; it does not bypass ticket, evidence, review, or
acceptance gates.

## CLI

```bash
palari human create HUMAN-ALICE Alice --skill product_strategy:L5 --role product_governor --capacity-hgl 60
palari human list
palari human show HUMAN-ALICE
palari human lint
palari human adopt HUMAN-ALICE --by founder
palari human revoke HUMAN-ALICE --by founder
```

## Non-Authority

Human profiles do not create agent identities, grant executor permissions, or
authorize lifecycle mutation. They are inputs for later Human Governance Load
coverage and planning.
