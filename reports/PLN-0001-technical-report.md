# PLN-0001 Technical Report

## Files Changed

- `adapters/planning/workflow_plan.py`
  - Adds a stdlib, read-only workflow planner that imports the HGL scorer,
    reads workflow artifacts and active human profiles, and emits text or JSON.
- `lib/palari/workflows.bash`
  - Adds `palari workflow plan WF-ID [--json]` and wires the planner adapter.
- `bin/palari`
  - Adds the workflow plan usage line.
- `tests/run-workflow-planning.sh`
  - Covers text output, JSON output, yellow gate behavior, red gate behavior,
    recommended next actions, and non-mutation.
- `contracts/workflows.md`
  - Documents `workflow plan` as a read-only planning command.
- `docs/autonomy/workflow-planning.md`
  - Documents planner inputs, outputs, conservative semantics, and non-goals.
- `STATE.md`, `CHANGELOG.md`
  - Record the shipped workflow planning capability.
- `tickets/open/PLN-0001-add-workflow-planning-and-autonomy-ceiling.md`
  - Replaces the generated body with the scoped completion contract.

## Verification

Passed during implementation:

- `./tests/run-workflow-planning.sh`
- `./tests/run-queue-dry-run.sh`
- `./tests/run-human-governance-load.sh`
- `./tests/run-cli-structure.sh`
- `python3 -m py_compile adapters/planning/workflow_plan.py adapters/planning/hgl.py`
- `bash -n lib/palari/workflows.bash`

## CI Evidence

Pending final gate evidence:

- `./bin/palari lint PLN-0001`
- `./bin/palari report-lint PLN-0001`
- `./bin/palari scope-check PLN-0001`
- `git diff --check`
- `./bin/palari ci PLN-0001 --base ticket/HGL-0001`

## Risks / Follow-Ups

- The planner is intentionally explanatory and conservative. It does not create
  tickets, spawn agents, or execute work.
- `palari run --dry-run` semantics are unchanged in this slice. Future tickets
  can decide whether to cross-link workflows into the queue runner.
- Snapshot/dashboard visibility remains out of scope until SNP-0001 and
  DSH-0001.
