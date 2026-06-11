---
description: Draft a structured decision for the human (options, recommendation, default)
---

Draft a Palari decision about: $ARGUMENTS

1. Frame one question in one sentence. Identify two to four genuinely different options and the real tradeoffs of each (cost, risk, what it forecloses).
2. Pick a recommendation and an honest default. The default may never include accept, merge, push, deploy, spend, or credential actions; if no safe default exists, omit `--default` so linked work pauses.
3. Run `./bin/palari decide create DEC-NNNN "Title" --option ... --option ... --recommend N [--default N] --respond-by DATE [--ticket ID] [--goal ID]`, then edit the created file to fill in tradeoffs and evidence links.
4. Show the human a three-line summary: the question, your recommendation with one reason, and the exact record command. Never record the outcome yourself.
