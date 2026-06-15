# Workflow Planning

`palari workflow plan WF-ID` is a read-only planning surface above tickets. It
combines a workflow artifact with Human Governance Load scoring so operators
can see what AI may prepare, which modes remain blocked, which human skills are
needed, and why the workflow has its current launch gate.

The command does not claim tickets, create worktrees, run agents, accept work,
activate policies, write broker evidence, push, merge, deploy, or call external
systems.

## Inputs

The planner reads:

- a workflow from `workflows/proposed`, `workflows/active`, or
  `workflows/closed`
- active human governance profiles from `humans/active`
- the deterministic HGL scorer under `adapters/planning/`

## Output

The text and JSON output include:

- workflow id, title, goal, status, and risk ceiling
- launch gate
- autonomy ceiling
- AI modes that can proceed
- modes AI must not enter
- Human Governance Load
- R0-R5 expected-decision counts
- required skills and coverage
- missing skills and bottlenecks
- recommended next actions

## Conservative Semantics

Red workflows are limited to research-mode planning. Yellow workflows remain
constrained and should preserve explicit human gates for R3/R4/R5 decisions.
R4 or R5 workflows remain human-led even when coverage exists.

Future tickets may add richer planning recommendations or connect planner
state to snapshots. This ticket keeps the command deterministic and
side-effect-free.
