# POS-0025 Technical Report

## Session

- Ticket: POS-0025
- Role: research evaluator
- Branch: codex/first-pilot-study
- Commit: current working tree
- Result: first DeepSeek pilot slice complete

## Files Changed

```text
research/pilots/deepseek-first-pilot/manifest.md
research/pilots/deepseek-first-pilot/data-capture.md
research/pilots/deepseek-first-pilot/results.md
research/pilots/deepseek-first-pilot/runs/baseline-doc-01/*
research/pilots/deepseek-first-pilot/runs/palari-doc-01/*
tickets/open/POS-0025-deepseek-first-pilot-study-run.md
reports/POS-0025-technical-report.md
```

## Outcome

- DeepSeek was available through opencode.
- Baseline-agent DOC-01 completed and passed requested checks.
- Palari-governed DOC-01 completed and passed opencode, scope-check, and CI.
- The pilot workflow successfully captured raw logs, diffs, timing, and scoring
  notes.
- The run is only a first executable slice, not the full 12-task pilot.

## Verification

- test -f research/pilots/deepseek-first-pilot/manifest.md
- test -f research/pilots/deepseek-first-pilot/results.md
- test -f research/pilots/deepseek-first-pilot/data-capture.md
- grep -q 'DeepSeek' research/pilots/deepseek-first-pilot/results.md
- grep -q 'Baseline-agent' research/pilots/deepseek-first-pilot/data-capture.md
- grep -q 'Palari-governed' research/pilots/deepseek-first-pilot/data-capture.md

## CI Evidence

- Passed: `./bin/palari ci POS-0025`
- POS-0025 CI evidence: `reports/evidence/POS-0025/`
- Scope evidence: local working-tree scope check passed for 39 changed paths.
- Baseline raw artifacts: `research/pilots/deepseek-first-pilot/runs/baseline-doc-01/`
- Palari raw artifacts: `research/pilots/deepseek-first-pilot/runs/palari-doc-01/`

## Review Status

- Review status: in-review with reviewer recommendation to accept.
- Reviewer note: `reports/POS-0025-reviewer-note.md`

## Risks / Follow-Ups

- One matched pair is too small for outcome claims.
- Palari improved evidence completeness but did not automatically improve edit
  quality in this single run.
- The next meaningful step is the full 12-task pilot with fresh reviewers and
  preselected task assignments.
