# POS-0100 Technical Report

## Session

- Ticket: POS-0100
- Role: implementation
- Branch: ticket/POS-0100
- Target branch: main
- Result: implemented and ready for verification/review

## Files Changed

```text
README.md
contracts/authority-and-lifecycle.md
humans/active/HUMAN-ADMIN-admin.md
lib/palari/ci_accept.bash
lib/palari/humans.bash
tests/palari_acceptance.bats
tickets/open/POS-0100-stable-actor-identity-for-acceptance.md
reports/POS-0100-technical-report.md
reports/human/POS-0100-human-report.md
```

## Outcome

- Added stable human identity support through optional `person_id` frontmatter.
- New human profiles created by `palari human create` now include a default
  `person_id` equal to the human ID.
- Active human profiles can be resolved by human ID, display name, or declared
  alias during acceptance.
- Acceptance actor comparison now uses stable identity:
  - `person:<person_id>` when a profile declares `person_id`
  - `human:<id>` when no `person_id` is present
  - `actor:<label>` only for labels that do not resolve to active human profiles
- Founder/admin labels in the default `HUMAN-ADMIN` profile now resolve to the
  same stable `PERSON-QUETZA` identity.
- Self-acceptance and human quorum checks now reject actor labels that map to
  the same stable person identity.
- Failure messages name the shared stable identity so the profile/config issue
  is visible.
- Human lint now validates non-empty `person_id` values.
- README and the authority/lifecycle contract document stable human identity and
  alias behavior.

## Verification

- Passed:
  - `bash -n lib/palari/ci_accept.bash lib/palari/humans.bash tests/run-human-governance.sh tests/run-risks.sh`
  - `shfmt -d lib/palari/ci_accept.bash lib/palari/humans.bash tests/run-human-governance.sh tests/run-risks.sh`
  - `shellcheck -x bin/palari scripts/palari lib/palari/ci_accept.bash lib/palari/humans.bash tests/run-human-governance.sh tests/run-risks.sh`
  - `bats tests/palari_acceptance.bats`
  - `./tests/run-human-governance.sh`
  - `./tests/run-risks.sh`
  - `git diff --check`

## CI Evidence

- Pending final Palari CI/evidence run for POS-0100.

## Boundaries

- Did not change policy acceptance behavior.
- Did not change broker behavior or enable broker side effects.
- Did not change risk scoring, evidence scoring, adoption behavior, secrets,
  dependencies, lockfiles, runtime state, deployment, push, merge, or acceptance
  bookkeeping for existing tickets.
- Did not implement a broader human profile migration beyond adding default
  `person_id` on new profile creation and validating declared values.

## Residual Risks

- Existing profiles without `person_id` continue to derive identity from their
  human ID. If two legacy profiles represent the same person but lack a shared
  `person_id`, they remain distinct until a later migration or manual profile
  update.
- Alias resolution is limited to active human profiles. Proposed or revoked
  profiles do not participate in acceptance authority.

## Risks / Follow-Ups

- A later migration ticket could normalize `person_id` across all historical
  human profiles if the repo wants stronger legacy identity guarantees.
- A later UX ticket could expose alias/person identity conflicts in `palari
  human lint` or status output before acceptance time.
