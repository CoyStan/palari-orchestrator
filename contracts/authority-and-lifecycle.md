# Authority And Lifecycle Contract

Palari distinguishes work completion from authority to declare completion.

## Authority Profiles

The default profile is `team-safe`.

- `team-safe`: agents may prepare work on branches and PRs, but may not merge main or accept tickets.
- `solo-founder`: agents may merge main when the founder has chosen that posture; ticket acceptance still requires an explicit user instruction.
- `strict`: agents may not commit, push, open PRs, merge main, or accept tickets autonomously.

Profiles are configured in `palari.config.yaml` and inspected with:

```bash
palari authority
palari authority check merge-main
```

This contract informs packets, wrappers, reviews, and human expectations. It is
not a replacement for GitHub branch protection or required checks.

## Repo Roles

Roles are optional repo-native authority artifacts under:

```text
roles/active/
roles/proposed/
roles/revoked/
```

Roles are local-mode authority artifacts. Signed provenance is not enforced in
v1.

A role may define responsibilities, allowed paths, forbidden paths, maximum
risk, delegation authority, ticket creation authority, review authority, and
escalation rules.

Authority must only narrow:

```text
parent role authority >= child role authority >= ticket authority
```

`palari role lint` and role-issued ticket creation enforce the v1 rule:

- active parent role is required
- child allowed paths must be contained in parent allowed paths
- child forbidden paths must preserve parent forbidden paths
- child risk above parent `max_risk` escalates
- child role tier must equal parent tier plus one
- unknown path containment escalates instead of silently accepting
- forbidden or invalid grants are rejected

Agents execute roles. Agents do not become authority sources, activate new
roles, accept tickets, or bypass the ticket/evidence/review spine.

## Lifecycle Visibility

Open tickets are not automatically wrong. Hidden state is wrong.

Every repo should be able to answer:

- which tickets are active
- which ticket is claimed, blocked, waiting for review, or waiting for a human
- what command or decision is next
- whether acceptance happened on the repository source of truth

Use:

```bash
palari status --next
palari doctor lifecycle
palari ticket audit
```

Ticket implementation, evidence creation, review, acceptance, push, PR merge,
and deployment are separate actions. A ticket should not be treated as closed
until `palari accept` has moved it to the closed ticket directory on the branch
that will become the repository source of truth.

## Stable Human Identity

Acceptance compares stable actor identity, not display labels.

Human profiles may declare:

```yaml
person_id: PERSON-ALICE
aliases:
  - founder
  - admin
```

If `person_id` is absent, Palari derives identity from the human profile ID.
Aliases let common operator labels resolve to the same person. They do not
create new authority. During acceptance, `--by` and `--co-by` values that map to
the same stable person cannot satisfy self-acceptance or quorum separation.
