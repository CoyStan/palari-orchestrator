# DeepSeek Full Pilot Exclusions

Source manifest: `research/pilots/deepseek-full-pilot/manifest.md`

This file records candidate exclusions and partial-evidence outcomes. Final
exclusion and scoring decisions belong to POS-0032 fresh review.

## POS-0028 Baseline Wave 1

### DSF-CLI-01

- Condition: Baseline
- Status: timeout / no patch
- Exit code: `124`
- Timebox: 900 seconds
- Changed files: none
- Evidence: `runs/baseline-dsf-cli-01/`
- Candidate exclusion reason: model run exceeded the timebox and produced no
  reviewable implementation diff.
- Replacement run: none
- Claim boundary: this outcome does not support claims about CLI task quality,
  safety, speed, performance, or model quality.

### DSF-WEB-02 Screenshot Review

- Condition: Baseline
- Status: partial screenshot evidence
- Evidence: `runs/baseline-dsf-web-02/screenshots/`
- Reason: headless screenshots at 375, 768, and 1280 px were captured, but the
  browser-visible page showed `Offline` because `/api/snapshot` returned HTTP
  500 during capture.
- Related checks: `./bin/palari snapshot --json`, `./bin/palari web --check`,
  `tests/run-dashboard-rubric.sh`, `node --check adapters/web/static/app.js`,
  `python3 -m py_compile adapters/web/server.py`, and `git diff --check`
  passed.
- Exclusion recommendation: keep DSF-WEB-02 in the study as a completed CSS
  patch, but score screenshot evidence as partial/missing for loaded data.
