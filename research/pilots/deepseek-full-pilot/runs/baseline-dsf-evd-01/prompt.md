# DSF-EVD-01 Baseline Task Prompt

You are working in a local repository checkout for a benchmark task.

Repository root:

`/home/quetza/palari-pilot-workspaces/deepseek-full-baseline-dsf-evd-01`

Task: separate local evidence from trusted remote CI in the evidence matrix so
readers understand how local review artifacts and externally trusted CI signals
should be interpreted.

Allowed paths:

- `research/evidence-matrix.md`

Forbidden paths and operations:

- Do not edit `.env`, `.env.*`, secrets paths, token files, `infra/prod/**`,
  or `prod/**`.
- Do not commit, push, merge, deploy, mutate production, touch databases, or
  run destructive git commands.

Required objective checks:

- `grep -q 'local evidence is review evidence' research/evidence-matrix.md`
- `grep -q 'trusted remote CI' research/evidence-matrix.md`
- `git diff --check`

Implementation guidance:

- Keep the matrix cautious and evidence-oriented.
- Do not claim that local evidence or remote CI proves safety, speed,
  performance, or model quality.
- Explain the distinction in plain language that a founder/operator can use
  during review.

Final response:

- Summarize changed files.
- List checks run and results.
- Mention any skipped checks or blockers.
