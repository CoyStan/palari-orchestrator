# POS-0064 Reviewer Note

## Review Result

Reopen

## Findings

- P1: Snapshot truthfulness still fails open for newly added governance
  aggregates. `policy_candidate_count()` returns `0` on read/parse errors,
  `broker_summary()` skips unreadable or invalid broker summaries, and
  invalidated outcome counting skips unreadable/malformed outcome files. These
  paths make policy candidates, broker observations, broker side-effect
  evidence, tickets with broker evidence, and invalidated outcomes look
  healthier than reality instead of reporting unknown/error state.
- P1: Active workflow analysis failures are silently omitted from workflow items
  and governance totals. The snapshot counts active workflow files, but if
  parsing or HGL analysis fails, the workflow is excluded from `workflows.items`,
  risk sources, missing skills, bottlenecks, HGL totals, capacity warnings, and
  launch-gate counts with no error field. That directly violates the POS-0064
  truthfulness requirement for workflow risk sources and capacity state.
- P1: The Bash/full snapshot wrapper still has a silent legacy fallback. If the
  Python company OS helper is unavailable or exits nonzero, stderr is discarded
  and the wrapper emits the old empty Company OS schema, missing POS-0064 fields
  such as coverage gaps, capacity warnings, active/proposed policy counts,
  broker observations, broker evidence tickets, and outcomes. This is exactly
  the kind of fail-open snapshot behavior POS-0064 is supposed to remove.
- P2: The committed CI evidence does not attest commit `9bff398`. The manifest
  records `head_sha` as the parent `61df72d...`, and the verification log
  captured an uncommitted dirty worktree. Reviewer reran the relevant
  non-writing checks locally, but the committed evidence bundle is stale for the
  reviewed commit.

## Verification Reviewed

- Reviewed ticket, technical report, POS-0064 diff from parent, implementation,
  changed tests, and committed evidence files.
- Ran and passed:
  - `python3 -m py_compile adapters/planning/company_os_snapshot.py`
  - `./bin/palari snapshot --json`
  - `./bin/palari web --check`
  - `PALARI_SNAPSHOT_ENGINE=bash ./bin/palari snapshot --json`
  - `./bin/palari snapshot --json --full`
  - `./tests/run-company-os-snapshot.sh`
  - `./tests/run-company-os-demo.sh`
  - `./tests/run-dashboard-rubric.sh`
- Reviewer did not run `./bin/palari ci POS-0064` because it writes evidence
  artifacts; inspected the committed CI bundle instead.

## Scope / Safety

- Diff is limited to POS-0064 allowed implementation, tests, ticket/report, and
  evidence paths.
- No policy acceptance, broker side effects, dashboard redesign, deploy path,
  secrets, dependency files, lockfiles, or unrelated surfaces changed.
- Worktree remained clean after review.

## Required Changes

- Remove silent zero/empty fallback behavior for governance sources. Broken or
  unreadable workflows, policy inputs, broker summaries, and outcomes must
  either fail the snapshot or be explicitly reported as errors/unknowns in
  `company_os`.
- Ensure active workflow analysis failures cannot disappear from
  `workflows.items`, HGL totals, risk sources, missing skills, bottlenecks,
  capacity warnings, or autonomy counts.
- Update the Bash/full snapshot fallback so it does not emit the legacy
  healthy-empty Company OS schema when the Python helper fails.
- Regenerate or provide fresh CI evidence that attests the final reviewed commit
  after fixes.

## Recommendation

Do not accept POS-0064. Reopen it on its own merits for snapshot truthfulness
failures. The known reopen findings in POS-0060 through POS-0063 also block
stack acceptance independently; this stack should not be accepted until those
upstream issues and the POS-0064 findings above are resolved.

## Evidence

- `reports/evidence/POS-0064/verification.log`
- `reports/evidence/POS-0064/junit.xml`
- `reports/evidence/POS-0064/palari.sarif`
- `reports/evidence/POS-0064/manifest.json`
