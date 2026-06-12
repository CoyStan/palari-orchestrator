# POS-0056 Technical Report

## Summary

Imported the useful parts of
`/home/quetza/projects/palari-orchestrator-openrouter.zip` into a clean
worktree based on `origin/main` (`6497419`), without using the zip as a
replacement snapshot.

The zip was first extracted to:

- `/home/quetza/projects/palari-orchestrator-openrouter-extracted/palari-orchestrator`

Safety checks before import:

- Zip entries had no absolute paths or `..` traversal.
- No `.git`, `.env`, `.ssh`, `.pem`, `.key`, or obvious credential files were
  present in the zip manifest.
- The zip omitted many accepted Palari reports/evidence from current `main`, so
  the import preserved existing repo history and did not use `--delete`.

## Files Changed

- Added risk-tiered model routing in `lib/palari/models.bash`.
  - `palari model routes`
  - `palari model show TICKET [--executor E]`
  - `ticket create --model-hint`
  - `agent run` records resolved model, source, and class in executor evidence.
- Added optional OpenRouter executor support.
  - Adapter: `adapters/openrouter/run.py`
  - Disabled by default via `openrouter_enabled: false`.
  - API key is read from the env var named by `openrouter_api_key_env`.
  - Model allowlist is enforced fail-closed.
  - Offline tests use `PALARI_OPENROUTER_TRANSPORT=file:...`.
  - Executor produces text artifacts/evidence and does not mutate repo files.
- Added stdlib Python fast snapshot adapter.
  - Adapter: `adapters/snapshot/fast_snapshot.py`
  - Early dispatch covers `snapshot --json`, `status [--next]`, and
    `web --check`.
  - Legacy Bash path remains available via `PALARI_SNAPSHOT_ENGINE=bash`,
    `--full`, `--legacy`, or missing `python3`.
- Improved dashboard review surface.
  - Executor evidence and scope/CI refusal evidence now appear as custody rows.
- Added tests for model routing, OpenRouter offline behavior, fast performance,
  gate fast snapshots, dashboard executor evidence, and archive README assets.

## Local Adjustments After Import

- Fixed an imported duplicate `web)` fast-path case in `bin/palari`.
- Preserved accepted reports/evidence from `origin/main`; the zip did not
  contain them.
- Replaced the zip's overlapping changelog text with a concise POS-0056 entry.
- Ensured the config schema retains a final newline.

## Verification

Passed:

- `./bin/palari scope-check POS-0056`
- `bash -n bin/palari lib/palari/*.bash tests/run-model-routing.sh tests/run-openrouter.sh tests/run-performance.sh`
- `python3 -m py_compile adapters/openrouter/run.py adapters/snapshot/fast_snapshot.py adapters/web/server.py`
- `node --check adapters/web/static/app.js`
- `git diff --check`
- `tests/run-model-routing.sh`
- `tests/run-openrouter.sh`
- `tests/run-performance.sh`
- `tests/run-cli-structure.sh`
- `tests/run-dashboard-rubric.sh`
- `tests/run-gate.sh`
- `tests/run-readme-assets.sh`
- `./bin/palari lint POS-0056`

## CI Evidence

Initial `./bin/palari ci POS-0056 --base origin/main` generated an evidence
bundle and all verification commands passed, but the run failed report lint
because this report was missing the required `## Files Changed` and
`## CI Evidence` headings. This report has been corrected and CI rerun evidence
is stored at:

- `reports/evidence/POS-0056/verification.log`
- `reports/evidence/POS-0056/junit.xml`
- `reports/evidence/POS-0056/palari.sarif`
- `reports/evidence/POS-0056/manifest.json`

## Risks / Follow-Ups

- The OpenRouter executor is a text-artifact executor only; it does not replace
  file-editing executors.
- Real OpenRouter runs were intentionally not performed in this ticket because
  they require network access, a human-provided API key, and spend approval.
- GitHub CodeQL initially flagged OpenRouter HTTP error logging because the
  adapter echoed provider response bodies. The adapter now suppresses HTTP
  response bodies in stderr/evidence while still reporting the status code.
- Fast snapshot is a read model. Full diagnostics still belong to the Bash
  snapshot/lint/doctor paths.
- The current branch should be reviewed before acceptance because POS-0056
  touches command dispatch, agent execution, dashboard snapshot, and tests.
