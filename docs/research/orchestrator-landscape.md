# Orchestrator Landscape

Status: research input only. This document describes analogous platforms and
patterns. It does not approve a Palari Orchestrator redesign or define an
implementation plan.

## Purpose

Palari Orchestrator is trying to coordinate long-running AI/software work:
tickets, scope, evidence, reviews, acceptance, branches, worktrees, humans,
and safe continuation after context loss. Similar problems appear in issue
trackers, pull request systems, CI products, workflow engines, software
catalogs, and incident tools. None of those products is the exact model for
Palari, but each has useful organization patterns.

This survey focuses on:

- information architecture
- status models
- evidence and checks
- review and approval
- ownership
- history and timelines
- the operator question: "what needs attention next?"

## Platforms Reviewed

### Linear And Jira: Work Intake, Status, And Flow

Representative sources:

- Linear concepts and triage: https://linear.app/docs/conceptual-model,
  https://linear.app/docs/triage
- Linear workflow statuses: https://linear.app/docs/configuring-workflows
- Jira workflows: https://support.atlassian.com/jira-cloud-administration/docs/work-with-issue-workflows/,
  https://www.atlassian.com/software/jira/guides/workflows/overview

How they organize work:

- The main object is a work item: issue, task, bug, project item, or request.
- Work items move through status categories or workflow statuses.
- Jira models workflow explicitly as statuses and transitions.
- Linear keeps a lighter model with status categories such as backlog, triage,
  in progress, done, and canceled.
- Views are filtered projections over the same work items: team queue, project,
  cycle, backlog, triage, custom views.
- Triage is a distinct intake state. It prevents unreviewed work from
  polluting execution queues.

Useful patterns for Palari:

- Separate intake from execution. A proposed ticket is not the same as active
  claimed work.
- Status should be readable without opening a document.
- The queue view should be a projection over tickets, not another source of
  truth.
- Transitions should be explicit and constrained. A ticket should not drift
  into "accepted" through report edits.
- Views should answer the current operational question: needs routing, active,
  blocked, ready for review, ready for human acceptance, ready to merge.

Risks to avoid:

- Heavy custom workflows can become a bureaucracy.
- Too many statuses create status archaeology instead of clarity.
- A workflow that demands perfect metadata before work can begin slows down
  small repairs.

### GitHub And GitLab: Review, Checks, And Mergeability

Representative sources:

- GitHub pull requests: https://docs.github.com/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests
- GitHub status checks: https://docs.github.com/articles/about-status-checks
- GitHub protected branches: https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
- GitHub reviewing proposed changes:
  https://docs.github.com/articles/reviewing-proposed-changes-in-a-pull-request
- GitLab merge requests: https://docs.gitlab.com/user/project/merge_requests/
- GitLab merge request approvals:
  https://docs.gitlab.com/user/project/merge_requests/approvals/
- GitLab approval rules:
  https://docs.gitlab.com/user/project/merge_requests/approvals/rules/

How they organize work:

- The pull request or merge request is the integration object.
- It brings together diff, discussion, reviewers, approvals, checks, commits,
  branch state, and merge action.
- Automated checks attach to a specific commit.
- Required reviews and required checks contribute to mergeability.
- Review outcomes are simple: approve, request changes, comment.
- Branch protection makes mergeability a computed gate rather than a narrative
  report.

Useful patterns for Palari:

- Palari needs one computed "can this be accepted/merged?" answer.
- Evidence should attach to a specific ticket commit or stack head, not just a
  ticket id in the abstract.
- Reviewer findings should be direct and actionable. They should not be
  buried in long ritual reports.
- Acceptance commands should protect against stale heads in the same way PR
  approvals protect against approving a different commit than the one reviewed.
- The detail view should group diff, evidence, review, and next action in one
  place.

Risks to avoid:

- If branch state, ticket state, evidence state, and reviewer state all have
  separate partial truths, the operator must manually reconcile them.
- A review note that says "accept-ready" is weaker than a computed gate that
  proves the reviewed head, evidence head, and branch head match.

### Buildkite And CircleCI: Evidence As Run Output

Representative sources:

- Buildkite annotations: https://buildkite.com/docs/agent/cli/reference/annotate
- Buildkite annotations API:
  https://buildkite.com/docs/apis/rest-api/annotations
