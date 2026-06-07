# POS-0015 Technical Report

## Session

- Ticket: POS-0015
- Role: specialist
- Branch: main
- Commit: current HEAD
- Result: in-review

## Files Changed

```text
.github/workflows/scorecard.yml
tickets/**
reports/**
```

## Outcome

- What changed: Fixed the Scorecard workflow permissions by keeping global permissions read-only and moving write permissions to the job.
- What did not change: Branch protection policy and Scorecard scoring policy were not changed.
- Blockers: None.
- Next action: Accept the completed Scorecard workflow ticket.

## Verification

- Passed: `palari ci POS-0015 --base origin/main`
- Failed: none
- Not run: none

## CI Evidence

- CI run: local closeout evidence
- Evidence bundle: `reports/evidence/POS-0015`
- JUnit: `reports/evidence/POS-0015/junit.xml`
- SARIF: `reports/evidence/POS-0015/palari.sarif`
- Attestation: GitHub attestation applies on trusted workflow runs, not local closeout.

## Review Status

- Review status: passed
- Reviewer note: `reports/POS-0015-reviewer-note.md`

## Risks / Follow-Ups

- Keep Scorecard workflow permissions aligned with OpenSSF action requirements.
