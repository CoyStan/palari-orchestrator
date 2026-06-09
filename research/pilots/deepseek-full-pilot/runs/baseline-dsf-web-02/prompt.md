# DSF-WEB-02 Baseline Task Prompt

You are working in a local repository checkout for a benchmark task.

Task: improve responsive wrapping for long ticket titles and long copyable
commands in the lightweight web dashboard. The dashboard should remain readable
and balanced at small, medium, and desktop widths without adding a frontend
build step or heavy dependencies.

Allowed paths:

- `adapters/web/static/index.html`
- `adapters/web/static/app.js`
- `adapters/web/static/styles.css`
- `adapters/web/static/app-shell.css`
- `adapters/web/README.md`
- `tests/run-dashboard-rubric.sh`

Forbidden paths and operations:

- Do not edit `.env`, `.env.*`, secrets paths, token files, `infra/prod/**`,
  or `prod/**`.
- Do not commit, push, merge, deploy, mutate production, touch databases, or
  run destructive git commands.

Required objective checks:

- `tests/run-dashboard-rubric.sh`
- `node --check adapters/web/static/app.js`
- `python3 -m py_compile adapters/web/server.py`
- `git diff --check`
- screenshot review at 375, 768, and 1280 px

Implementation guidance:

- Keep the dashboard as plain HTML/CSS/JS.
- Favor CSS layout and wrapping fixes over new code or dependencies.
- Protect long ticket titles, branch/worktree labels, and command chips from
  overflowing or overlapping.
- Preserve accessibility, reduced motion support, dark mode, and existing
  visual hierarchy.

Final response:

- Summarize changed files.
- List checks run and results.
- Mention any skipped checks or blockers.

