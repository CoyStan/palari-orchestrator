# POS-0104 Reviewer Note

## Review Result

Reopened.

## Findings

- High: normal process tickets can still pass with skipped acceptance evidence if the manifest is internally inconsistent. A temporary fixture flipped `skipped_acceptance_criteria` to `false` while `skipped_checks[].acceptance_criteria` stayed true; `evidence score --strict` returned ready and `accept` succeeded.
- Medium: TODO/FIXME/expected-failure markers emitted by verification command output are not scanned when the configured verification string itself does not contain those words.
- Medium: allowed documentation/test-discovery skips do not appear in `palari evidence score` output, so readiness can hide that evidence was skipped intentionally.

## Verification Reviewed

- `./tests/run-evidence-quality.sh`
- `bats tests/palari_acceptance.bats`
- `./tests/run-cli-structure.sh`
- `./bin/palari scope-check POS-0104 --base ticket/POS-0103`
- `./bin/palari report-lint POS-0104`
- `./bin/palari evidence score POS-0104 --strict`
- `bash -n bin/palari lib/palari/ci_accept.bash lib/palari/evidence_truthfulness.bash lib/palari/evidence_quality.bash tests/run-evidence-quality.sh`
- `shfmt -d bin/palari lib/palari/ci_accept.bash lib/palari/evidence_truthfulness.bash lib/palari/evidence_quality.bash tests/run-evidence-quality.sh`

## Required Changes

- Derive skipped-acceptance failure from `skipped_checks[].acceptance_criteria`, not only from the top-level `skipped_acceptance_criteria` flag, and reject inconsistent manifests fail-closed.
- Scan verification command output for deferred-evidence markers before writing the manifest.
- Make `evidence score` print skipped/deferred truthfulness fields even when an explicit docs/test-discovery exception allows readiness.

## Recommendation

Do not accept POS-0104 until the bounded findings are repaired and re-reviewed.

## Repair Re-Review Result

Reopened.

## Repair Re-Review Findings

- High: `skipped_checks[].acceptance_criteria: true` can still be neutralized when `skipped` is falsified to `0` and `skipped_acceptance_criteria` is falsified to `false`. A fresh isolated CLI probe still returned `score: 100/100` and `rating: ready`.

## Repair Re-Review Required Changes

- Make `skipped_checks[].acceptance_criteria: true` independently fail closed for process tickets, even when `skipped` or `skipped_acceptance_criteria` are falsified.
- Add a regression where `skipped=0`, `skipped_acceptance_criteria=false`, and `skipped_checks[].acceptance_criteria=true` causes both `evidence score --strict` and `accept` to fail.
