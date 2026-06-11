# POS-0051 Technical Report

## Files Changed

- `bin/palari`
- `scripts/palari`
- `tests/run-adoption.sh`
- `adapters/codex/README.md`
- `CHANGELOG.md`
- `tickets/open/POS-0051-fix-external-palari-root-invocation.md`

## Verification

Passed:

```text
tests/run-adoption.sh
tests/run-cli-structure.sh
shellcheck -x bin/palari scripts/palari tests/run-adoption.sh tests/run-cli-structure.sh
```

The adoption regression now invokes the Palari package from both the target
repository and a temporary directory, proving that external package invocation
uses the package root instead of the caller's git root.

## CI Evidence

Passed:

```text
./bin/palari scope-check POS-0051
./bin/palari lint POS-0051
./bin/palari ci POS-0051
git diff --check
```

Evidence is stored under `reports/evidence/POS-0051/`.

## Risks / Follow-Ups

- The fix keeps `PALARI_ROOT` as the highest-precedence override.
- The script-root fallback only activates when that root contains
  `lib/palari/core.bash`.
- No adoption copy semantics, executor authority, acceptance authority, merge,
  push, deploy, network, or credential behavior changed.
