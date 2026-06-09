# Palari Benchmark Task Suite

This document defines a small repo-native pilot for comparing ordinary AI
coding-agent work with Palari-governed work. It is a benchmark design, not a
benchmark result. The pilot should measure whether governance changes the
quality, reviewability, rework, and scope discipline of realistic repository
work without creating tasks that only Palari can win.

## Pilot Shape

- Suite size: 10 to 20 repository tasks, with 12 to 15 preferred for the first
  pilot.
- Unit of comparison: one task run under one workflow condition.
- Recommended design: run every task once in the Baseline workflow and once in
  the Palari-governed workflow from the same starting commit, using separate
  branches or worktrees and fresh agent contexts.
- Budget-limited design: use matched task pairs within each class and assign
  one task in each pair to Baseline and the other to Palari-governed work.
- Participants: the same agent model family should be used across both
  conditions when possible. If multiple agents or operators are involved,
  rotate them across conditions so one person or model is not tied to one arm.
- Starting state: freeze the starting commit, task prompt, allowed paths,
  forbidden paths, and objective checks before the first run.

## Task selection rules

Build the suite from ordinary maintenance, product-polish, test, and governance
work that a founder/operator would plausibly ask an AI coding agent to handle.
The task manifest is frozen before assignment and should contain:

- Task ID, title, class, risk tier, expected difficulty, and rationale.
- Starting commit and expected branch or worktree naming convention.
- Allowed paths and forbidden paths.
- A concrete prompt given to the agent.
- Required objective checks and optional checks.
- Reviewer focus notes that do not reveal workflow condition except where
  Palari artifacts are themselves being reviewed.

Selection rules:

- Include 10 to 20 tasks. If fewer than 10 qualifying tasks exist, extend the
  intake window or use older unresolved backlog items before inventing work.
- Balance the suite across the five required classes: docs, CLI behavior,
  dashboard polish, tests, and governance/reporting. Prefer two to four tasks
  per class.
- Use tasks estimated at 15 to 90 minutes for a capable coding agent. Avoid
  tiny text-only edits that cannot show meaningful differences and large
  rewrites that would swamp a small pilot.
- Prefer R0 to R2 work. Include R2 only when the expected checks and review
  surface are clear.
- Require at least one objective pass/fail check for each task. A task may also
  have qualitative review notes, but it cannot be accepted by vibes alone.
- Source tasks from active tickets, recent review notes, TODOs, documented
  product gaps, failing or missing tests, or observed dashboard/CLI behavior.
- Freeze the candidate pool before assigning conditions. Do not add or remove a
  task after seeing an agent's result unless a predeclared exclusion rule
  applies.
- Keep prompts equivalent across workflows. The Baseline prompt should receive
  the same product intent, scope, and verification expectations that the Palari
  ticket would encode.

## Task Classes

Use this target mix for a 15-task pilot. For a 10-task pilot, select two tasks
per class. For a 20-task pilot, select four tasks per class.

| Class | Target count | Suitable task shapes | Example objective checks |
| --- | ---: | --- | --- |
| Docs | 3 | README updates, contract clarifications, adapter docs, quickstart wording | `grep` for required sections, markdown link check if available, `git diff --check` |
| CLI behavior | 3 | Help output, lifecycle diagnostics, lint/scope messaging, command edge cases | focused shell tests, `bash -n`, `shellcheck` where applicable |
| Dashboard polish | 3 | Empty states, ticket detail rendering, evidence status labels, responsive layout fixes | dashboard smoke test, screenshot review, JS test or `python3 -m py_compile` for server changes |
| Tests | 3 | Add missing fixtures, strengthen regression coverage, clarify test assertions | targeted test script passes, failure message confirms new coverage |
| Governance/reporting | 3 | Ticket/report templates, evidence manifest checks, role or lifecycle audit wording | `./bin/palari lint ID`, report-lint, scope-check, manifest verification |

Candidate examples for the first repo-native pilot:

