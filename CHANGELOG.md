# Changelog

## Unreleased

- Made the local sandbox a first-class primitive (POS-0045). `palari sandbox
  create` now writes machine-readable metadata to `.palari/sandbox.json`
  (ticket, mode, source repo/commit, target branch, created_at), and new
  lifecycle commands manage sandboxes: `sandbox list`, `sandbox inspect`
  (metadata, dirty state, changed paths), and `sandbox destroy` (refuses any
  path without the `.palari-sandbox` marker). Validated by
  `tests/run-sandbox.sh`.
- Documented the isolation model honestly (POS-0044). Docs now distinguish
  worktrees (ticket isolation), local sandboxes (disposable repo copies), and
  hardened sandboxes (container/VM/remote, not yet shipped), and state
  explicitly that a local sandbox is not a security boundary - scope,
  evidence, review, and acceptance gates are the control layer.
- Made skills machine-discoverable (POS-0043). Shipped skills under `skills/`
  now carry YAML frontmatter (`name`, `description`), and two new commands
  inspect them: `palari skill list` enumerates shipped, adopter, and plugin
  skills; `palari skill lint` validates frontmatter, per-root name uniqueness,
  and refuses skills whose wording claims authority a skill may never hold
  (accept, merge, push, or overriding `AGENTS.md`). Skills guide behavior;
  tickets and gates enforce authority. Validated by `tests/run-skills.sh`.
- Packaged Palari as a Claude Code plugin with a self-hosted marketplace:
  `.claude-plugin/marketplace.json` at the repo root and the plugin under
  `plugin/` (operating skill, six `/palari-orchestrator:*` slash commands,
  and `palari-specialist` / `palari-reviewer` subagents that enforce
  no-self-acceptance and fresh-context review). Install with
  `/plugin marketplace add CoyStan/palari-orchestrator` then
  `/plugin install palari-orchestrator@palari`. Added a Codex adapter
  (`adapters/codex/`) with prompt files and an installer, since Codex's
  native mechanism is the `AGENTS.md` contract Palari already ships.
  Validated by `tests/run-plugin-structure.sh`.
- Added first-class goals (`palari goal create|list|show|adopt|achieve|drop|lint`)
  under `goals/`. Tickets and proposals link to a goal with `serves_goal`
  (`--goal GOAL-ID` at creation), making founder intent machine-readable and
  prioritization traceable. `require_serves_goal` (off|warn|strict) controls
  enforcement; goals never grant authority. See
  `contracts/goals-and-decisions.md`.
- Added structured decisions (`palari decide create|list|show|record|lint`)
  under `decisions/`. Agents draft a question with two or more options,
  tradeoffs, a recommendation, a respond-by date, and an explicit default;
  only a human records the outcome, which is archived and mirrored into
  `memory/decisions/`. Defaults may never include human-gated actions. Open
  decisions appear in `palari snapshot --json` as `open_decisions`.
- Implemented the queue runner dry-run from the POS-0040 spec:
  `palari run --dry-run [--until blocked] [--goal GOAL-ID] [--max N] [--json]`
  prints a read-only plan in spec priority order, surfaces open decisions and
  human gates as stop items, and skips overlapping, over-broad, or
  lease-unclear tickets with reasons. `palari run` without `--dry-run` fails
  closed; no execution mode exists.
- Replaced substring-glob forbidden path defaults (`**/*secret*`,
  `**/*token*`) with precise patterns (key files, `.env` everywhere, secrets
  directories, SSH/AWS material) in core defaults, `palari.config.yaml`, and
  all role files. The old globs blocked legitimate source files such as
  `gate/forgegate/token.py` while renamed credentials evaded them; pair path
  rules with a content scanner such as gitleaks in CI.
- Hardened YAML correctness end to end: ticket/role/goal/decision frontmatter
  generation now quotes items a strict parser would reject, `palari lint`
  flags unquoted indicator characters, `palari doctor` runs a strict
  python3+PyYAML frontmatter audit when available, and all existing tickets
  were repaired to parse as valid YAML.
- Stopped persisting machine-absolute worktree paths into ticket frontmatter
  at creation; the path is computed from `worktree_base` at runtime. Scrubbed
  previously committed absolute home paths from the repository history
  surfaces (tickets and research run logs).
- Hardened evidence scoring: `junit.xml` only scores when it contains at
  least one testcase with zero failures/errors, and reviewer notes under 200
  bytes are treated as missing.
- Documented the claim-lease atomicity boundary (git refs are a coordination
  convention, not a cross-machine lock) in
  `contracts/goals-and-decisions.md`.
- Added `.gitattributes` export-ignore so release archives ship the portable
  tool without this repository's own governance history and pilot run data.
- Clarified the `skills/` (shipped) vs `agent-skills/` (adopter-generated)
  split and created the configured `agent-skills/` directory.

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
