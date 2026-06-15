# WFU-0001 Technical Report

## Files Changed

- `lib/palari/workflows.bash`
  - Adds workflow ID validation, file lookup, create/list/show/lint/adopt/close
    commands, and workflow-specific lint rules.
- `bin/palari`
  - Sources the workflow module, advertises workflow commands, and dispatches
    `palari workflow`.
- `lib/palari/core.bash`
  - Adds workflow directory globals and includes `workflows` in adoption paths.
- `lib/palari/init_adopt.bash`
  - Ensures workflow directories exist during init and checks the workflow
    module in doctor.
- `palari.config.yaml` and `schemas/palari.config.schema.json`
  - Add workflow directory config keys.
- `contracts/workflows.md`
  - Documents workflow artifacts, directories, frontmatter, lint rules, and
    non-authority boundaries.
- `templates/workflow.md`
  - Adds a workflow body template.
- `workflows/proposed/.gitkeep`, `workflows/active/.gitkeep`,
  `workflows/closed/.gitkeep`
  - Add the workflow state directories.
- `tests/run-workflows.sh`
  - Covers create/list/show/lint/adopt/close and lint failures.
- `tests/run-cli-structure.sh`
  - Adds `workflows` to the required module list.
- `README.md`, `STATE.md`, `CHANGELOG.md`
  - Document the new workflow artifact family and commands.
- `tickets/open/WFU-0001-add-workflow-artifacts-and-cli.md`
  - Tracks this scoped workflow slice.

## Verification

Passed:

- `./tests/run-workflows.sh`
- `./tests/run-cli-structure.sh`
- `./tests/run-state.sh`
- `./bin/palari lint WFU-0001`
- `./bin/palari report-lint WFU-0001`
- `./bin/palari scope-check WFU-0001`
- `git diff --check`

## CI Evidence

Passed with `./bin/palari ci WFU-0001 --base ticket/COS-0001`.

Evidence bundle:

- `reports/evidence/WFU-0001/verification.log`
- `reports/evidence/WFU-0001/junit.xml`
- `reports/evidence/WFU-0001/palari.sarif`
- `reports/evidence/WFU-0001/manifest.json`

## Risks / Follow-Ups

- Workflow artifacts are planning records only. They do not run agents, create
  tickets, accept work, mutate policies, or perform broker side effects.
- HGL scoring, workflow planning/autonomy ceilings, snapshot/dashboard
  integration, and human governance coverage remain later roadmap tickets.
