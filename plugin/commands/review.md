---
description: Run a fresh-context review of a ticket that is in-review
---

Perform a fresh-context Palari review of ticket: $ARGUMENTS

Use the palari-reviewer agent for this so the review context is clean. The reviewer must:
1. Run `./bin/palari packet TICKET-ID reviewer` and read it fully.
2. Inspect the diff, evidence under `reports/evidence/TICKET-ID/`, and `./bin/palari evidence score TICKET-ID`.
3. Check correctness, scope compliance, verification honesty, completion contract, and regression risk. Do not implement fixes.
4. Write `reports/TICKET-ID-reviewer-note.md` from `templates/reviewer-note.md` with a clear recommend/reopen verdict.
5. Report back: verdict, top findings, and the exact human command (`./bin/palari accept TICKET-ID --by NAME` or `./bin/palari ticket reopen TICKET-ID`). Never run accept yourself.
