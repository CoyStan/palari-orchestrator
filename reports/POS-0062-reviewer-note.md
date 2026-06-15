# POS-0062 Reviewer Note

## Review Result

Reopen

## Findings

1. P1: HGL/planning do not implement the new R3 risk-source gate documented by
   POS-0062. `contracts/human-governance-load.md` says an R3 risk source
   without expected human decision coverage and without an exception should make
   the gate yellow. But `adapters/planning/hgl.py` only creates gaps for
   `>= R4`; the later `== R3` branch is therefore unreachable for R3 gaps. A
   temporary workflow with `risk_ceiling: R3`, an R3 work unit, no expected
   decisions, and no exception produced `launch_gate=green` and
   `risk_coverage_gaps=[]`. That contradicts the HGL contract added in this
   commit.
2. P1: POS-0062 CI evidence is stale for the reviewed commit. The target commit
   is `b44e8d3d1fd090ebb44390e825011d6d6802e4ee`, but
   `reports/evidence/POS-0062/manifest.json` records `head_sha` as
   `35060c9b38300f15961f1913c31ee41a48e751d0`, the parent commit. The artifact
   hashes match the manifest, but the manifest does not attest the commit under
   review.

## Verification Reviewed

- Inspected the ticket, parent diff, source, tests, contracts, technical report,
  human report, placeholder reviewer note, JUnit, SARIF, verification log, and
  manifest.
- Ran locally:
  - `./bin/palari workflow lint`
  - `./tests/run-workflows.sh`
  - `./tests/run-workflow-planning.sh`
  - `./tests/run-human-governance-load.sh`
  - `./tests/run-company-os-snapshot.sh`
  - `./tests/run-company-os-demo.sh`
  - `bash -n lib/palari/workflows.bash`
  - `git diff --check 35060c9 b44e8d3`
- All listed commands passed.
- Manual temporary-fixture checks confirmed R4/R5 declared risk prevents
  high/full autonomy, R5 work-unit lint fails without decision coverage, and R3
  lint exception suppression works.
- Reviewer did not run `./bin/palari ci POS-0062` because it writes evidence
  files.

## Scope / Safety

- The diff is limited to allowed POS-0062 surfaces: planning adapters, workflow
  lint, contracts, tests, ticket/report/evidence files.
- No changes to forbidden paths, secrets, deploy/prod paths, dependencies,
  lockfiles, policy acceptance, broker behavior, or unrelated implementation
  surfaces were found.
- Worktree remained clean; reviewer did not edit, accept, commit, or push.

## Required Changes

1. Implement the documented R3 HGL/planning behavior: uncovered R3 risk sources
   without an exception should appear in `risk_coverage_gaps`, make the launch
   gate yellow, and surface a planning recommendation.
2. Add tests for both no-exception and exception cases.
3. Refresh POS-0062 evidence so the manifest/report clearly attest the reviewed
   head, not the parent commit.

## Recommendation

Reopen POS-0062. The R4/R5 autonomy and workflow lint behavior is mostly
correct, but the R3 HGL contract mismatch and stale POS-0062 evidence block
acceptance.

The known upstream POS-0060 and POS-0061 reopen findings are separate from this
review, but they still block overall stack acceptance until resolved. POS-0062
also has its own blockers, so the stack is not accept-ready.

## Evidence

- `reports/evidence/POS-0062/verification.log`
- `reports/evidence/POS-0062/junit.xml`
- `reports/evidence/POS-0062/palari.sarif`
- `reports/evidence/POS-0062/manifest.json`

---

## Fresh-Context Re-Review After Repair

Review result: Accept-ready.

Reviewer: Ohm subagent, 2026-06-15.

Scope reviewed:

- Latest stacked worktree `/home/quetza/palari-orchestrator-worktrees/POS-0097`.
- Repair commit `42ddc865c70d9d5b7d5adcaeeccbfceb6af25421`.
- `adapters/planning/hgl.py`
- `tests/run-workflow-planning.sh`
- `reports/evidence/POS-0062/manifest.json`
- `reports/evidence/POS-0062/verification.log`

Findings:

- No reopen findings.
- Uncovered R3 workflow ceiling and R3 work-unit sources now emit
  `risk_coverage_gaps` when no exception exists.
- `human_decision_exceptions` suppresses the R3 gap as documented.
- R4/R5 gap behavior remains independent of the R3 exception path.

Verification:

- `./tests/run-workflow-planning.sh` passed.
- Refreshed POS-0062 evidence records commit
  `42ddc865c70d9d5b7d5adcaeeccbfceb6af25421`, status `passed`, 6 tests, 0
  failures.

Caveat:

- This is stacked-branch evidence refreshed with `--base HEAD`; it attests the
  final stacked repair commit, not an isolated POS-0062-only branch diff.
