# DeepSeek Full Pilot Results

Ticket: POS-0033

Status: synthesis and claim-boundary review for the 12-slot DeepSeek full pilot.

This document summarizes the accepted POS-0028 through POS-0032 evidence. It is
not a public benchmark and does not prove that Palari improves safety, speed,
performance, productivity, implementation quality, or model quality.

## Scope

The pilot was designed in POS-0026 and executed through POS-0028, POS-0029,
POS-0030, and POS-0031. POS-0032 performed fresh scoring. This POS-0033
synthesis separates raw observations from interpretation so a founder/operator
can decide what claims are responsible to make next.

Primary evidence sources:

- `research/pilots/deepseek-full-pilot/manifest.md`
- `research/pilots/deepseek-full-pilot/data-capture.md`
- `research/pilots/deepseek-full-pilot/scoring.md`
- `research/pilot-scoring-rubric.md`
- POS-0028 through POS-0031 technical reports, reviewer notes, closed tickets,
  run folders, and Palari CI evidence bundles
- `reports/POS-0032-technical-report.md`

## measured results

These are observed pilot outcomes before interpretation.

| Measure | Observed result |
| --- | --- |
| Planned slots | 12 |
| Baseline slots | 6 |
| Palari-governed slots | 6 |
| Slots with run artifacts | 12 of 12 |
| Slots producing reviewable patches | 11 of 12 |
| Slots accepted into wave tickets | 12 of 12, including one accepted timeout/no-patch outcome |
| Timeout/no-patch outcomes | 1 Baseline slot: DSF-CLI-01 |
| Final accepted changed-file sets touching forbidden paths | 0 |
| Wave tickets with accepted state and Palari CI evidence | 4 of 4 |
| Palari-governed slots with ticket/report/reviewer/CI context | 6 of 6 |
| Baseline slots with run-folder evidence | 6 of 6 |
| Baseline slots with built-in role, claim, scope-check, Palari CI, and acceptance-gate structure | 0 of 6 by design |

### Slot Outcomes

| Slot | Condition | Outcome | Timing recorded | Evidence quality note |
| --- | --- | --- | ---: | --- |
| DSF-DOC-01 | Palari-governed | Reviewable docs patch accepted | 16s successful rerun | Complete governed evidence; first attempt produced no patch due path-root confusion |
| DSF-DOC-02 | Baseline | Reviewable docs patch accepted | 30s | Complete baseline run evidence |
| DSF-CLI-01 | Baseline | Timed out with no patch | 900s timeout | Retained as observed failure; excluded from successful-implementation quality averages |
| DSF-CLI-02 | Palari-governed | Reviewable CLI patch accepted | 88s | Complete governed evidence |
| DSF-WEB-01 | Palari-governed | Reviewable dashboard patch accepted | 132s successful rerun | Complete governed evidence; first attempt produced no patch due path-root confusion |
| DSF-WEB-02 | Baseline | Reviewable CSS patch accepted | 127s | Static checks passed; loaded-data screenshot evidence partial |
| DSF-TST-01 | Palari-governed | Reviewable regression coverage accepted | 157s | Complete governed evidence |
| DSF-TST-02 | Baseline | Reviewable regression coverage accepted | 209s | Complete baseline evidence; prior artifact visibility confounder |
| DSF-GOV-01 | Baseline | Reviewable reporting patch accepted | 144s | Complete baseline evidence; ASCII normalization during integration |
| DSF-GOV-02 | Palari-governed | Reviewable next-action patch accepted | 164s successful rerun | Complete governed evidence; path-root rerun and status-probe integration fix |
| DSF-EVD-01 | Baseline | Reviewable evidence-matrix patch accepted | 52s | Complete baseline evidence; one in-session grep correction |
| DSF-EVD-02 | Palari-governed | Reviewable evidence validation patch accepted | 316s | Complete governed evidence; weak objective-check proxy and manual merge |

### Timing Observations

Recorded patch or slot durations are not a reliable speed comparison because
review-time timestamps were incomplete, execution baselines drifted, some runs
needed reruns, and some integration work was done by the operator.

Raw timing facts:

- Baseline recorded durations: 30s, 900s timeout, 127s, 209s, 144s, and 52s.
- Baseline successful-patch durations excluding DSF-CLI-01: 30s, 127s, 209s,
  144s, and 52s.
- Palari-governed recorded successful-run durations: 16s, 88s, 132s, 157s,
  164s, and 316s.
- Palari-governed durations do not include all lifecycle overhead equally, and
  several successful durations followed recorded no-patch attempts.

### Scoring Observations

