# POS-0072 Technical Report

## Session

- Ticket: POS-0072
- Role: implementation
- Branch: ticket/POS-0072
- Commit: pending
- Result: in-review

## Files Changed

```text
adapters/broker/mock_broker.py
contracts/broker.md
lib/palari/broker.bash
tests/run-broker-mock.sh
tickets/open/POS-0072-add-local-sandbox-broker-for-ticket-scoped-repo-file-work.md
reports/POS-0072-technical-report.md
reports/POS-0072-reviewer-note.md
reports/human/POS-0072-human-report.md
reports/evidence/POS-0072/
```

## Outcome

- What changed: `palari broker run TICKET --sandbox -- COMMAND` and `palari broker sandbox TICKET -- COMMAND` now run commands inside a disposable repo copy, scrub obvious credential environment variables, capture changed paths, compare those paths against ticket allowed/forbidden scope, write patch/evidence artifacts, and delete the sandbox copy.
- What did not change: Sandbox broker mode does not copy changes back to the real repo, does not enable real side effects, does not load credentials, does not provide network isolation, and does not claim to be a hardened security boundary.
- Blockers: none.
- Next action: fresh-context review, then POS-0073 can add broker permission check without execution if accept-ready.

## Verification

- Passed:
  - `python3 -m py_compile adapters/broker/mock_broker.py`
  - `bash -n lib/palari/broker.bash tests/run-broker-mock.sh tests/run-sandbox.sh`
  - `./tests/run-broker-mock.sh`
  - `./tests/run-sandbox.sh`
  - `./bin/palari broker status`
  - `./bin/palari lint POS-0072`
  - `./bin/palari report-lint POS-0072`
  - `./bin/palari scope-check POS-0072`
  - `./bin/palari ci POS-0072`
- Failed:
  - none after implementation.
- Not run:
  - Full repository test loop; POS-0072 is scoped to broker sandbox behavior and sandbox lifecycle compatibility.

## CI Evidence

- CI run: `./bin/palari ci POS-0072`
- Evidence bundle: `reports/evidence/POS-0072/`
- JUnit: `reports/evidence/POS-0072/junit.xml`
- SARIF: `reports/evidence/POS-0072/palari.sarif`
- Attestation: `reports/evidence/POS-0072/manifest.json`

## Review Status

- Review status: pending
- Reviewer note: `reports/POS-0072-reviewer-note.md`

## Risks / Follow-Ups

- Local sandbox mode is a disposable repo-copy boundary, not a VM/container/network sandbox.
- The broker detects changed paths after execution and returns nonzero for forbidden/out-of-scope changes; it does not yet preflight a requested resource without execution. POS-0073 is intended for permission checks.
- Evidence patch artifacts are for review. They are not automatically applied to the real repo.
