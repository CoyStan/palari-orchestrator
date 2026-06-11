# Evidence Quality Scoring

`palari evidence score TICKET` gives a founder, operator, or reviewer a quick
read-only answer to a practical question:

Is this ticket evidence complete enough to review or accept?

The score is not a claim that the work is correct. It is an operator readiness
signal that checks whether the expected proof surface is present.

## Scored Items

The command scores 100 possible points:

- 20 points for required CI artifacts:
  `verification.log`, `junit.xml`, `palari.sarif`, and `manifest.json`.
- 20 points for a valid Palari CI manifest with matching hashes.
- 15 points for a technical report.
- 15 points for a fresh reviewer note when review is required.
- 10 points for a human/founder report when the ticket requires human
  confirmation.
- 10 points for a lint pass marker in `verification.log`.
- 10 points for a scope-check pass marker in `verification.log`.

## Ratings

- `ready`: 95-100 points.
- `needs-review`: 75-94 points.
- `needs-evidence`: below 75 points.

## Safety Boundary

Evidence scoring is intentionally read-only. It does not accept, commit, push,
merge, deploy, claim tickets, create credentials, or modify reports. It can
guide a future queue runner, but it must not replace human acceptance authority.

## Operator Use

Useful commands:

```bash
./bin/palari evidence score POS-0041
./bin/palari evidence score POS-0041 --strict
```

Use the default command while exploring a ticket. Use `--strict` inside a gate
when the expected state is fully review-ready.
