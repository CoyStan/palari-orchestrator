# POS-0028 Reviewer Note

## Review Result

Decision: accept

## Summary

Reviewed POS-0028 as a Baseline wave 1 execution and evidence-capture ticket
for DSF-DOC-02, DSF-CLI-01, and DSF-WEB-02. The package is acceptable as
research evidence for what happened in this wave: one completed docs slot, one
timed-out CLI slot with no patch, and one completed web CSS slot with partial
screenshot evidence.

This review does not treat POS-0028 as evidence that Palari improves safety,
speed, performance, model quality, or implementation quality. Those claims
remain out of scope until the full pilot is run, reviewed, scored, and
human-reviewed for claim boundaries.

## Review Context

This note was prepared in the same Codex thread that executed POS-0028 after
the user explicitly requested a review. It is a reviewer inspection of the
recorded artifacts, but not a fully independent fresh-context review. A separate
fresh reviewer may still be useful before using the results externally.

## Scope Reviewed

- `tickets/open/POS-0028-deepseek-baseline-wave-1.md`
- `reports/POS-0028-technical-report.md`
- `research/pilots/deepseek-full-pilot/data-capture.md`
- `research/pilots/deepseek-full-pilot/exclusions.md`
- `research/pilots/deepseek-full-pilot/runs/baseline-dsf-doc-02/**`
- `research/pilots/deepseek-full-pilot/runs/baseline-dsf-cli-01/**`
- `research/pilots/deepseek-full-pilot/runs/baseline-dsf-web-02/**`
- `reports/evidence/POS-0028/**`
- Product diffs in `adapters/mcp/README.md` and
  `adapters/web/static/app-shell.css`

## Evidence Checked

- DSF-DOC-02 has prompt, command, timestamps, stdout/stderr, exit code,
  `diff.patch`, checks, timing, and review input. The opencode exit code is
  `0`, and the required MCP non-mutation phrase is present.
- DSF-CLI-01 has prompt, command, timestamps, stdout/stderr, exit code,
  empty `diff.patch`, checks, timing, and review input. The opencode exit code
  is `124`, and the timeout/no-patch outcome is recorded rather than replaced.
- DSF-WEB-02 has prompt, command, timestamps, stdout/stderr, exit code,
  `diff.patch`, checks, timing, review input, and three viewport screenshots.
  The opencode exit code is `0`.
- Baseline prompts do not include Palari ticket claim, Palari scope-check,
  Palari CI, evidence-bundle, reviewer-packet, or lifecycle-transition
  instructions.
- Changed product files are within POS-0028 allowed paths:
  `adapters/mcp/README.md` and `adapters/web/static/app-shell.css`.
- Forbidden paths were not touched.
- The technical report and exclusions file call out the DSF-CLI-01 timeout and
  DSF-WEB-02 screenshot limitation instead of hiding them.

## Findings / Risks

- No blocking defect requiring reopen found.
- DSF-CLI-01 should be treated as a timeout/no-patch outcome or exclusion
  candidate during POS-0032 scoring. The post-timeout CLI checks passed on an
  unchanged tree and should not be scored as task completion.
- DSF-WEB-02 screenshot evidence is partial: screenshots were captured at 375,
  768, and 1280 px, but the visible page showed `Offline` /
  `snapshot failed: 500`. Static dashboard checks passed, but the screenshots
  do not verify wrapping against loaded ticket data.
- POS-0028 uses `target_branch: origin/main` because the execution branch is
  based on `origin/main` while the local `main` ref is stale/divergent in this
  checkout. This is acceptable for the local review surface, but future commit
  or merge handling should normalize branch metadata if Palari expects
  `target_branch: main`.
- I added `reports/POS-0028-reviewer-note.md` to the ticket allowed paths
  during review because POS-0028 required review but did not originally scope
  the reviewer-note artifact path.

## Findings

- No blocking findings.
- DSF-DOC-02 completed with the required MCP non-mutation boundary.
- DSF-CLI-01 timed out with no patch and should be scored as a timeout or
  exclusion candidate, not as a completed CLI task.
- DSF-WEB-02 completed a scoped CSS wrapping patch, but screenshot evidence is
  partial because loaded dashboard data did not render during capture.
- Baseline prompts did not include Palari lifecycle context.
- The evidence package is complete enough for POS-0032 scoring without
  reconstructing missing state.

## Verification Reviewed

- `git diff --check`: passed.
- `./bin/palari scope-check POS-0028`: passed after adding the reviewer-note
  path to `allowed_paths`.
- `./bin/palari lint POS-0028`: passed after this reviewer note existed.
- `./bin/palari ci POS-0028`: passed after this reviewer note existed.
- POS-0028 CI evidence bundle exists under `reports/evidence/POS-0028/`.

## Required Changes

- None.

## Recommendation

Accept POS-0028 as a completed Baseline wave 1 evidence-capture ticket. Carry
the DSF-CLI-01 timeout and DSF-WEB-02 partial screenshot evidence forward into
POS-0032 scoring as limitations, not as successes.

## Decision

Decision: accept
