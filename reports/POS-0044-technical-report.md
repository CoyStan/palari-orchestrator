# POS-0044 Technical Report

## Session

- Ticket: POS-0044
- Role: specialist (claude)
- Branch: combine/plugin-import
- Result: in-review

## Files Changed

```text
README.md
adapters/opencode/README.md
contracts/adapters.md
CHANGELOG.md
tickets/open/POS-0044-honest-sandbox-terminology-and-isolation-docs.md
```

## Outcome

- What changed: docs now use three isolation terms consistently - worktree
  (ticket isolation), local sandbox (disposable repo copy), hardened sandbox
  (container/VM/remote, not shipped). The opencode adapter README gained an
  Isolation Model table; the README executor section and capability bullet,
  and the adapters contract, now state explicitly that a local sandbox is not
  a security boundary and that scope/evidence/review/acceptance gates are the
  control layer. The adapters contract also forbids adapters from describing
  the local sandbox as a security boundary.
- What did not change: no code, no commands, no behavior. `sandbox create`
  semantics are untouched (lifecycle commands are POS-0045).

## Verification

- `git diff --check` -> clean
- `./bin/palari scope-check POS-0044` -> ok (5 changed paths)
- `./bin/palari lint POS-0044` -> ok (serves_goal warning only)

## CI Evidence

- `./bin/palari ci POS-0044` -> ok
- Bundle: `reports/evidence/POS-0044/`

## Risks / Follow-Ups

- None functional. POS-0045 will add sandbox lifecycle commands; its docs
  should reuse this vocabulary.
