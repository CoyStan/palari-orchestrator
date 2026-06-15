# Human Governance Load Contract

Human Governance Load, or HGL, estimates how much human judgment a workflow
needs before Palari can safely proceed. HGL is a planning signal. It does not
grant authority, accept tickets, move workflows, activate policies, run agents,
or perform side effects.

## Inputs

HGL reads repo-native artifacts only:

- workflow `expected_decisions` entries from `workflows/proposed`,
  `workflows/active`, and `workflows/closed`
- workflow `risk_ceiling` and `work_units` risk declarations from the same
  artifacts
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
  * evidence_quality_factor
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

Evidence quality is multiplicative:

- strong evidence lowers HGL
- normal evidence is neutral
- weak evidence raises HGL
- none or unknown evidence raises HGL the most

Unknown evidence labels default to the neutral `normal` factor so scoring stays
deterministic while lint remains a separate concern.

Skill scarcity starts simple:

```text
covered_by_two_or_more = 0.8
covered_by_one = 1.0
missing_or_underleveled = 1.8
```

The exact formula is intentionally conservative and explainable. Its value is
making human judgment visible, not pretending to be mathematically complete.

## Coverage

A decision skill is covered when at least one active human profile satisfies
all coverage checks:

- the human has the required skill at the required level or higher
- `authority_max_risk` is greater than or equal to the decision risk
- the human has remaining risk-specific capacity for R3/R4/R5 decisions
- for R5 decisions, `may_approve_policy_changes: true`

Coverage must fail closed for serious work. A `privacy:L5` human with
`authority_max_risk: R2` does not cover an R5 privacy decision. An R5-authorized
human without `may_approve_policy_changes: true` also does not cover an R5
decision.

Coverage output should show:

- required skills and levels
- missing or underleveled skills
- under-authorized humans who have the skill but not the decision authority
- humans who are otherwise qualified but at risk-specific capacity
- humans and roles that cover each required skill when available
- bottleneck roles when only one covering human is available
- coverage failure reasons in text output and JSON

Workflow planning derives a human decision map from this coverage data. Each
decision-map entry should expose the decision risk, kind, title, per-decision
HGL score, required skills, eligible humans, coverage status, and a short list
of reasons human judgment is required. R5 entries must explicitly remain
human-governed and must not imply policy acceptance can satisfy the decision.

`palari burden debt` reports Human Governance Debt across active workflows. It
is a read-only operator report for missing skill coverage, high-risk bottlenecks,
capacity pressure, weak evidence, policy-candidate opportunities, and R5
dual-human coverage gaps. The report may summarize a highest-leverage fix, but
it must not mutate humans, workflows, policies, tickets, outcomes, or weights.
It is governance capacity planning, not productivity tracking.

Human profiles model governance coverage. They are not employee productivity
records and do not grant agent execution authority.

## Launch Gates And Autonomy Ceilings

The first scorer uses conservative gates:

- red when required R3/R4/R5 skills are missing or underleveled
- red when an R5 decision lacks L5 coverage
- red when an R4/R5 workflow risk ceiling or work unit lacks an expected human
  decision at or above that risk
- yellow when an R3 risk source lacks an expected human decision and no
  exception is documented
- yellow when R3/R4 coverage exists but only one qualified human covers a
  required skill
- yellow when total HGL exceeds declared active human weekly capacity
- green when required coverage exists and capacity pressure is not detected

Autonomy ceiling follows the gate and risk shape:

- red workflows are `simulation_only`
- R5 workflows are `simulation_only` unless explicitly human-led with R5 human
  decision coverage
- R4 workflows are `human_led` or `simulation_only`, never high/full autonomy
- R3 workflows are `conditional_autonomy`
- R2 workflows are `high_autonomy`
- R0/R1-only workflows are `full_autonomy`

Scoring and planning output include `risk_sources` so humans can see whether
the maximum risk came from workflow ceiling, work units, expected decisions, or
some combination of them.

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
