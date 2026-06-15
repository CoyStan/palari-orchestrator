# POS-0066 Reviewer Note

Note: sections before "Design Amendment" preserve the historical review trail
for the earlier hard-coded dual-human implementation. The current amended
design is the configurable human approval quorum described under "Design
Amendment" and any later re-review sections.

## Review Result

Reopen

## Findings

- P1: The POS-0066 blocker repair changed
  `adapters/snapshot/fast_snapshot.py`, but the POS-0066 scope contract did
  not list that path in `allowed_paths`. `./bin/palari scope-check POS-0066
  --base HEAD~1` failed with `adapters/snapshot/fast_snapshot.py` outside
  allowed paths.
- Functional R5 behavior looked correct: the fast snapshot/operator next action
  now showed `./bin/palari accept POS-0066 --by HUMAN-ONE --co-by HUMAN-TWO`;
  `./bin/palari evidence score POS-0066` was ready and showed the same command.
- Acceptance enforcement still required `--by` and `--co-by`, distinct active
  R5 human profiles, `may_approve_policy_changes: true`, and no claimant or
  implementer acceptor.
- Policy acceptance remained simulation-only and ForgeGate did not replace
  human approval.
- No active R5 human profiles existed for eventual acceptance.

## Verification Reviewed

- Fresh-context review by Erdos subagent on 2026-06-15.
- Inspected current stacked worktree
  `/home/quetza/palari-orchestrator-worktrees/POS-0097`.
- Ran/inspected:
  - `./bin/palari scope-check POS-0066 --base HEAD~1`
  - `./bin/palari snapshot --json`
  - `./bin/palari evidence score POS-0066`
  - `./bin/palari doctor secure`

## Required Changes

- Add `adapters/snapshot/fast_snapshot.py` to POS-0066 `allowed_paths`.
- Refresh POS-0066 evidence against the final repair commit.
- Re-run fresh-context review.

## Recommendation

Do not accept POS-0066 until the scope contract includes the changed fast
snapshot path and evidence/re-review are refreshed. POS-0066 is R5 and must not
be self-accepted by an agent.

## Evidence Notes

- R5 one-acceptor path fails.
- R5 same-human twice path fails.
- R5 R2 co-acceptor path fails.
- R5 two-authorized-human path passes and records `co_accepted_by` plus `acceptance_mode: human_dual`.

## Historical Re-review Result

Accept-ready after bounded repair.

## Historical Re-review Findings

- No blocking code findings remained after adding
  `adapters/snapshot/fast_snapshot.py` to the POS-0066 allowed paths.
- Fast snapshot, status, and evidence score now consistently show the R5
  dual-human command:
  `./bin/palari accept POS-0066 --by HUMAN-ONE --co-by HUMAN-TWO`.
- R5 acceptance enforcement still requires two distinct active authorized human
  profiles. Policy acceptance remains simulation-only and ForgeGate does not
  replace human approval.
- Operational blocker for eventual acceptance: no active human profile markdown
  files currently exist under `humans/active`, so two R5-authorized active
  profiles must be created or adopted before POS-0066 can actually be accepted.

## Historical Re-review Verification

- Fresh-context re-review by Laplace subagent on 2026-06-15.
- Inspected current stacked worktree
  `/home/quetza/palari-orchestrator-worktrees/POS-0097`.
- Ran/inspected:
  - `./bin/palari status --next`
  - `./bin/palari snapshot --json`
  - `./bin/palari evidence score POS-0066 --strict`
  - `./bin/palari scope-check POS-0066 --base HEAD~2`
  - `./bin/palari doctor secure`
  - `bats tests/palari_acceptance.bats`
  - `find humans -maxdepth 3 -type f -name '*.md' -print | sort`

## Historical Re-review Recommendation

Do not reopen for code. Leave POS-0066 in-review until two authorized active
R5 human profiles exist, then use exactly:
`./bin/palari accept POS-0066 --by HUMAN-ONE --co-by HUMAN-TWO`.

