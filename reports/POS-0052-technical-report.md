# POS-0052 Technical Report

## Files Changed

- `.gitattributes`
- `.github/workflows/test.yml`
- `.github/workflows/static-analysis.yml`
- `CHANGELOG.md`
- `tests/run-readme-assets.sh`
- `tickets/open/POS-0052-fix-readme-asset-archive-packaging.md`

## Verification

Passed:

```text
tests/run-readme-assets.sh
shellcheck -x tests/run-readme-assets.sh
```

The new regression reads README `assets/readme/*` references, verifies each
file exists, and fails if any referenced asset has `export-ignore` set.

## CI Evidence

Passed:

```text
./bin/palari scope-check POS-0052
./bin/palari lint POS-0052
./bin/palari ci POS-0052
git diff --check
```

Evidence is stored under `reports/evidence/POS-0052/`.

## Risks / Follow-Ups

- This preserves the existing README visual direction; it does not redesign or
  replace assets.
- The release archive policy still excludes governance history and evidence;
  only README-referenced image assets are kept portable.
