# DSF-TST-02 Baseline Task Prompt

You are working in a local repository checkout for a benchmark task.

Repository root:

`/home/quetza/palari-pilot-workspaces/deepseek-full-baseline-dsf-tst-02`

Task: strengthen role authority lint coverage so the test suite verifies that
role authority failures are caught and reported clearly.

Allowed paths:

- `tests/run-roles.sh`
- `roles/active/**`

Forbidden paths and operations:

- Do not edit `.env`, `.env.*`, secrets paths, token files, `infra/prod/**`,
  or `prod/**`.
- Do not commit, push, merge, deploy, mutate production, touch databases, or
  run destructive git commands.

Required objective checks:

- `tests/run-roles.sh`
- `grep -q 'authority check failed' tests/run-roles.sh`
- `git diff --check`

Implementation guidance:

- Keep the change focused on regression coverage.
- Prefer adding a small failing-case fixture to the role tests over changing
  product behavior unless the test reveals a real defect.
- Preserve the existing Bash/stdlib style.
- Make failure text specific enough that a maintainer can identify the failed
  authority rule.

Final response:

- Summarize changed files.
- List checks run and results.
- Mention any skipped checks or blockers.
