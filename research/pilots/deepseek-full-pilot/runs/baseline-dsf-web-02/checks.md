# DSF-WEB-02 Checks

Condition: Baseline

## Required Objective Checks

- `tests/run-dashboard-rubric.sh`
  - Result: passed (`dashboard-rubric: ok (static layout checks + contrast)`)
- `node --check adapters/web/static/app.js`
  - Result: passed
- `python3 -m py_compile adapters/web/server.py`
  - Result: passed
- `git diff --check`
  - Result: passed
- Screenshot review at 375, 768, and 1280 px
  - Result: partial / failed loaded-data review
  - Evidence:
    - `screenshots/viewport-375.png`
    - `screenshots/viewport-768.png`
    - `screenshots/viewport-1280.png`

## Screenshot Notes

Headless Chromium captured all three requested viewports, but the rendered
dashboard showed `Offline` with `snapshot failed: 500`. A retry with
server-side snapshot prewarm produced the same visible state. Separately,
`./bin/palari web --check` and `./bin/palari snapshot --json` passed in the
POS-0028 run worktree, and `./bin/palari web --check` passed in the slot
worktree after a long snapshot run.

Because the browser-visible ticket data did not load, these screenshots do not
verify long-title or command wrapping against populated data. They do confirm
that the page shell remained nonblank and did not crash.

## Scope Notes

- Changed file: `adapters/web/static/app-shell.css`
- The changed file is in POS-0028 `allowed_paths`.
- No forbidden paths were changed.

## Run Outcome

- opencode exit code: `0`
- No rerun was attempted.
- No dependencies or frontend build steps were added.
