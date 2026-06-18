# POS-0099 Technical Report

## Session

- Ticket: POS-0099
- Role: implementation
- Branch: ticket/POS-0099
- Target branch: main
- Result: implemented and ready for verification/review

## Files Changed

```text
README.md
bin/palari
contracts/adoption.md
lib/palari/init_adopt.bash
tests/run-adoption.sh
tickets/open/POS-0099-governed-bootstrap-adoption-lifecycle.md
reports/POS-0099-technical-report.md
reports/human/POS-0099-human-report.md
reports/evidence/POS-0099/
```

## Outcome

- Added `palari adopt plan TARGET --out FILE`.
- The generated plan records:
  - `type: bootstrap-adoption-plan`
  - `status: proposed`
  - source path
  - source SHA/ref when available
  - source manifest hash for the copied substrate files
  - target path
  - target HEAD
  - CI/hooks/force intent
  - imported/write path manifest, including init-created `.gitkeep` files,
    target-configured Palari directories, `AGENTS.palari.md`, `.gitignore`,
    lock storage, and optional CI/hooks outputs
  - excluded paths
  - excluded foreign governance artifacts
  - downstream customization boundaries
- Non-dry-run `palari adopt TARGET` now fails closed unless `--plan FILE` is
  provided.
- A plan must be `status: approved` or `status: accepted` before adoption writes
  target files.
- Adoption validates that the plan source and target match the current command.
- Adoption validates that the target repository HEAD still matches the reviewed
  plan before writing.
- Adoption validates that copied source content still matches the approved plan
  before writing, so dirty source-tree edits and copied symlink changes after
  approval fail closed.
- Adoption validates that the target worktree is still clean before a plan is
  generated and again before any approved non-dry-run write, including ignored
  files that overlap planned adoption writes.
- Adoption validates that the reviewed path manifest exactly matches the writes
  implied by the command flags and target config.
- Adoption validates that approved plan flags (`with_ci`, `with_hooks`, and
  `force`) match the actual write command.
- Approved plans must include `approved_by` and `approved_at`.
- Adoption validates that the plan still includes foreign-governance-artifact
  exclusions.
- Dry-run adoption remains available without a plan as a no-write preview.
- README and the adoption contract now describe the preview -> plan -> human
  approval -> adopt flow.

## Verification

- Passed:
  - `bash -n lib/palari/init_adopt.bash tests/run-adoption.sh tests/run-cli-structure.sh`
  - `./tests/run-adoption.sh`
  - `./tests/run-cli-structure.sh`
  - `./tests/run-golden.sh`
  - `shellcheck -x bin/palari scripts/palari tests/run-adoption.sh lib/palari/init_adopt.bash`
  - `shfmt -d bin/palari lib/palari/init_adopt.bash tests/run-adoption.sh tests/run-cli-structure.sh`
  - `git diff --check`
- Added repair coverage after initial fresh review:
  - source substrate changes after plan approval fail before writing through
    `source_manifest_hash`.
  - missing `excluded_foreign_governance_artifacts` entries fail before
    writing.
  - missing approval metadata fails before writing.
  - `--force` and `--ci` command/plan mismatches fail before writing.
- Added repair coverage after second fresh review:
  - the generated `path_manifest` includes init-created files, lock storage,
    `AGENTS.palari.md`, `.gitignore`, and optional CI/hooks writes.
  - modifying source substrate files after plan approval changes
    `source_manifest_hash` and fails before writing.
- Added repair coverage after a timed fresh-review probe:
  - committing to the target repo after plan generation changes `target_head`
    and fails before writing.
  - plans for targets with existing custom Palari directory config list the
    effective target-configured init directories, not the source/default ones.
- Added repair coverage after a second timed fresh-review probe:
  - committing only the approved plan artifact in the source repo does not block
    adoption when copied substrate content is unchanged.
  - trimming the reviewed path manifest while keeping command flags unchanged
    fails before writing.
