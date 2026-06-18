# CLI Maintainability Contract

The Palari CLI stays portable Bash, but the entrypoint must not become the
whole application.

## Fixed Enough Criteria

The large-CLI maintainability risk is considered fixed when:

- `bin/palari` is only bootstrap, module loading, usage text, and dispatch.
- `bin/palari` stays below 300 lines.
- Palari Bash behavior lives in named modules under `lib/palari/*.bash`.
- No Palari Bash module exceeds 900 lines.
- `adopt` copies `lib/` into target repositories.
- `doctor` can confirm the module set exists after adoption.
- Shell syntax, ShellCheck, shfmt, golden flow, and adoption tests pass.

## Module Boundaries

- `core.bash`: config, frontmatter, git, path, report, and overlap helpers.
- `init_adopt.bash`: init, status, doctor, and adoption.
- `proposals.bash`: restricted lead/planner proposals.
- `tickets_workspace.bash`: ticket lifecycle, worktrees, and sandboxes.
- `agents_review_scope.bash`: executor wrapper, packets, report lint, and scope gates.
- `ci_accept.bash`: CI evidence, manifests, and acceptance.
- `evidence_truthfulness.bash`: skipped, expected-failure, FIXME/TODO, and follow-up metadata for evidence manifests.
- `evidence_quality.bash`: conservative evidence readiness scoring.
- `adapters_snapshot.bash`: skills, MCP, GitHub, snapshot, web, and memory adapters.

## Required Check

Run this whenever CLI ownership changes:

```bash
tests/run-cli-structure.sh
```

This is a structural guard, not a substitute for behavior tests.