## Design Amendment

Superseded on 2026-06-15 by founder direction to make human approvals
configurable by risk tier instead of hard-coding dual-human R5 acceptance.

The prior accept-ready re-review remains preserved as reviewer trail for the
old dual-human implementation, but it is no longer the final approval evidence
for POS-0066. The amended POS-0066 design is:

- `governance.required_human_approvals` declares the active human-profile
  quorum per risk tier.
- The current solo-founder repo config sets `R5: 1`, so one active
  R5-authorized human profile is enough for R5 acceptance.
- Team repos may raise R5, or any other risk tier, to `2` or more; `palari
  accept` supports repeated `--co-by` values and validates distinct active
  profiles.
- Policy acceptance remains simulation-only and ForgeGate remains separate
  from human approval.

A fresh-context re-review is required against the amended quorum design before
POS-0066 can be considered accept-ready again.

## Amended Quorum Re-review Result

Reopen.

## Amended Quorum Re-review Findings

- P2: Code and evidence for the configurable quorum path looked sound, but
  stale live ticket/report wording still described R5 as hard-coded
  dual-human. The reviewer cited POS-0077 ticket/report wording and POS-0067
  report wording.
- Confirmed good: current config sets `R0` through `R4` to `0` required human
  approvals and `R5` to `1`; status, snapshot, evidence score, and secure
  doctor show the one-human R5 command and enforced quorum.
- Confirmed good: tests cover R5 quorum `1`, R5 quorum `2`, distinct active
  profile validation, R2 rejection, simulation-only policy acceptance, and
  Human Governance Debt behavior under configured quorum.
- Residual operational blocker: no active human profile markdown files exist
  under `humans/active`, so eventual POS-0066 acceptance still needs one active
  R5-authorized human profile.

## Amended Quorum Re-review Verification

- Fresh-context re-review by Lagrange subagent on 2026-06-15.
- Ran/inspected:
  - `./bin/palari status --next`
  - `./bin/palari evidence score POS-0066 --strict`
  - `./bin/palari doctor secure`
  - `./bin/palari scope-check POS-0066`
  - `./tests/run-risks.sh`
  - `./tests/run-secure-doctor.sh`
  - `./tests/run-human-governance-load.sh`
  - `bats tests/palari_acceptance.bats`
  - `find humans -maxdepth 3 -type f -name '*.md' -print | sort`

## Amended Quorum Required Changes

- Update stale POS-0067 and POS-0077 live ticket/report wording so it describes
  configured human-quorum behavior rather than hard-coded R5 dual-human
  acceptance.
- Re-run focused checks and fresh-context review.

## Final Amended Quorum Re-review Result

Accept-ready.

## Final Amended Quorum Re-review Findings

- No blocking findings. The prior reopen issue is fixed.
- POS-0067 and POS-0077 live wording now describes configured human-quorum
  behavior rather than hard-coded R5 dual-human behavior.
- The only remaining dual-human wording is POS-0066's own explicit historical
  or fix wording.
- Residual operational blocker: no active human profile markdown files exist
  under `humans/active`; actual acceptance still requires one active
  R5-authorized profile for the configured `R5: 1` quorum.

## Final Amended Quorum Re-review Verification

- Fresh-context re-review by Parfit subagent on 2026-06-15.
- Ran/inspected:
  - `git status --short`
  - `./bin/palari status --next`
  - `./bin/palari evidence score POS-0066 --strict`
  - `./bin/palari doctor secure`
  - `./bin/palari scope-check POS-0066`
  - `./bin/palari report-lint POS-0066`
  - `./bin/palari lint POS-0066`
  - `reports/evidence/POS-0066/manifest.json`
  - `find humans -maxdepth 3 -type f -name '*.md' -print | sort`

## Final Amended Quorum Recommendation

Leave POS-0066 accept-ready and in-review. Do not reopen for code. After one
active R5-authorized human profile exists, acceptance can proceed with:
`./bin/palari accept POS-0066 --by HUMAN-ONE`.
