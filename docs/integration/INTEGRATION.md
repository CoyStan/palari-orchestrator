# Forgegate Integration: Criteria and Outcome

This document defines, before any code judgment is trusted, what it means to
integrate `forgegate` into `palari-orchestrator`, what counts as objectively
worse and therefore must be replaced, and what it means for the operator
console to be a great dashboard. Every item is a checkbox so the work is
auditable against its own definition.

## Part 1. What "integrate both repos, take the best of each" means

### 1.1 Direction of the merge

- [x] `palari-orchestrator` remains the host repository, brand, lifecycle, and
      operator surface. It is the product.
- [x] `forgegate` is vendored unchanged as the trusted verification kernel at
      `gate/`. The kernel stays small, auditable, and byte-identical to the
      donor repo, including its full adversarial test suite.
- [x] Nothing from either repo is silently dropped. Every removal or
      demotion is listed in section 1.4 with the reason.

### 1.2 Objectively worse pieces of palari-orchestrator, replaced

"Objectively worse" means: for the same job, forgegate's mechanism defeats an
attack that the palari mechanism does not, with no capability lost. Each row
below names the job, the old mechanism, the attack it failed, and the
replacement.

- [x] **Acceptance integrity.** Old: `palari accept` trusted an unsigned
      `manifest.json` whose sha256 entries any actor with write access could
      regenerate. Attack: an implementer fabricates a passing evidence bundle
      and a fresh manifest in one commit. New: when the gate is enabled,
      acceptance additionally requires a cryptographic verdict from the
      forgegate kernel: signed attestations for implement, test, and review,
      token chains that verify to the repository root key, hash flow between
      steps, and commit binding. The manifest check is kept as defense in
      depth, but it is no longer the authority.
- [x] **Actor identity.** Old: identity was a `--by NAME` string compared
      case-insensitively. Attack: claim as `agent-a`, accept as `agent-b`.
      New: identity is an Ed25519 key fingerprint. The signer must be the
      token holder, signatures are verified, and a stolen token is useless to
      any other key. The string check remains as a UX guard only and is
      documented as such.
- [x] **Dual control.** Old: self-acceptance prevention compared
      `claimed_by` and `implemented_by` strings against `--by`. Attack: use a
      different name. New: the layout's `distinct_from` rule requires the
      review attestation to be signed by a different key than the implement
      and test attestations. Renaming changes nothing; only holding a
      different private key does.
- [x] **Step linkage.** Old: the evidence bundle was flat; nothing bound the
      test run to the exact bytes that were implemented. Attack: test against
      one diff, ship another. New: hash flow. The test attestation must
      consume the implement attestation's outputs byte for byte, and review
      must consume test. The gate refuses any break in the chain.
- [x] **Commit binding.** Old: `manifest.json` carried `head_sha` and accept
      compared it to current HEAD, but the manifest itself was forgeable.
      New: the commit is inside every signed attestation body; rebinding the
      evidence to a different commit invalidates the signatures.
- [x] **Authority delegation.** Old: role authority lived in markdown
      frontmatter that lint inspects but any writer can edit. Attack: widen
      your own `allowed_paths`. New: per-ticket authority is a delegation
      token minted from the root key, attenuated to (ticket, branch, steps,
      expiry), and the kernel proves narrowing on every link of the chain.
      The markdown role system is kept for planning ergonomics; the token is
      what the gate trusts.
- [x] **Evidence freshness.** Old: none; stale evidence stayed valid forever.
      New: verification passes `verify_time` and `max_age_seconds` so
      future-dated and stale evidence are refused, with documented clock-skew
      tolerance.
- [x] **Replay and ambiguity.** Old: re-running CI overwrote evidence;
      duplicates were impossible to express but also impossible to detect at
      accept time. New: duplicate attestations for the same step are refused
      outright by the kernel; retries supersede explicitly.
- [x] **Injection stance.** Old and kept: ticket `verification:` commands are
      executed by CI; that is palari's job and stays. Adopted from forgegate:
      the accept authority never derives from ticket content. The gate reads
      tokens and attestations only; tickets are pure data to it, so injected
      instructions in a ticket cannot mint, widen, or substitute for
      authority.
