# Human Governance Load Contract

Human Governance Load, or HGL, estimates how much human judgment a workflow
needs before Palari can safely proceed. HGL is a planning signal. It does not
grant authority, accept tickets, move workflows, activate policies, run agents,
or perform side effects.

## Inputs

HGL reads repo-native artifacts only:

- workflow `expected_decisions` entries from `workflows/proposed`,
  `workflows/active`, and `workflows/closed`
- active human governance profiles from `humans/active`

The scorer treats folder state and frontmatter as the source of truth. Missing
directories or missing artifacts must fail closed or return empty coverage, not
invent authority.

## Commands

```bash
palari burden score WF-ID
palari burden score WF-ID --json
palari human coverage WF-ID
palari human coverage WF-ID --json
```

All commands are read-only. They may print text or JSON, but they must not
mutate tickets, workflows, human profiles, policies, broker evidence, git refs,
credentials, runtime state, or external systems.

## Scoring Formula

Each expected decision receives a deterministic score:

```text
ceil(
  risk_weight
  * novelty_weight
  * ambiguity_weight
  * irreversibility_weight
  * context_weight
  * skill_scarcity_weight
  / evidence_quality_factor
)
```

Initial risk weights:

```text
R0 = 0
R1 = 0.25
R2 = 1
R3 = 3
R4 = 8
R5 = 20
```

Initial attribute weights:

```text
novelty: low 0.8, medium 1.0, high 1.5
ambiguity: low 0.8, medium 1.0, high 1.5
irreversibility: low 0.7, medium 1.0, high 1.7
context: low 0.8, medium 1.0, high 1.4
evidence: none_or_unknown 1.25, weak 1.15, normal 1.0, strong 0.8
```

Skill scarcity starts simple:

```text
covered_by_two_or_more = 0.8
covered_by_one = 1.0
missing_or_underleveled = 1.8
```

The exact formula is intentionally conservative and explainable. Its value is
making human judgment visible, not pretending to be mathematically complete.

## Coverage

A skill is covered when at least one active human profile has the required
skill at the required level or higher. Coverage output should show:

- required skills and levels
- missing or underleveled skills
- humans and roles that cover each required skill when available
- bottleneck roles when only one covering human is available

Human profiles model governance coverage. They are not employee productivity
records and do not grant agent execution authority.

## Launch Gates And Autonomy Ceilings

The first scorer uses conservative gates:

- red when required R3/R4/R5 skills are missing or underleveled
- red when an R5 decision lacks L5 coverage
- yellow when R3/R4 coverage exists but only one qualified human covers a
  required skill
- yellow when total HGL exceeds declared active human weekly capacity
- green when required coverage exists and capacity pressure is not detected

Autonomy ceiling follows the gate and risk shape:

- red workflows are `simulation_only`
- R4 or R5 workflows are `human_led`
- R3 workflows are `conditional_autonomy`
- R2 workflows are `high_autonomy`
- R0/R1-only workflows are `full_autonomy`

Future planner tickets may add richer explanations, but this contract keeps
the first scorer deterministic and fail-closed.

## Non-Goals

HGL scoring does not implement:

- workflow plan generation
- policy simulation or policy acceptance
- broker execution
- external system writes
- credential handling
- autonomous acceptance
- employee surveillance
