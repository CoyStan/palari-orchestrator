# POS-0031 Technical Report

## Summary

POS-0031 ran Palari-governed wave 2 from the accepted DeepSeek full-pilot
manifest: DSF-TST-01, DSF-GOV-02, and DSF-EVD-02. The prompts included Palari
ticket claim, allowed-path, forbidden-path, scope/lint/CI/report/reviewer
context, and an explicit human acceptance boundary.

This report records execution evidence only. It does not claim Palari improves
safety, speed, performance, productivity, model quality, or implementation
quality.

## Changes

- DSF-TST-01 completed and added overlap-detection regression coverage to
  `tests/run-cli-structure.sh`.
- DSF-GOV-02 completed after one path-root rerun and clarified next-action
  labels for claimed and in-review ticket states.
- POS-0031 integration also made the quiet report-lint probe resilient when
  reviewer notes are intentionally missing, so `palari status --next` can show
  the correct review-gate action instead of exiting.
- DSF-EVD-02 completed and strengthened evidence-manifest validation
  diagnostics plus failure-mode coverage.
- Generated Palari CI manifests now include non-authoritative
  `manifest_file` metadata so fresh evidence packets identify their own
  manifest file without changing trust semantics.
- The DeepSeek full-pilot data-capture sheet now records POS-0031 slot
  outcomes, timings, reruns, checks, confounders, and review handoff state.
- Per-slot run folders now include prompts, commands, timestamps, stdout/stderr,
  exit codes, raw diffs, integrated diffs, checks, timing, and reviewer handoff
  notes.

## Files Changed

- `lib/palari/ci_accept.bash`
- `lib/palari/init_adopt.bash`
- `research/pilots/deepseek-full-pilot/data-capture.md`
- `research/pilots/deepseek-full-pilot/runs/palari-dsf-tst-01/**`
- `research/pilots/deepseek-full-pilot/runs/palari-dsf-gov-02/**`
- `research/pilots/deepseek-full-pilot/runs/palari-dsf-evd-02/**`
- `reports/POS-0031-technical-report.md`
- `tests/golden/status.contains.txt`
- `tests/run-agent-wrapper.sh`
- `tests/run-cli-structure.sh`
- `tests/run-github-ci.sh`
- `tests/run-golden.sh`
- `tickets/open/POS-0031-deepseek-palari-wave-2.md`

## Verification

- DSF-TST-01:
  - `tests/run-cli-structure.sh` passed.
  - `tests/run-golden.sh` passed.
  - `grep -q 'scope-overlaps' tests/run-cli-structure.sh` passed.
  - `git diff --check` passed.
- DSF-GOV-02:
  - `tests/run-golden.sh` passed.
  - `tests/run-cli-structure.sh` passed.
  - `grep -q 'Next required action' tests/golden/status.contains.txt` passed.
  - `git diff --check` passed.
- DSF-EVD-02:
  - `tests/run-cli-structure.sh` passed.
  - `tests/run-agent-wrapper.sh` passed.
  - `git diff --check` passed.
  - `grep -q 'manifest' reports/evidence/POS-*/manifest.json` initially
    failed before fresh POS-0031 evidence existed because historical manifest
    JSON files did not contain the literal string `manifest`. After
    `./bin/palari ci POS-0031` generated fresh evidence with `manifest_file`
    metadata, the grep rerun passed. The initial failure remains recorded as an
    objective-check confounder.

Additional integrated checks run before Palari CI:

- `tests/run-cli-structure.sh` passed.
- `tests/run-agent-wrapper.sh` passed.
- `bash -n bin/palari lib/palari/*.bash` passed.
- `tests/run-golden.sh` passed.
- `tests/run-github-ci.sh` passed after clearing inherited GitHub Actions PR
  environment variables inside the test fixture.
- `./bin/palari status --next` showed the next review gate:
  `reviewer reports needed: palari packet POS-0031 reviewer; verify with
  palari lint POS-0031`.

## CI Evidence

POS-0031 ticket-level Palari checks passed and were captured under:

- `reports/evidence/POS-0031/verification.log`
- `reports/evidence/POS-0031/junit.xml`
- `reports/evidence/POS-0031/manifest.json`
- `reports/evidence/POS-0031/palari.sarif`

## Risks / Follow-Ups

- Execution baseline was `76c47d1`, the merged PR #17 state on `origin/main`,
  while the frozen manifest starting commit remains `475b0d0`. Score this as a
  documented baseline drift during POS-0032.
- POS-0031 was claimed with `--allow-overlap` because future POS-0032/POS-0033
  and in-review POS-0034 intentionally share research/evidence or maintenance
  paths. The overlap acknowledgment should be considered during fresh review.
- The built-in `palari worktree POS-0031` command could not run after claim
  metadata dirtied the canonical checkout, so the POS-0031 integration worktree
  was created manually from `origin/main`. The canonical checkout was restored
  to clean by reversing only the claim metadata there.
- DSF-GOV-02 attempt 1 exited `0` but produced no patch after resolving
  repository paths under the prompt folder and hitting opencode
  external-directory auto-rejections. Attempt 1 artifacts are preserved.
- During POS-0031 integration, `palari status --next` briefly returned an empty
  next-action section after the ticket moved to review because the quiet
  report-lint probe was brittle around missing reviewer notes. The probe now
  runs report lint in a subshell and the fixed status output is verified.
  POS-0031 was reopened/reclaimed after this fix so final CI evidence could be
  regenerated before returning the ticket to review.
- DSF-EVD-02 required a manual merge with DSF-TST-01 in
  `tests/run-cli-structure.sh`; both slot additions were preserved.
- The DSF-EVD-02 manifest grep is a weak objective check because it checks
  literal JSON text rather than structural manifest validity. The model and
  integration evidence record that limitation.
- No public claims about safety, performance, speed, productivity, or model
  quality should be made from this wave alone.
