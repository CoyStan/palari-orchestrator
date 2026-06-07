## Summary

## Scope

Changed paths:

```text

```

## Verification

- [ ] `tests/run-golden.sh`
- [ ] `tests/run-cli-structure.sh`
- [ ] `tests/run-dashboard-rubric.sh`
- [ ] `./bin/palari lint`
- [ ] `shellcheck -x bin/palari scripts/palari`
- [ ] `shfmt -d bin/palari scripts/palari lib/palari/*.bash`
- [ ] `actionlint`
- [ ] `python3 -m py_compile adapters/web/server.py`
- [ ] `bats tests`

## Risk

- [ ] acceptance/evidence
- [ ] scope/worktree
- [ ] GitHub governance
- [ ] adapter authority
- [ ] docs/presentation only