- [x] **Fail-closed verification.** Old: a corrupt manifest produced a Python
      traceback path; behavior on malformed evidence was incidental. New: the
      kernel's contract is that malformed evidence of any shape produces a
      refusal with reasons, never an exception, and corrupt stored evidence
      files are skipped with a warning.

### 1.3 Best of palari-orchestrator, kept and wired through

- [x] Full ticket lifecycle: propose, adopt, create, claim with leases,
      heartbeat, ready, block, needs-human, reopen, accept.
- [x] Worktree-first isolation, scope-check, scope-overlap detection.
- [x] Role system, packets, proposals, memory adapter, opencode wrapper,
      GitHub workflow and ruleset adapters, MCP manifest, demo fixtures.
- [x] Evidence bundle formats (verification.log, junit.xml, palari.sarif,
      manifest.json) unchanged, so existing CI consumers keep working.
- [x] The operator console, now overhauled (Part 2).
- [x] Zero-dependency bash core. The gate is additive: when
      `gate.enabled: false`, every existing command behaves exactly as
      before, and the full legacy test suite passes unmodified.

### 1.4 Demotions and non-removals, with reasons

- [x] String-identity checks (`same_actor`) are demoted from security
      boundary to UX guard, not deleted, because they catch honest mistakes
      cheaply even when the gate is off.
- [x] Manifest sha256 validation is demoted from authority to defense in
      depth, not deleted, because it still catches accidental corruption with
      zero crypto dependencies.
- [x] Markdown roles are not replaced by tokens because they serve planning
      and review ergonomics that tokens do not; the two are bridged by
      `palari gate setup-ticket`, which mints step-scoped tokens for the
      implementer, CI, and reviewer identities of a ticket.
- [x] Forgegate's `code-change.yml` example layout ships alongside the
      palari-specific `palari-change.yml` so the kernel remains usable
      standalone.

### 1.5 Mechanical integration requirements

- [x] Vendored kernel at `gate/forgegate/` with its adversarial suite at
      `gate/tests/`, runnable in place.
- [x] One adapter, `adapters/gate/palari_gate.py`, owns all kernel calls:
      init, setup-ticket, grant, attest (with automatic hash-flow wiring),
      verify, and status. Bash never reimplements crypto.
- [x] One bash module, `lib/palari/gate.bash`, exposes `palari gate ...`,
      gates `palari accept`, and feeds the snapshot.
- [x] Attestations are stored inside the existing evidence tree at
      `reports/evidence/<ID>/gate/attestations/` so they travel with the
      bundle through CI artifact upload.
- [x] Private keys live under `.palari/gate/keys/` and are gitignored; only
      the root public key is repo-visible.
- [x] `palari.config.yaml` and the JSON schema gain a `gate:` block with
      `enabled`, `layout`, `keys_dir`, `root_pub_file`, `token_validity_days`,
      `max_age_seconds`, and `ci_key`.
- [x] `palari ci` auto-attests the test step when the gate is enabled, the CI
      key exists, and the implement step is already attested; otherwise it
      prints the exact next command.
- [x] `palari accept` fails closed: if the gate is enabled but the kernel is
      unavailable (missing python3 or cryptography), acceptance is refused,
      never silently downgraded.
- [x] `palari snapshot --json` gains a `gate` section (enabled, availability,
      root fingerprint, layout, per-ticket step attestations and verdicts) so
      the console renders the chain without a second backend.
- [x] `palari doctor` reports gate health.
- [x] CLI help, README, CHANGELOG, and a new contract
      (`contracts/signed-acceptance.md`) document the boundary, the threat
      model inherited from forgegate, and the backdating rule that verify is
      always called with both `verify_time` and `max_age`.
- [x] Tests: kernel suite wrapper (`tests/run-gate-kernel.sh`), end-to-end
      governance test (`tests/run-gate.sh`) covering the honest path,
      forged-step refusal, tamper refusal, same-key review refusal, and
      accept integration both enabled and disabled.
