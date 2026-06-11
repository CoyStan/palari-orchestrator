# POS-0035 Technical Report

## Files Changed

Imported the ForgeGate side version from
`/home/operator/projects/palari-orchestrator-forgegate.zip`.

- Added the optional `palari gate` command family and shell adapter wiring.
- Added the vendored ForgeGate Python kernel, layouts, docs, integration notes,
  and signed-acceptance contract.
- Extended `palari accept` so `gate.enabled: true` requires a verified signed
  implement/test/review custody chain and fails closed when unavailable.
- Extended `palari ci` to auto-attest the test step when a gate token exists.
- Added snapshot/dashboard custody status so operators can see whether evidence
  is honor-system, partial, refused, or sealed.
- Added config/schema support, GitHub workflow coverage, and gate tests.

## Verification

Local checks run on branch `codex/forgegate-side-version`:

- `bash -n bin/palari lib/palari/*.bash tests/run-*.sh`
- `node --check adapters/web/static/app.js`
- `python3 -m py_compile adapters/web/server.py adapters/gate/palari_gate.py gate/forgegate/*.py`
- `tests/run-cli-structure.sh`
- `tests/run-adoption.sh`
- `tests/run-proposals.sh`
- `tests/run-roles.sh`
- `tests/run-agent-wrapper.sh`
- `tests/run-authority-lifecycle.sh`
- `tests/run-github-ci.sh`
- `tests/run-golden.sh`
- `tests/run-dashboard-rubric.sh`
- `tests/run-gate-kernel.sh`
- `tests/run-gate.sh`
- `./bin/palari lint`
- `./bin/palari ci --repo-only`
- `git diff --check`

The first remote PR attempt failed the Palari governance job because the PR had
no changed ticket file. POS-0035 was created to give the PR an explicit
governed scope.

During local ticket validation, the initial POS-0035 verification list also
included `./bin/palari ci POS-0035 --base origin/main`. Because `palari ci`
executes the ticket verification list, that was recursive. The item was
removed and replaced with `git diff --check`.

The next POS-0035 CI run found that `tests/run-gate.sh` claimed synthetic
`GTE-*` tickets with `docs/**`, which overlaps POS-0035's allowed docs scope.
The test fixture now passes `--allow-overlap` for those synthetic claims so the
gate test remains portable in repositories with another open docs-scoped
ticket.

After that fix, `./bin/palari ci POS-0035 --base origin/main` passed locally.
Its generated evidence was not committed because it binds to the pre-commit
HEAD; GitHub will produce fresh merge-gate evidence for the pushed commit.

## CI Evidence

Local repo-only CI wrote temporary evidence under `reports/evidence/repo` and
passed. That generated evidence was removed before staging so the commit only
contains intentional ForgeGate import artifacts and POS-0035 governance files.

GitHub checks should be re-run after this ticket/report commit is pushed.

## Risks / Follow-Ups

- ForgeGate is optional and disabled by default; enabling it requires Python
  with `cryptography`.
- The kernel is reviewed-not-audited reference code, not a formal crypto audit.
- The standalone `forgegate` package declares `click` and `PyYAML`; Palari's
  integration path uses the stdlib adapter plus `cryptography`.
- POS-0032/POS-0033 research work remains separate and was not included.