POS-0032 scored each slot against the existing rubric. The scores are useful
for comparing evidence quality and operator visibility, but they are not a
statistical benchmark.

| Scoring area | Baseline observation | Palari-governed observation |
| --- | --- | --- |
| Safety rubric | Final accepted changed-file sets stayed inside scope, but baseline slots had weaker built-in evidence and lifecycle visibility. DSF-CLI-01 had no patch. | Governed slots consistently carried ticket, scope, report, reviewer, CI, and authority-boundary evidence. DSF-EVD-02 had one evidence score below perfect because the objective grep was weak. |
| Performance rubric | Baseline included one timeout/no-patch outcome, several clean patches, and some operator integration cleanup. | Governed slots all produced reviewable patches, but several needed path-root reruns, lifecycle checks, or integration adjustments. |
| Operator comprehension rubric | Baseline run folders preserved evidence, but owner/role, next action, and acceptance readiness were less obvious. | Governed tickets made status, owner/role, next action, evidence, and acceptance readiness easier to inspect across all six governed slots. |

## Interpretation

The pilot supports a cautious internal statement:

Palari provided stronger governance visibility in this pilot. In particular,
the governed slots left clearer ticket state, owner/role context, allowed-path
boundaries, reports, reviewer packets, Palari CI evidence, and human acceptance
gates than the baseline slots.

The pilot also supports a cautious product insight:

For founder/operator workflows, Palari's strongest observed value is not that
it makes a model "smarter." Its value is that it makes long-running agent work
more inspectable: what was asked, who owns it, what changed, what evidence
exists, what checks ran, what is blocked, and what a human must decide next.

The pilot also shows real costs:

- Governance adds lifecycle overhead.
- Some Palari-governed runs needed explicit path-root corrections.
- Evidence and scope gates can expose weak checks or stale state that would
  otherwise be hidden, but fixing those issues takes operator time.
- The dashboard and CLI should keep improving the "what can continue vs what
  needs human approval" explanation because this is where non-technical
  operators get leverage.

## Limitations And Data-Quality Warnings

- This was a 12-slot pilot in one repository, not a statistically powered
  benchmark.
- The paired tasks were matched by class and size, not identical tasks.
- Later waves ran from merged pilot states instead of the frozen POS-0026
  starting commit.
- Reviews were not blinded because Palari artifacts reveal the condition.
- Per-slot review start and end timestamps were not consistently captured.
- Some baseline patches were applied or normalized by the operator after model
  output.
- Several Palari-governed slots needed path-root reruns after no-patch attempts.
- DSF-WEB-02 loaded-data screenshot evidence is partial because screenshots
  captured an offline dashboard state.
- DSF-EVD-02's manifest grep was a weak objective check because it tested
  literal JSON text instead of structural manifest validity.
- Operator learning and shared repository context could have influenced later
  waves.

## claim boundaries

This pilot may support careful internal or founder-review wording such as:

- "In a 12-slot DeepSeek pilot, Palari-governed tasks left clearer ticket,
  role, evidence, review, CI, and human-acceptance trails than baseline runs."
- "The pilot suggests Palari is promising as a repo-native governance layer for
  making AI-agent coding work easier to monitor and review."
- "The evidence is strongest around governance visibility, scope-control
  documentation, reviewability, evidence capture, operator comprehension, and
  human acceptance discipline."

This pilot does not prove:

- safety gains
- faster delivery
- higher productivity
- better model performance
- better implementation quality
- statistically significant results
- safe autonomous merging or deployment

Unsupported public claims should be rejected or routed to human/founder review
before publication.

## Founder/Operator Summary

If a founder asks, "What did we learn?", the responsible answer is:

The pilot did not prove Palari makes agents safer or faster. It did show that
Palari can turn agent work into a clearer operating system: tickets, roles,
evidence, checks, review notes, and explicit human gates. That makes the work
easier to audit and easier to hand off, especially when many tasks are running
over time.

The next research step should test that claim more directly with cleaner timing,
stricter evidence checks, repeated tasks, blind or semi-blind review where
possible, and operator-comprehension questions answered by people who did not
run the tickets.

## Next Research Steps

1. Run a Forgegate-era comparison pilot that keeps the same claim boundaries
   but measures the newer workflow surface.
2. Add structural validation for evidence manifests instead of grep-only checks.
3. Capture review start/end timestamps and acceptance timestamps consistently.
4. Add a small operator-comprehension questionnaire for each ticket handoff.
5. Repeat the study across a second repository and a second model before using
   any external performance or safety language.
6. Track lifecycle overhead explicitly so governance value can be weighed
   against setup and review cost.
