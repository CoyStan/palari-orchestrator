# DSF-CLI-01 Baseline Task Prompt

You are working in a local repository checkout for a benchmark task.

Task: make stale or expired claim next-action diagnostics clearer. A user
looking at status output should understand when a claimed ticket has an expired
lease and what action to take next. Keep command names and existing lifecycle
semantics stable.

Allowed paths:

- `lib/palari/init_adopt.bash`
- `lib/palari/tickets_workspace.bash`
- `tests/run-cli-structure.sh`
- `tests/golden/status.contains.txt`

Forbidden paths and operations:

- Do not edit `.env`, `.env.*`, secrets paths, token files, `infra/prod/**`,
  or `prod/**`.
- Do not commit, push, merge, deploy, mutate production, touch databases, or
  run destructive git commands.

Required objective checks:

- `tests/run-cli-structure.sh`
- `tests/run-golden.sh`
- `bash -n bin/palari lib/palari/*.bash`
- `git diff --check`

Implementation guidance:

- Prefer a narrow diagnostic/output improvement over a lifecycle rewrite.
- Preserve existing command names, ticket schema, and acceptance behavior.
- Add focused regression coverage only where it directly checks the clearer
  stale-claim diagnostic.

Final response:

- Summarize changed files.
- List checks run and results.
- Mention any skipped checks or blockers.

