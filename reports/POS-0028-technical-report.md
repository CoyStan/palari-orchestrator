# POS-0028 Technical Report

## Summary

POS-0028 ran Baseline wave 1 from the accepted DeepSeek full-pilot manifest:
DSF-DOC-02, DSF-CLI-01, and DSF-WEB-02. The prompts intentionally omitted
Palari lifecycle context such as claim, scope-check, CI, evidence-bundle,
reviewer-packet, and lifecycle-transition instructions.

This report records execution evidence only. It does not claim Palari improves
safety, speed, performance, or model quality.

## Changes

- DSF-DOC-02 completed and added an explicit MCP adapter non-mutation boundary
  sentence to `adapters/mcp/README.md`.
- DSF-CLI-01 timed out after the 900-second opencode timebox and produced no
  implementation diff.
- DSF-WEB-02 completed and added CSS wrapping guards for long queue titles,
  human-summary titles, command code, ticket-table labels, and selected-ticket
  headings in `adapters/web/static/app-shell.css`.
- The DeepSeek full-pilot data-capture sheet now records POS-0028 slot outcomes,
  timings, checks, confounders, reviewer state, and scoring handoff.
- Per-slot run folders now include prompts, commands, timestamps, stdout/stderr,
  exit codes, diffs, checks, timing, and reviewer handoff notes.
- Candidate exclusions and partial screenshot evidence are documented in
  `research/pilots/deepseek-full-pilot/exclusions.md`.

## Files Changed

- `adapters/mcp/README.md`
- `adapters/web/static/app-shell.css`
- `research/pilots/deepseek-full-pilot/data-capture.md`
- `research/pilots/deepseek-full-pilot/exclusions.md`
- `research/pilots/deepseek-full-pilot/runs/baseline-dsf-doc-02/**`
- `research/pilots/deepseek-full-pilot/runs/baseline-dsf-cli-01/**`
- `research/pilots/deepseek-full-pilot/runs/baseline-dsf-web-02/**`
- `reports/POS-0028-technical-report.md`
- `reports/POS-0028-reviewer-note.md`
- `reports/evidence/POS-0028/screenshots/**`
- `tickets/closed/POS-0028-deepseek-baseline-wave-1.md`

## Verification

- DSF-DOC-02:
  - `grep -q 'does not accept, merge, push, deploy, or bypass human acceptance' adapters/mcp/README.md`
    passed.
  - `git diff --check -- adapters/mcp/README.md` passed.
- DSF-CLI-01:
  - `tests/run-cli-structure.sh` passed.
  - `tests/run-golden.sh` passed.
  - `bash -n bin/palari lib/palari/*.bash` passed.
  - `git diff --check` passed.
  - The checks passed on the unchanged slot worktree because the model timed
    out before creating a patch.
- DSF-WEB-02:
  - `tests/run-dashboard-rubric.sh` passed.
  - `node --check adapters/web/static/app.js` passed.
  - `python3 -m py_compile adapters/web/server.py` passed.
  - `git diff --check` passed.
  - Screenshot capture at 375, 768, and 1280 px produced files, but the browser
    showed `Offline` / `snapshot failed: 500`, so loaded-data screenshot review
    is partial.

## CI Evidence

POS-0028 ticket-level Palari checks passed in the accepted integration state:

- `./bin/palari lint POS-0028` passed.
- `git diff --check` passed.
- `./bin/palari scope-check POS-0028` passed.
- `./bin/palari ci POS-0028` passed.

CI evidence bundle:

- `reports/evidence/POS-0028/verification.log`
- `reports/evidence/POS-0028/junit.xml`
- `reports/evidence/POS-0028/manifest.json`
- `reports/evidence/POS-0028/palari.sarif`

The reviewer note is present, and final `./bin/palari lint POS-0028` and
`./bin/palari ci POS-0028` pass with the accepted ticket file under
`tickets/closed/`.

## Risks / Follow-Ups

- DSF-CLI-01 is a timeout/no-patch outcome and should be treated as an
  exclusion candidate or failed slot during POS-0032 scoring.
- DSF-WEB-02 screenshot evidence is partial because headless dashboard capture
  hit HTTP 500 on `/api/snapshot`, even though `palari snapshot --json`,
  `palari web --check`, and static dashboard checks passed.
- The execution baseline was commit `1236a08`, which includes accepted
  POS-0025 through POS-0027 research/pilot artifacts. The frozen POS-0026
  manifest starting commit remains `475b0d0`.
- The ticket metadata uses `target_branch: origin/main` so the actual
  `ticket/POS-0028-run` branch and worktree pass branch-containment checks in
  this checkout, where the local `main` ref is stale/divergent.
- No public claims about safety, performance, speed, or model quality should be
  made from this wave alone.
