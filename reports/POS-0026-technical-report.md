# POS-0026 Technical Report

## Session

- Ticket: POS-0026
- Role: research evaluator
- Branch: codex/first-pilot-study
- Commit: current working tree from
  `475b0d0a0be26d62bd3d7853dcff328e785ede02`
- Result: full DeepSeek pilot manifest and run plan created

## Files Changed

```text
research/pilots/deepseek-full-pilot/manifest.md
reports/POS-0026-technical-report.md
```

## Outcome

- Created a frozen full-pilot manifest for the next DeepSeek study wave.
- Set the target at 12 completed tasks: 6 baseline and 6 Palari-governed.
- Kept the DeepSeek/opencode model choice from POS-0025:
  `deepseek/deepseek-v4-flash`.
- Defined deterministic randomization from the frozen starting commit and suite
  label.
- Selected task slots across docs, CLI behavior, dashboard polish, tests, and
  governance/reporting.
- Added objective checks, allowed paths, forbidden paths, run-folder naming,
  evidence requirements, scoring linkage, exclusion rules, reviewer handoff,
  follow-on ticket routing, and claim boundaries.

## Deviations

- No pilot task was executed in POS-0026.
- No follow-on execution ticket was created.
- The manifest uses the budget-limited matched-pair design described in
  `research/benchmark-task-suite.md`, not the larger design where every task is
  run once under both conditions.
- Governance/reporting receives four task slots because Palari's core
  differentiator is evidence, lifecycle visibility, and human acceptance
  discipline. Docs, CLI behavior, dashboard polish, and tests each receive two
  task slots.

## Verification

- Passed before moving to in-review: `./bin/palari lint POS-0026`
- Passed: `git diff --check`
- Passed before moving to in-review: `./bin/palari ci POS-0026`
- Post-review-transition gate: `./bin/palari lint POS-0026` now reports
  `missing fresh-context reviewer note`, which is the next required review
  action rather than a self-fix for the implementer.

## CI Evidence

- POS-0026 CI evidence: `reports/evidence/POS-0026/`
- CI artifacts: `junit.xml`, `manifest.json`, `palari.sarif`, and
  `verification.log`

## Review Status

- Review status: in-review.
- Required next gate: fresh reviewer inspects the manifest for task balance,
  assignment fairness, objective checks, claim boundaries, and follow-on
  routing.

## Risks / Follow-Ups

- The manifest is a plan, not evidence of safety or performance impact.
- The planned pilot still needs clean worktrees or branches for each slot.
- Baseline and Palari-governed prompts must stay equivalent except for Palari
  lifecycle context.
- Fresh reviewers must score both conditions with the same rubric.
- Human acceptance remains required before any external-facing claim.
