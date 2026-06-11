# POS-0041 Technical Report

## Summary

POS-0041 adds a read-only evidence-quality scoring command:

```bash
./bin/palari evidence score TICKET
./bin/palari evidence score TICKET --strict
```

The command helps a founder/operator see whether a ticket has the expected
proof surface before review or acceptance.

## Files Changed

- `bin/palari`
- `lib/palari/evidence_quality.bash`
- `docs/autonomy/evidence-quality-scoring.md`
- `tests/run-evidence-quality.sh`
- `tickets/open/POS-0041-evidence-quality-scoring.md`
- `reports/POS-0041-technical-report.md`

## Behavior

The scorer reads existing repo-native state only. It does not claim tickets,
write reports, accept, commit, push, merge, deploy, or create credentials.

It scores:

- required evidence artifacts,
- Palari CI manifest integrity,
- technical report presence,
- reviewer-note presence when required,
- human/founder report presence when required,
- lint and scope-check markers in `verification.log`.

## Verification

Commands run during implementation:

- `tests/run-evidence-quality.sh`
- `bash -n bin/palari lib/palari/*.bash tests/run-evidence-quality.sh`
- `tests/run-cli-structure.sh`
- `shellcheck -x bin/palari lib/palari/evidence_quality.bash tests/run-evidence-quality.sh`
- `./bin/palari scope-check POS-0041`

## CI Evidence

Palari CI evidence is expected under:

- `reports/evidence/POS-0041/verification.log`
- `reports/evidence/POS-0041/junit.xml`
- `reports/evidence/POS-0041/manifest.json`
- `reports/evidence/POS-0041/palari.sarif`

## Risks / Follow-Ups

- This is a local scoring heuristic, not proof that the implementation is
  correct.
- The score should guide review readiness and future queue-runner planning, not
  replace human acceptance authority.
- A future dashboard slice can surface the score alongside the Founder Inbox.