- CircleCI test data: https://circleci.com/docs/guides/test/collect-test-data/
- CircleCI artifacts: https://circleci.com/docs/guides/optimize/artifacts/
- CircleCI insights: https://circleci.com/docs/guides/insights/insights/
- CircleCI test insights:
  https://circleci.com/docs/guides/insights/insights-tests/

How they organize work:

- The main proof object is a run: pipeline, workflow, build, or job.
- Runs have status, logs, artifacts, test results, summaries, and timestamps.
- Artifacts persist raw outputs for later inspection.
- Annotations summarize what matters without replacing logs.
- Insights roll up historical health and duration trends.

Useful patterns for Palari:

- Evidence should feel like a run record, not a hand-assembled dossier.
- A Palari evidence bundle should have:
  - ticket id
  - commit/head
  - created timestamp
  - commands run
  - pass/fail/skip state
  - artifacts
  - summary annotations
- Human reports should summarize evidence; they should not substitute for it.
- Stale evidence should be a first-class state: "evidence passed, but not for
  this head."

Risks to avoid:

- Empty or synthetic evidence artifacts create false confidence.
- Evidence that is too hard to read encourages rubber-stamp acceptance.
- Long all-purpose CI commands can hide which bounded check actually matters.

### Temporal, Airflow, And Dagster: Workflow Execution History

Representative sources:

- Temporal workflow event history:
  https://docs.temporal.io/workflow-execution/event
- Temporal workflows: https://docs.temporal.io/workflows
- Airflow UI: https://airflow.apache.org/docs/apache-airflow/stable/ui.html
- Airflow task logs:
  https://airflow.apache.org/docs/apache-airflow/stable/administration-and-deployment/logging-monitoring/logging-tasks.html
- Dagster webserver and UI: https://docs.dagster.io/guides/operate/webserver
- Dagster assets: https://docs.dagster.io/guides/build/assets
- Dagster sensors: https://docs.dagster.io/guides/automate/sensors

How they organize work:

- They distinguish definitions from executions.
- Temporal records a durable event history for each workflow execution.
- Airflow's grid view makes recent run/task state visible and drills down into
  task logs.
- Dagster organizes jobs, runs, schedules, sensors, assets, observations, and
  materializations.
- Operators inspect status at a glance, then drill into failing tasks or
  events.

Useful patterns for Palari:

- A ticket definition is not the same as a ticket execution attempt.
- Palari should have a durable timeline of meaningful events:
  created, claimed, worktree created, evidence run, review requested,
  reviewer finding, repair, acceptance, merge.
- Timeline events should be inspectable and ordered. They should make context
  compaction less dangerous.
- The operator view should start with the current state and allow drill-down
  into logs/evidence.

Risks to avoid:

- Full workflow-engine complexity is too much for Palari's near-term need.
- Replaying every command is less important than preserving the small set of
  events needed for trust and continuation.

### Backstage: Catalog, Ownership, And Metadata Near Code

Representative sources:

- Backstage Software Catalog:
  https://backstage.io/docs/features/software-catalog/
- Backstage descriptor format:
  https://backstage.io/docs/features/software-catalog/descriptor-format/
- Backstage ownership relations:
  https://backstage.io/docs/features/software-catalog/well-known-relations/

How it organizes work:

- Backstage centralizes metadata about software entities.
- Entity descriptors live as YAML near code and are harvested into a catalog.
- Ownership is explicit and queryable.
- The catalog is a discoverability surface over distributed metadata.

Useful patterns for Palari:

- Palari can keep file-based ticket metadata, but expose it through a coherent
  generated catalog/status view.
- Ownership and responsibility should be visible:
  - who claimed work
  - who reviewed it
  - who can accept it
  - what human profile/quorum applies
- Metadata near code is acceptable as long as generated views make it easy to
  understand.

Risks to avoid:

- Catalog completeness can become a project by itself.
- Metadata that is easy to hand-edit but not validated can rot.

### PagerDuty: Incident Status, Timeline, Roles, And Next Action

Representative sources:

- PagerDuty incidents:
  https://support.pagerduty.com/main/docs/incidents
