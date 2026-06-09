# POS-0018 Reviewer Note

## Review Result

Decision: accept

## Findings

- The role layer rejects or escalates unknown authority instead of silently accepting it.
- Ordinary roles cannot silently edit active/revoked roles, Palari core files, workflow rules, or core config.
- Proposed and revoked roles cannot act as active authority.
- Role-issued ticket creation records role metadata and preserves the old no-role ticket flow.
- Packet context now includes role authority information when a ticket has role metadata.

## Verification Reviewed

- `tests/run-roles.sh`
- `tests/run-golden.sh`
- `tests/run-memory.sh`
- `tests/run-adoption.sh`
- `tests/run-dashboard-rubric.sh`
- `tests/run-cli-structure.sh`
- `./bin/palari lint`
- `bash -n bin/palari lib/palari/*.bash tests/run-roles.sh`
- `shellcheck -x bin/palari lib/palari/*.bash scripts/palari`
- `shfmt -d bin/palari lib/palari/*.bash scripts/palari`
- `actionlint`
- `bats tests`
- `python3 -m py_compile adapters/web/server.py adapters/memory/memory.py`
- `git diff --check`
- Palari CI evidence under `reports/evidence/POS-0018/`

## Required Changes

- None.

## Recommendation

Accept. The v1 role layer is still intentionally local and unsigned, but it is now much harder for roles to become an authority bypass.
