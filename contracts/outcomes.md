# Outcomes Contract

Outcomes record what happened after governed work.

## Boundary

- Outcomes do not accept work.
- Outcomes do not prove business impact unless evidence is linked.
- Outcomes may inform future Human Governance Load estimates and policy
  candidates, but they do not grant policy authority.

## Artifact Model

Outcome artifacts live under:

- `outcomes/open/`
- `outcomes/recorded/`

Outcome `status` is business status:

- `observed`
- `pending`
- `invalidated`

Outcome `lifecycle` is ledger state:

- `open`
- `recorded`

## References

Outcome lint checks linked workflow, goal, ticket, decision, and evidence paths
when present. Missing references fail closed so future policy/HGL learning does
not rest on invisible evidence.