- PagerDuty incident response docs: https://response.pagerduty.com/
- PagerDuty status pages:
  https://support.pagerduty.com/main/docs/status-pages-overview
- PagerDuty status update templates:
  https://support.pagerduty.com/main/docs/status-update-templates

How it organizes work:

- Incident tools optimize for urgency, ownership, timeline, communication, and
  current status.
- Incident detail pages expose status, notes, responders, timeline, and
  actions.
- Status updates communicate externally without forcing users to inspect every
  internal event.
- Timelines record status changes, actions, and notifications.

Useful patterns for Palari:

- For blocked or high-risk tickets, Palari should make owner, severity/risk,
  current blocker, and next action obvious.
- A short operator update can summarize status without replacing the detailed
  evidence.
- Timeline plus notes helps future agents continue without relying on memory.

Risks to avoid:

- Incident workflows are optimized for production operations, not all
  software work. Palari should borrow clarity, not urgency theater.

## Cross-Platform Patterns

### 1. The Best Systems Separate Definition, Execution, And Decision

Common split:

- Definition: issue, ticket, workflow, policy, component descriptor.
- Execution: build run, workflow run, worktree session, CI attempt.
- Decision: approval, merge, incident resolution, acceptance.

Palari currently blends these too easily. A ticket file, evidence report,
review note, claim, worktree, and acceptance state can all appear to describe
the same thing while disagreeing. A redesign should make these layers explicit.

### 2. "What Needs Attention Next?" Is The Primary Operator View

Good systems make the next action obvious:

- triage this
- assign this
- rerun failed check
- respond to requested changes
- approve or reject
- update branch
- merge
- investigate failing task

Palari should not require the founder to read several reports to answer
whether a ticket is safe to accept.

### 3. Evidence Belongs To A Specific Head

CI systems and PR systems attach checks to commits or runs. Palari should treat
evidence the same way. A ticket with "passed evidence" at an old head is not
the same as a ticket with passed evidence at the current head.

### 4. Review Should Be Structured Around Findings

GitHub/GitLab review language is simple:

- approve
- request changes
- comment / question

Palari reviewer notes can remain Markdown, but the core data should be:

- reviewer
- reviewed head
- verdict
- findings
- required fixes
- residual risks

### 5. History Should Be A Timeline, Not A Memory Test

Temporal, Airflow, Dagster, PagerDuty, GitHub, and GitLab all preserve event
history. Palari's context-compaction problem makes this especially important.
The system should answer:

- What happened?
- Who did it?
- Which command/check produced this evidence?
- Which commit was reviewed?
- Why did the ticket reopen?
- What remains?

### 6. Views Are Projections, Not Sources Of Truth

Dashboards and queues should read validated ticket, git, evidence, and review
state. They should not become a second place where truth is edited manually.

### 7. Strong Gates Should Be Reserved For Strong Risks

High-risk work deserves formal review and acceptance gates. Small internal
repairs need a lighter path. Otherwise the process becomes slower than the
work and users route around it.

## Implications For Palari Orchestrator

Strong candidates:

- A control-board command/view organized by next action.
- Evidence bundles modeled as run records tied to a head SHA.
- A computed acceptability/mergeability answer.
- Clear distinction between ticket definition, execution attempt, review, and
  acceptance.
- Timeline events for ticket lifecycle and context recovery.
- First-class external maintainer mode for work on Palari Orchestrator itself.

Possible but uncertain:

- A richer web dashboard.
- Full workflow execution graph.
- Formal catalog entities for every ticket, human, workflow, and policy.
- Multi-reviewer policy surfaces beyond the current human-quorum model.

Likely not worth copying:

- Jira-style heavily customized workflow schemes.
- Full workflow-engine replay semantics.
- Incident-style urgency for normal development tickets.
- Dashboards that can mutate critical state without explicit commands.

## Questions For The Redesign Review

- What should be the single source of truth for "ready to accept"?
- Should Palari maintain a durable event log, or derive history from git and
  files?
- How much of the current report/evidence structure should become generated
  output instead of handwritten artifacts?
- What work should be allowed in external maintainer mode?
- Which gates are required for R1/R2 versus R3/R4/R5 work?
- How should Palari prevent stale review/evidence acceptance without forcing
  the founder to understand every internal file?
