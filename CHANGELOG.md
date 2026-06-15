# Changelog

## Unreleased

- Documented the Company AI OS infrastructure direction (DOC-0001). README and
  operator docs now explain workflows, Human Governance Load, human coverage,
  policy simulation, broker evidence, outcomes, and current non-goals without
  claiming silent autonomous acceptance or real broker side effects.
- Added deterministic Company OS demo fixtures (DEM-0004). `palari demo
  --company-os` creates a local-only founder/operator demo with active
  workflow, human coverage, missing skill, policy-candidate signal, mock broker
  evidence, recorded outcome, and snapshot/web inspection without external
  agents or services.
- Added the secure governance doctor (SEC-0001). `palari doctor secure` and
  `palari doctor governance` classify weak vs stronger local governance
  posture, report ForgeGate, broker, policy, R5, and branch-protection
  boundaries, and avoid claiming hosted branch protection is active from local
  state.
- Added the outcome ledger (OUT-0001). Outcomes now live under
  `outcomes/open` and `outcomes/recorded`; `palari outcome
  create|list|show|lint|record` manages records without accepting work, and
  policy candidates can cite linked recorded outcomes when present.
- Added the mock broker evidence boundary (BRK-0001). `palari broker run
  TICKET-ID --mock -- COMMAND` records command, cwd, exit code, stdout/stderr
  hashes, observed changed paths, and side-effect posture under
  `reports/evidence/TICKET/broker/`; `broker evidence` and `broker status`
  inspect the mock-only posture without enabling real side effects.
- Added conservative policy candidate suggestions (POL-0002). `palari policy
  candidates [--json]` inspects decided R0-R2 decisions linked to tickets,
  groups repeated recommendation/chosen-option patterns, estimates rough HGL
  reduction, and suggests simulation policy creation commands without creating
  or activating policy files.
- Added simulation-only policy artifacts and CLI (POL-0001). Policies now live
  under `policies/`; `palari policy create|list|show|lint` manages artifacts,
  and `palari policy simulate TICKET-ID [--json]` explains
  `would_accept`/`would_not_accept` without accepting work or moving lifecycle
  state.
- Added Company Governance cards to the local console (DSH-0001). The read-only
  panel renders `company_os` snapshot state: workflow counts, open HGL,
  R3/R4/R5 decision counts, active human coverage count, missing-skill count,
  and active workflow launch gates without adding mutation controls.
- Added compact Company OS snapshot state (SNP-0001). `palari snapshot --json`,
  the Bash snapshot fallback, and `palari web --check` now expose
  `company_os` with workflow/human counts, open HGL estimate, R3/R4/R5 decision
  counts, missing skills, bottlenecks, autonomy gate distribution,
  simulation-only policy posture, and broker side-effect posture.
- Added read-only workflow planning and autonomy output (PLN-0001).
  `palari workflow plan WF-ID [--json]` combines workflow artifacts, HGL,
  active human coverage, allowed/blocked modes, required skills, missing
  skills, bottlenecks, launch gates, autonomy ceilings, and recommended next
  actions without claiming tickets or mutating lifecycle state.
- Added Human Governance Load scoring and coverage commands (HGL-0001).
  `palari burden score WF-ID [--json]` and `palari human coverage WF-ID
  [--json]` read workflow expected decisions and active human profiles to show
  deterministic HGL, R0-R5 decision counts, missing skills, bottleneck roles,
  launch gates, and autonomy ceilings without mutating lifecycle state.
- Added human governance profiles and CLI (HUM-0001). Profiles live under
  `humans/proposed`, `humans/active`, and `humans/revoked`; new
  `palari human create|list|show|lint|adopt|revoke` commands model governance
  roles, skills, authority ceilings, capacity, and constraints without
  granting agent authority or adding surveillance behavior.
- Added workflow artifacts and CLI (WFU-0001). Workflows live under
  `workflows/proposed`, `workflows/active`, and `workflows/closed`; new
  `palari workflow create|list|show|lint|adopt|close` commands manage the
  artifact lifecycle above tickets without executing work or granting
  authority.
- Added the R5 governance risk tier (COS-0001). Ticket creation, lint/report
  gates, evidence scoring, dashboard readiness checks, role risk ranking, root
  role authority, model routing, config/schema docs, and tests now recognize
  R5 as a human-gated governance/kernel tier that routes to `frontier` by
  default.