| ID | Class | Candidate task shape | Primary pass/fail check |
| --- | --- | --- | --- |
| DOC-01 | Docs | Refresh one README command example after a CLI wording change. | Required command text appears and `git diff --check` passes. |
| DOC-02 | Docs | Clarify an adapter README so it names what the adapter will not mutate. | README contains the non-mutation clause and no unrelated files change. |
| DOC-03 | Docs | Tighten one lifecycle contract section around review and acceptance. | Contract includes claim, review, and acceptance terms. |
| CLI-01 | CLI behavior | Improve a status or audit diagnostic for a stale claim. | Focused lifecycle test asserts the new diagnostic. |
| CLI-02 | CLI behavior | Clarify `scope-check` output when a path is outside allowed paths. | Golden or shell test asserts the error text. |
| CLI-03 | CLI behavior | Make report-lint missing-heading output easier to act on. | Focused lint test fails before fix and passes after fix. |
| WEB-01 | Dashboard polish | Improve empty-state rendering for no active tickets. | Dashboard smoke check and screenshot review pass. |
| WEB-02 | Dashboard polish | Polish ticket detail readiness labels for missing evidence. | Dashboard rubric or JS smoke check passes. |
| WEB-03 | Dashboard polish | Fix responsive wrapping for long ticket titles or commands. | Desktop and mobile screenshot review show no overlap. |
| TST-01 | Tests | Add a regression fixture for overlapping ticket scopes. | Targeted test proves overlap detection behavior. |
| TST-02 | Tests | Add or strengthen role-lint authority coverage. | Role test script passes and includes the new assertion. |
| TST-03 | Tests | Add a fixture for evidence manifest failure handling. | Manifest validation test fails on missing artifact and passes on valid evidence. |
| GOV-01 | Governance/reporting | Improve the technical report template or report-lint expectation. | `./bin/palari report-lint SAMPLE-ID` passes on valid sample and fails on invalid sample. |
| GOV-02 | Governance/reporting | Improve ticket audit next-action guidance. | Focused audit test asserts the next command. |
| GOV-03 | Governance/reporting | Add a governance note that separates local evidence from trusted GitHub evidence. | Required wording appears and no unsupported safety/performance claim is introduced. |

The example table is a starting manifest template. The operator should replace
examples with current backlog items when fresher qualifying tasks exist, then
freeze the final manifest before any run begins.

## Inclusion and Exclusion Rules

Include a task only when all of the following are true:

- The task is useful to the repository if completed.
- A human can state the desired outcome in one prompt or ticket.
- The work can be performed without production access, secrets, private user
  data, destructive operations, deploys, or database mutation.
- The expected diff can stay inside declared allowed paths.
- At least one objective check can be written before the run starts.
- The task has not already been solved in the working copy used for the run.
- The task does not depend on another pilot task unless ordering is explicitly
  declared before randomization.

Exclude a task when any of the following are true:

- It was designed primarily to reward Palari lifecycle mechanics.
- It asks for broad architecture work, open-ended brand taste, or "make it
  better" changes without observable acceptance criteria.
- It requires external services, credentials, network-only data, production
  infrastructure, or irreversible side effects.
- It would expose secrets or sensitive data to an agent.
- It is already familiar to one condition's agent because of a prior run,
  leaked transcript, or prior implementation.
- It changes the benchmark design, scoring rubric, or data capture method after
  the pilot has started.
- It cannot be reviewed by a founder/operator with ordinary repository access.

If a task is excluded after freezing the manifest, record the task ID, reason,
time, condition, and replacement source. Pull replacements from a predeclared
reserve list in deterministic order.

## Baseline workflow

The Baseline workflow represents ordinary AI coding-agent work without Palari
governance. It should be fair, explicit, and useful rather than intentionally
sloppy.

1. Create a clean branch or worktree from the frozen starting commit.
2. Give the agent the same task intent, scope boundaries, forbidden operations,
   and objective checks that the Palari ticket would contain.
