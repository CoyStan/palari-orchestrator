# Company AI OS Infrastructure

Palari's Company AI OS layer is a planning and governance surface above
tickets. It helps an operator see the shape of a company workflow before
delegating implementation work to agents.

Palari remains repo-native governance first. The repo is still the source of
truth, evidence still comes before acceptance, and humans still own judgment
and accountability.

## What Exists Now

- Workflows model company or business processes above tickets.
- `palari workflow plan WF-ID` shows launch gate, autonomy ceiling, Human
  Governance Load, allowed modes, blocked modes, missing skills, bottlenecks,
  and recommended next actions.
- Human profiles model governance coverage: skills, roles, capacity, authority
  ceiling, and constraints.
- Policy artifacts and policy candidates are simulation-only.
- Broker evidence is mock/local and reports `real_side_effects_enabled: false`.
- Outcomes record what happened after governed work when evidence is linked.
- `palari demo --company-os` creates a deterministic local fixture that shows
  the whole shape without external services.

## What Does Not Exist Yet

- No silent autonomous acceptance.
- No real broker side effects.
- No hosted service mutation.
- No credential storage in repo artifacts or evidence.
- No replacement for human accountability.
- No claim that Palari has proven safety, productivity, or business impact
  without evidence.

## Operator Loop

```bash
./bin/palari demo --company-os --force
./bin/palari workflow plan WF-9004
./bin/palari human coverage WF-9004
./bin/palari policy candidates
./bin/palari broker evidence DPC-9001
./bin/palari outcome list
./bin/palari snapshot --json
```

The loop is read-mostly and local. The demo writes fixture artifacts so a
founder or operator can inspect them, but it does not run agents, call hosted
APIs, accept tickets, push, merge, or deploy.

## Design Boundary

Company OS artifacts add context and learning around the existing Palari
ticket lifecycle:

```text
Goal -> Workflow -> Tickets / Decisions -> Evidence -> Review -> Acceptance -> Outcome
```

The artifacts do not grant authority by themselves. Future tickets may add
stronger policy acceptance or real broker connectors only after separate
safeguards, explicit human approval, and fail-closed verification exist.