- Added the Company AI OS doctrine contract (COS-0000). The contract records
  the roadmap boundary for workflows above tickets, Human Governance Load,
  human governance coverage, policy simulation, broker-controlled side effects,
  R5 governance/kernel protection, and outcome learning without changing
  runtime behavior.
- Imported optional OpenRouter/model-routing support (POS-0056). Tickets can
  resolve to `fast`, `balanced`, or `frontier` model classes by risk tier,
  inspect routing with `palari model routes|show`, override via `model_hint`,
  and record the resolved model in executor evidence. The OpenRouter executor
  is opt-in, stdlib-only, allowlist-gated, key-from-env only, offline-testable,
  and produces text artifacts rather than mutating repo files.
- Added the Python fast snapshot adapter (POS-0056) for `snapshot --json`,
  `status [--next]`, and `web --check`, with legacy Bash fallback via
  `PALARI_SNAPSHOT_ENGINE=bash`. Dashboard refreshes can import the fast
  snapshot directly, and executor evidence/refusals now surface in the review
  panel.
- Added POS-0056 tests for model routing, OpenRouter dry/offline behavior,
  fast-path performance, dashboard executor evidence, gate fast snapshots, and
  README asset checks outside a git checkout.
- Fixed sandbox demo/test baseline cleanliness (POS-0055). `palari sandbox
  create` now commits files produced by the sandbox's own `palari init`, so
  `sandbox list` and `sandbox inspect` start from a clean local sandbox after
  creation even when release archives omit governed history directories.
- Added a mock-agent refusal demo fixture (POS-0054). `palari demo
  --agent-refusal` writes `DEM-0003`, a blocked ticket with preserved
  mock-executor evidence showing a forbidden `.env` write attempt refused by
  scope-check. This complements the real deterministic mock executor tests
  without invoking an AI tool, network, or credentials.
- Made the default dashboard snapshot fast (POS-0053). `palari snapshot --json`
  and `palari web --check` now return the live operator view: active tickets,
  lightweight role rows, evidence/report presence, and shallow role diagnostics.
  Use `--full` for closed tickets, full report diagnostics, and full role lint.
- Fixed README asset packaging for release/source archives (POS-0052). README
  `assets/readme/*` references are now checked by `tests/run-readme-assets.sh`
  and PNG README assets are no longer blanket `export-ignore`d.
- Fixed external Palari package invocation for adoption flows (POS-0051).
  `bin/palari` now resolves its own package root before falling back to a
  caller git root, and `scripts/palari` pins `PALARI_ROOT`. This makes
  `/path/to/palari/bin/palari adopt /path/to/target --dry-run` work from the
  target repo or any other current directory. Regression coverage lives in
  `tests/run-adoption.sh`.
- Packet skill polish from review findings (POS-0049): duplicate `--skill`
  values are deduplicated at ticket creation, packets with declared-but-
  missing skills no longer also print "none declared", and the excerpt
  pointer only appears when the skill body actually exceeds the excerpt cap.
- Added Codex as a governed executor (POS-0048). `palari agent run TICKET-ID
  --executor codex [--dry-run]` runs Codex through the shared lifecycle
  (worktree, packet, evidence, scope-check, ci); the current `codex exec`
  invocation is isolated in one shim function. New `palari codex doctor`
  reports readiness (AGENTS.md, CLI, prompts, executor entry point) and
  `palari codex install` wraps the prompt installer. Validated by
  `tests/run-agent-codex.sh` (dry-run based; no Codex CLI or network
  required).
- Added a deterministic mock executor (POS-0047). `palari agent run TICKET-ID
  --executor mock --scenario safe|forbidden-path|outside-scope` runs the full
  governed lifecycle (worktree, packet, evidence, scope-check, ci) with a
  scripted local edit instead of an AI tool, so the headline behavior -
  executor touches `.env`, scope-check refuses, evidence preserved, ticket
  state not advanced - is demonstrable and CI-testable with no network or
  credentials. Executor invocation now lives behind per-executor shims
  (describe + run) sharing one lifecycle; the opencode contract is unchanged.
  Validated by `tests/run-agent-mock.sh`.
- Tickets can declare governing skills and packets carry them (POS-0046).
  `palari ticket create --skill NAME` writes `related_skills` frontmatter
  (creation fails on unknown names); `palari packet` injects a Relevant
  Skills section with each skill's description and a capped excerpt;
  `palari lint` warns on dangling references. Also tightened the skill-lint
  authority heuristic with word boundaries so benign wording (pushback,
  acceptance, merged) no longer trips it. Skills stay advisory: packets carry
  them, tickets scope, gates enforce.
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
