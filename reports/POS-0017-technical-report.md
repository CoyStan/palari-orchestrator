# POS-0017 Technical Report

## Files Changed

- `.github/workflows/palari.yml`
- `.github/workflows/static-analysis.yml`
- `.github/workflows/test.yml`
- `README.md`
- `adapters/github/workflows/palari.yml`
- `bin/palari`
- `lib/palari/adapters_snapshot.bash`
- `tests/run-github-ci.sh`
- `tests/run-golden.sh`
- `tickets/open/POS-0017-clear-github-ci-ticket-discovery.md`

## Verification

- `tests/run-github-ci.sh`
- `tests/run-golden.sh`
- `tests/run-adoption.sh`
- `tests/run-cli-structure.sh`
- `tests/run-proposals.sh`
- `tests/run-agent-wrapper.sh`
- `tests/run-memory.sh`
- `shellcheck -x bin/palari scripts/palari tests/run-cli-structure.sh tests/run-adoption.sh tests/run-proposals.sh tests/run-agent-wrapper.sh tests/run-github-ci.sh tests/run-golden.sh tests/run-memory.sh`
- `shfmt -d bin/palari scripts/palari lib/palari/*.bash tests/run-cli-structure.sh tests/run-adoption.sh tests/run-proposals.sh tests/run-agent-wrapper.sh tests/run-github-ci.sh tests/run-golden.sh tests/run-memory.sh`
- `actionlint`
- `python3 -m py_compile adapters/web/server.py adapters/memory/memory.py`
- `bats tests`
- `./bin/palari scope-check POS-0017 --base origin/main`
- `./bin/palari lint POS-0017`
- `./bin/palari ci POS-0017 --base origin/main`

## CI Evidence

- Local Palari evidence was generated during implementation and intentionally
  left out of the branch so GitHub can produce fresh PR evidence.

## Risks / Follow-Ups

- `palari github ci --repo-only` remains intentionally explicit. It should not
  be used as a shortcut for ticket-governed agent work.
- The GitHub workflow still fetches the base ref in YAML. Ticket discovery and
  policy now live in the CLI.