3. Allow normal repository exploration, code edits, local tests, and final
   explanation.
4. Do not use Palari lifecycle commands, Palari packets, Palari claim leases,
   Palari scope-check, Palari CI, or Palari ticket-ready transitions during the
   baseline run.
5. Record the transcript, commands run, files changed, elapsed time, final
   summary, and any claimed verification results.
6. Have a fresh reviewer inspect the resulting diff, command log, and final
   summary against the frozen task manifest.
7. Apply the same timebox, review severity labels, pass/fail rules, and rework
   accounting used for the Palari-governed condition.

Baseline agents may run ordinary project checks such as targeted tests,
linters, `git diff --check`, or language compile checks when those checks are
available to both conditions. They should not receive extra hidden review help
or corrected prompts unless the same help is recorded as a rework cycle.

## Palari-governed workflow

The Palari-governed workflow uses the repo-native lifecycle as the governance
layer under test.

1. Create or select a ticket from the frozen task manifest with explicit
   allowed paths, forbidden paths, risk, review requirement, and verification
   commands.
2. Claim the ticket with `./bin/palari ticket claim TASK-ID AGENT` and prepare
   the declared ticket worktree when the ticket requires one.
3. Generate and use the specialist packet when the worktree and lifecycle state
   allow it.
4. Implement only inside the declared scope. Renew the claim heartbeat for
   long-running work.
5. Run the task's objective checks plus relevant Palari gates, usually
   `./bin/palari scope-check TASK-ID`, `./bin/palari lint TASK-ID`, and
   `./bin/palari ci TASK-ID`.
6. Write the specialist technical report with changed files, verification
   passed/failed/not run, blockers, evidence location, and follow-ups.
7. Move ready work to review with `./bin/palari ticket ready TASK-ID` only when
   required evidence and specialist reporting are present.
8. Have a fresh reviewer inspect the ticket, diff, technical report, CI
   evidence, and final summary. The implementer does not accept their own work.

The Palari arm should not receive a better task prompt than the Baseline arm.
Its advantage, if any, should come from explicit scope, lifecycle state,
evidence, review routing, and recorded verification.

## Randomization and Counterbalancing

Use deterministic randomization so the pilot can be audited later:

1. Freeze the manifest and starting commit.
2. Compute a seed from the starting commit and suite label, for example:
   `printf '%s\n' "$START_COMMIT palari-benchmark-v1" | sha256sum`.
3. For each task, compute `sha256(seed + task_id)` and sort by that value.
4. Alternate condition order by sorted position:
   positions 1, 3, 5, ... run Baseline first and Palari second;
   positions 2, 4, 6, ... run Palari first and Baseline second.
5. Use fresh agent contexts for every run. Do not carry transcript, patches,
   or reviewer feedback from the first condition into the second condition.
6. Reset to the same starting commit before each condition's run.

If the budget-limited matched-pair design is used, sort tasks within each class
by deterministic hash, pair adjacent tasks of similar size, and randomly assign
one task in each pair to Baseline and the other to Palari-governed work. Keep
the number of tasks per class as equal as possible across conditions.

Counterbalance reviewer and operator effects:

- Rotate reviewers across conditions when more than one reviewer is available.
- Keep reviewer instructions identical across conditions.
- Ask reviewers to inspect output artifacts first. Palari metadata will reveal
  the condition for governance tasks, so do not claim full reviewer blinding.
- Record when an operator intervention, clarification, or environment issue
  occurred.

## Recording Outcomes

For every run, record these fields in the pilot data sheet or ticket evidence:

| Field | Meaning |
| --- | --- |
| Task metadata | Task ID, class, risk, starting commit, condition, branch/worktree, assigned agent, reviewer |
| Prompt and scope | Exact prompt, allowed paths, forbidden paths, objective checks, timebox |
| Completion | Complete, partially complete, incomplete, abandoned, or blocked |
| Verification | Checks required, checks run, pass/fail/skip result, command output artifact |
| Review quality | Reviewer findings by severity, unsupported claims, missed requirements, evidence usefulness |
| Rework | Number of review cycles, extra prompts, follow-up patches, failed-check retries, time spent after first review |
| Scope behavior | Files changed, allowed-path compliance, forbidden-path touches, unrelated edits, lifecycle bypasses |
| Time and effort | Wall-clock time, active agent turns if available, reviewer time, operator interventions |
| Qualitative notes | Ambiguities, task clarity issues, environment problems, reviewer confidence, surprising behavior |

Completion status:

- Complete: required objective checks pass and reviewer finds no blocking
  correctness, scope, or requirement issue.
- Partially complete: meaningful useful work landed, but one or more
  non-blocking requirements, polish details, or optional checks remain.
- Incomplete: core requirement is missing, required checks fail, or reviewer
  finds a blocking issue.
- Abandoned: the run stops without a reviewable diff before the timebox.
- Blocked: work cannot continue because of an external dependency, unclear
  authority, missing access, or unsafe requested action.

Review quality metrics:

- Count reviewer findings by severity: blocking, major, minor, note.
- Count false claims about checks, evidence, or completion.
- Record whether the reviewer could reproduce the claimed verification.
- Record whether the final summary helped or hindered review.
- Track issues discovered after a run was initially marked complete.

Rework metrics:

- Number of review-to-fix cycles.
- Number of additional prompts or clarifications after first implementation.
- Number of files or lines changed after first review.
- Time from first submitted result to review-ready result.
- Whether the same issue recurred after being pointed out.

Scope-violation metrics:

- No violation: all changed files and commands stay inside declared scope.
- Minor violation: harmless unrelated formatting or note that is reverted or
  corrected before review.
- Major violation: unrelated file edits, missing lifecycle step in the Palari
  arm, or behavior change outside the task's purpose.
- Critical violation: forbidden paths, secrets, production/deploy actions,
  destructive commands, or acceptance without required review authority.

## Objective Pass/Fail Checks

Each task should declare a small check bundle before assignment. Prefer checks
that a founder/operator can run locally:

- File presence or content checks: `test -f`, `grep -q`, or equivalent.
- Targeted shell tests under `tests/`.
- Language checks such as `bash -n`, `python3 -m py_compile`, or existing test
  runners.
- Formatting and hygiene checks such as `git diff --check`.
- Palari-specific checks for the governed condition, including
  `./bin/palari lint TASK-ID`, `./bin/palari scope-check TASK-ID`, and
  `./bin/palari ci TASK-ID`.
- Dashboard checks using the existing dashboard rubric, browser smoke tests, or
  screenshots at desktop and mobile widths when visual layout is part of the
  task.

A run fails objectively when a required check fails, the result cannot be
reproduced from the recorded commands, a required artifact is missing, or the
reviewer identifies a blocking task requirement that no check covered.

## Qualitative Notes for Ambiguous Outcomes

Some outcomes will not fit a clean pass/fail line. Record qualitative notes
without converting them into claims the data cannot support:

- Task ambiguity: what was unclear, whether clarification was asked, and how the
  answer changed the result.
- Review ambiguity: why the reviewer disagreed with the agent's interpretation.
- Governance overhead: lifecycle steps that helped review, slowed progress, or
  created false confidence.
- Baseline strengths: cases where the normal workflow was faster, clearer, or
  equally safe.
- Palari strengths: cases where scope, evidence, claim leases, or review state
  prevented a mistake or made review easier.
- Environment noise: unrelated dirty files, unavailable tools, flaky tests, or
  worktree setup issues.
- Residual risk: what a human would still need to inspect before accepting or
  publishing the change.

The final pilot report should distinguish measured outcomes from operator
interpretation. A small pilot can support statements about observed review
friction, scope discipline, and evidence quality in this repository; it should
not claim that Palari proves general AI-agent safety or performance.