- Added repair coverage after a final fresh-context review:
  - adding a copied source symlink after approval changes `source_manifest_hash`
    and fails before writing.
  - adding an untracked target `bin/palari` after approval fails as target
    worktree drift before the target binary can run.
  - shellcheck now covers the adoption module directly.
- Added repair coverage after a fresh-context re-review:
  - an ignored target `bin/palari` hidden by `.git/info/exclude` fails as
    target worktree drift before it can run.
- Added repair coverage after a second fresh-context re-review:
  - an empty but valid git target records `target_head: "unavailable"` instead
    of malformed unborn-HEAD text and can still be adopted when unchanged.
- Added repair coverage after a later fresh-context re-review:
  - ignored target parent directories, such as `tickets/`, fail as target
    worktree drift when they could hide files under planned adoption writes.

## CI Evidence

- CI run: `./bin/palari ci POS-0099`
- Evidence bundle: `reports/evidence/POS-0099/`
- JUnit: `reports/evidence/POS-0099/junit.xml`
- SARIF: `reports/evidence/POS-0099/palari.sarif`
- Manifest: `reports/evidence/POS-0099/manifest.json`
- CI result: passed
- Initial strict evidence score: 85/100, `needs-review`, because the fresh
  reviewer note is not yet present.

## Boundaries

- Did not change secrets, dependencies, lockfiles, runtime state, deployment
  config, broker behavior, policy acceptance behavior, push, merge, or deploy
  behavior.
- Did not implement downstream artifact curation beyond recording excluded
  foreign governance artifacts in the plan. That is reserved for a later ticket.
- Did not change actor identity or acceptance authority behavior.

## Residual Risks

- The plan approval is a plain repo-native artifact check, not a cryptographic
  signature.
- Direct manual `rsync`/shell copying outside Palari cannot be prevented by the
  CLI; this ticket makes the Palari-supported adoption path governed and
  fail-closed.
- Initial fresh-context review found two low-severity bounded gaps: missing
  validation for `excluded_foreign_governance_artifacts` and no source-content
  drift regression. Both were repaired before final review.
- Second fresh-context review found two blocking gaps: command flags were not
  bound to reviewed plan flags, and blank approver metadata passed. Both were
  repaired before final review.
- Third fresh-context review found two blocking gaps: the plan manifest did not
  enumerate all write classes, and the approved source SHA did not catch dirty
  source-tree edits after plan approval. Both were repaired before final review.
- A later fresh-context review timed out before a final verdict, but surfaced two
  concrete probes: target `HEAD` drift after plan generation was not rejected,
  and custom target Palari directory config made the path manifest inaccurate.
  Both were repaired before final review.
- Another fresh-context review timed out before a final verdict, but surfaced two
  concrete probes: the path manifest could be truncated without blocking writes,
  and committing the approved plan artifact itself changed `source_sha` even
  though copied source content was unchanged. Both were repaired before final
  review.
- Final fresh-context review found two blocking gaps: the target worktree could
  drift through untracked files without changing `target_head`, and copied
  symlinks were not included in `source_manifest_hash`. Both were repaired
  before final review.
- Fresh-context re-review found one blocking gap: ignored target files could
  overlap planned adoption writes without appearing in ordinary git status.
  This was repaired before final review.
- Second fresh-context re-review found one bounded gap: empty target repos with
  unborn `HEAD` values recorded malformed `target_head` text. This was repaired
  before final review.
- Later fresh-context re-review found one bounded gap: ignored parent
  directories such as `tickets/` could hide already-present governance files
  that become active after adoption. This was repaired before final review.

## Risks / Follow-Ups

- Follow-up ticket: downstream adoption boundary work should prevent upstream
  project history, reports, evidence, and self-tests from becoming active
  downstream governance by default.
- Follow-up ticket: stable actor identity should make the human approval record
  stronger than display-name strings.
