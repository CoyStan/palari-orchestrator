# Changelog

## Unreleased

- Added the forge-proof accept gate: the forgegate kernel is vendored at
  `gate/` with its adversarial test suite, and `palari accept` requires a
  cryptographic verdict when `gate.enabled` is true. Signed Ed25519
  attestations, narrowing-only delegation tokens, byte-for-byte hash flow
  between implement, test, and review, dual control by distinct keys, commit
  binding, and a freshness window replace honor-system manifests and name
  strings as the acceptance authority. Acceptance fails closed if the kernel
  is unavailable. See `contracts/signed-acceptance.md`.
- Added `palari gate` commands (init, setup-ticket, grant, attest-implement,
  attest-test, attest-review, attest, verify, status), gate auto-attestation
  of the test step after green single-ticket CI, gate health in `doctor`, a
  `gate` section in `palari snapshot --json`, governance layouts under
  `layouts/`, and a `gate:` config block with schema coverage.
- Overhauled the operator console: chain-of-custody rail with seal states,
  signer fingerprints, and verbatim gate verdicts; queue, pipeline board, and
  ledger surfaces over one snapshot; keyboard navigation; auto refresh that
  pauses in hidden tabs; live lease countdowns; root key plaque; honest
  honor-system state when the gate is off; rewritten dashboard rubric with
  AA contrast computed for both themes.
- Fixed the bash config parser to strip inline YAML comments and fixed
  `palari snapshot` failing outside a git work tree.

## Previous Unreleased

- Added public-readiness audit documentation.
- Added evidence manifest integrity checks before acceptance.
- Removed MCP exposure of the acceptance command.
- Added local dashboard non-loopback bind refusal unless explicitly unsafe.
- Added open-source project hygiene files and GitHub templates.
- Added security workflows for Scorecard, CodeQL, dependency updates, and static
  shell/workflow checks.

## 0.1.0

- Initial portable Palari Orchestrator package.
- Ticket lifecycle, worktree-first execution, packets, scope checks, reports,
  CI evidence, acceptance gate, templates, contracts, and optional adapters.
