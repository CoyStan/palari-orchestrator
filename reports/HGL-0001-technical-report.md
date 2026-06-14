# HGL-0001 Technical Report

## Files Changed

- `adapters/planning/hgl.py`
  - Adds a stdlib Python Human Governance Load scorer for workflow expected
    decisions and active human governance profiles.
  - Produces deterministic text and JSON with HGL, R0-R5 counts, required
    skills, missing skills, bottlenecks, launch gate, autonomy ceiling, and
    per-decision coverage.
- `lib/palari/burden.bash`
  - Adds the Bash wrapper for `palari burden score WF-ID [--json]` and
    `palari human coverage WF-ID [--json]`.
- `bin/palari`
  - Sources the burden module, advertises the commands, and dispatches
    `palari burden`.
- `lib/palari/humans.bash`
  - Adds `palari human coverage` dispatch and help text.
- `lib/palari/init_adopt.bash`
  - Adds the burden module to doctor checks.
- `tests/run-human-governance-load.sh`
  - Covers deterministic scoring, JSON output, skill coverage, missing R5
    coverage, red/yellow gates, and autonomy ceilings.
- `tests/run-cli-structure.sh`
  - Adds the burden module to CLI structure checks.
- `contracts/human-governance-load.md`
  - Documents the read-only HGL contract, formula, coverage behavior, gates,
    autonomy ceilings, and non-goals.
- `README.md`, `STATE.md`, `CHANGELOG.md`
  - Document the new read-only HGL commands and shipped capability.
- `tickets/open/HGL-0001-add-human-governance-load-scorer.md`
  - Replaces the generated body with the scoped completion contract.

## Verification

Passed during implementation:

- `./tests/run-human-governance-load.sh`
- `./tests/run-workflows.sh`
- `./tests/run-human-governance.sh`
- `./tests/run-cli-structure.sh`
- `python3 -m py_compile adapters/planning/hgl.py`
- `bash -n lib/palari/burden.bash`

## CI Evidence

Pending final gate evidence:

- `./bin/palari lint HGL-0001`
- `./bin/palari report-lint HGL-0001`
- `./bin/palari scope-check HGL-0001`
- `git diff --check`
- `./bin/palari ci HGL-0001 --base ticket/HUM-0001`

## Risks / Follow-Ups

- The scorer is deterministic and intentionally simple. It makes human
  judgment visible; it is not a complete risk model.
- HGL currently reads active human profiles and workflow expected decisions
  only. It does not yet generate workflow plans or recommended next actions;
  that belongs to PLN-0001.
- No lifecycle mutation, policy activation, broker behavior, external writes,
  credentials, network calls, or dependency changes were added.
