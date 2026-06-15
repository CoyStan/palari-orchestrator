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

Optional metric and governance-impact fields may be present:

- `metric_name`
- `metric_before`, `metric_after`, `metric_delta`
- `risk_predicted`, `risk_actual`
- `hgl_predicted`, `hgl_actual`
- `human_decisions_predicted`, `human_decisions_actual`
- `review_outcome`: `passed`, `failed`, `overridden`, or `uncertain`
- `rollback_used`: `true` or `false`
- `policy_candidate`: `true` or `false`
- `notes`

When present, lint validates risks, integer governance counts, decimal metric
values, booleans, and review outcome labels. These fields are learning signals
only. They do not change HGL weights, activate policies, accept work, or grant
authority.

Recorded outcome impact fields may feed read-only calibration reports such as
`palari burden calibrate`. Those reports are advisory: they can show where HGL,
risk estimates, evidence patterns, or simulation-only policy candidates deserve
human review, but they must not update governance weights or policy state
without a separate human-approved change.

## References

Outcome lint checks linked workflow, goal, ticket, decision, and evidence paths
when present. Missing references fail closed so future policy/HGL learning does
not rest on invisible evidence.