- [x] CI workflow (`.github/workflows/test.yml`) runs both new suites.
- [x] All pre-existing test scripts pass unmodified except the dashboard
      rubric, which is intentionally rewritten with the new console.

## Part 2. What a great operator dashboard means

The console's single job: show the operator what needs them next, and prove
that the evidence behind a ticket is real before they accept it.

### 2.1 Truth and trust

- [x] Renders only repository truth via `palari snapshot --json`; no parallel
      state, no writes, copy-only commands.
- [x] Chain of custody is a first-class visual: implement, test, review as
      sealed steps with signer fingerprints, hash-flow links, and the gate
      verdict with its exact refusal reasons.
- [x] The root key fingerprint is visible so an operator can compare it
      out of band.
- [x] Unsigned and gate-disabled states are honest: the console says the
      acceptance is honor-system, it never fakes a green seal.
- [x] Evidence artifacts are listed per ticket with presence states, and
      missing evidence is a named warning with the exact command to fix it.

### 2.2 Operator speed

- [x] Five-second orientation: project, health grade, and the single next
      action are visible without scrolling on a laptop viewport.
- [x] Three work surfaces over one dataset: a triage queue, a pipeline board
      grouped by lifecycle stage, and a full ledger table; one click or
      keystroke switches.
- [x] Every ticket row answers: who owns it, what risk, what stage, is the
      evidence real, what is the next command.
- [x] Live lease countdowns tick in place and flip to a warning state when a
      claim expires.
- [x] Scope overlaps, stale claims, missing evidence, role lint issues, and
      workflow gaps surface as actionable warnings, each with a copyable
      command.
- [x] Search across id, title, owner, role, paths, and status; filters by
      queue; both combine.
- [x] Keyboard-first: `/` focuses search, `j`/`k` move the selection,
      `1`/`2`/`3` switch surfaces, `Enter` opens the dossier, visible focus
      everywhere.
- [x] Auto-refresh on a quiet interval that pauses when the tab is hidden,
      plus a manual refresh that bypasses the snapshot cache.

### 2.3 Craft

- [x] A deliberate visual identity, not a template: a ledger-and-seal
      language where cryptographic truth has its own color reserved for
      nothing else, monospace for every fingerprint, hash, and command, and
      one signature element (the custody rail with its verdict stamp).
- [x] Light and dark themes from one token sheet, persisted choice,
      `prefers-color-scheme` respected on first load.
- [x] AA contrast for text and state colors in both themes, enforced by the
      rubric test, not by eyeball.
- [x] Responsive from 320px to wide desktop with no horizontal scroll; the
      board degrades to stacked lanes, the table to labeled cards.
- [x] Reduced-motion users get a still console; the only persistent motion
      (lease tick, live pulse) is disabled under the media query.
- [x] Accessible by structure: skip link, landmarks, aria-live status
      announcements, table semantics preserved on mobile, buttons are
      buttons.
- [x] Empty states direct action; error states name the failure and offer
      retry; loading states never block the whole shell.
- [x] No network dependencies: no CDN fonts or scripts; the console works
      fully offline on loopback.
- [x] The dashboard rubric test (`tests/run-dashboard-rubric.sh`) encodes all
      of the above as greppable and computable checks, including contrast
      math, so regressions fail CI.

## Part 3. Verification of this document

- [x] Kernel adversarial suite passes in the vendored location.
- [x] End-to-end gate test passes: honest chain accepted, forged test step
      refused, tampered evidence refused, same-key review refused, accept
      blocked on refusal, accept succeeds on a verified chain.
- [x] Entire legacy suite passes: cli-structure, adoption, proposals, roles,
      agent-wrapper, authority-lifecycle, github-ci, golden, demo, memory.
- [x] Dashboard rubric passes against the new console.
- [x] `palari web --check` emits a snapshot containing the `gate` section.
- [x] The console was rendered and visually inspected at 1280, 768, and 375
      widths in both themes.
