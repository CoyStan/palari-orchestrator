# Workflow Artifacts

Workflows are the planning unit above tickets. A workflow represents a company
or business process, not a single coding task. Tickets remain the scoped
implementation unit beneath workflows.

Workflows do not grant authority. They make the plan, risk ceiling, expected
human decisions, and allowed/forbidden modes visible before execution.

## Directories

```text
workflows/proposed/
workflows/active/
workflows/closed/
```

Agents may propose workflow artifacts. A human adopts a proposed workflow into
`workflows/active`. A human closes an active workflow as achieved or dropped.

## Frontmatter

Workflow frontmatter uses flat keys and pipe-delimited lists so Palari's Bash
parser can validate it deterministically.

Important fields:

- `id`: `WF-0001`
- `status`: `proposed`, `active`, or `closed`
- `goal`: linked `GOAL-0001`
- `owner`: accountable human or team label
- `risk_ceiling`: one of Palari's risk tiers, including R5
- `autonomy_target`: intended autonomy posture
- `work_units`: `WU-0001|kind|RISK|Title`
- `expected_decisions`: `RISK|kind|skill:Lx|Title`
- `allowed_modes`: modes AI may prepare
- `forbidden_modes`: modes AI must not enter

R3/R4/R5 expected decisions must name at least one `skill:Lx` requirement.

Risk source rules:

- `risk_ceiling`, every `work_units` risk, and every `expected_decisions` risk
  contribute to the workflow's maximum declared risk.
- R4/R5 work units must have an expected human decision at or above that risk.
- R3 work units without a matching expected decision produce a visible lint
  warning unless the workflow documents a human decision exception.
- A workflow with an R5 ceiling or R5 work unit must not be planned as high or
  full autonomy just because expected decisions are empty.

## CLI

```bash
palari workflow create WF-0001 "Improve onboarding" --goal GOAL-0100 --owner founder
palari workflow list
palari workflow show WF-0001
palari workflow plan WF-0001
palari workflow plan WF-0001 --json
palari workflow lint
palari workflow adopt WF-0001 --by founder
palari workflow close WF-0001 --by founder --status achieved
```

`workflow create` writes proposed workflows. Adoption is explicit human
bookkeeping and does not create tickets, run agents, accept work, push, merge,
deploy, or perform external side effects.

`workflow plan` is also read-only. It combines workflow fields with Human
Governance Load and active human coverage so an operator can inspect launch
gate, autonomy ceiling, allowed modes, blocked modes, required skills, missing
skills, bottlenecks, and recommended next actions before tickets are created or
executed.

## Lint Rules

Workflow lint checks:

- valid workflow id
- valid status and directory match
- linked goal exists
- valid `risk_ceiling`
- valid work unit pipe format and risk
- valid expected-decision risk
- R3/R4/R5 expected decisions include at least one `skill:Lx`
- R4/R5 work units have expected decisions at or above the work-unit risk
- R3 work units without expected decisions are called out as warnings unless
  an exception is documented
- frontmatter remains YAML-safe

## Non-Authority

Workflow artifacts are planning records. They do not widen ticket scopes, raise
role authority, bypass review, satisfy human approval, or change acceptance
requirements.
