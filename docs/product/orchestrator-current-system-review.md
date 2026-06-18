# Palari Orchestrator Current System Review

Status: current-system inventory and compatibility review. This document is
analytical input for future redesign work. It does not approve a redesign,
create implementation tickets, or change runtime behavior.

## Purpose

Palari Orchestrator already contains more than a ticket workflow. It is a
repo-native operating system for AI-assisted company work: humans set goals,
agents prepare scoped work, evidence proves what happened, reviewers inspect
fresh context, humans make decisions, and acceptance gates preserve authority.

Any redesign must start from the current system instead of replacing it with a
generic issue tracker model. The important existing primitives are:

- goals and decisions
- tickets and proposals
- human roles, human profiles, and AI role packets
- queue dry-run and status/snapshot surfaces
- worktree-first execution
- scope checks
- CI evidence and evidence scoring
- fresh-context review
- workflows and Company AI OS planning
- Human Governance Load
- policy simulation
- broker evidence and broker boundaries
- outcomes
- forge-proof signed acceptance gate
- human acceptance and quorum
- branch, merge, cleanup, and dogfooding conventions

## Current Operating Loop

The current model is best summarized as:

```text
Goal
  -> Proposal / Workflow
    -> Ticket / Decision
      -> Worktree / Packet / Agent Work
        -> Scope Check / Evidence
          -> Fresh Review
            -> Human Acceptance / Decision
              -> Outcome / Memory
```

This loop matters because Palari is not trying to make agents merely faster.
It is trying to make AI work governable inside a company: visible intent,
bounded authority, inspectable work, human judgment, and learning from
outcomes.

## 1. Goals

### What Exists Now

Goals are repo artifacts under:

```text
goals/proposed/
goals/active/
goals/closed/
```

Current active examples:

- `GOAL-0100-build-palari-company-ai-os-infrastructure`
- `GOAL-0200-harden-palari-company-ai-os-governance`

Key commands and files:

- `./bin/palari goal create`
- `./bin/palari goal list`
- `./bin/palari goal show`
- `./bin/palari goal adopt`
- `./bin/palari goal lint`
- `contracts/goals-and-decisions.md`
- `lib/palari/goals.bash`
- `palari.config.yaml` fields:
  - `goals_active_dir`
  - `goals_proposed_dir`
  - `goals_closed_dir`
  - `require_serves_goal`

### Why It Matters

Goals make founder intent machine-readable. Tickets and proposals can declare
`serves_goal`, which lets the repo answer why a piece of work exists. That is
central to a Company AI OS: agents should not self-prioritize from vibes.

### What Works Well

- Goals are simple Markdown artifacts.
- `require_serves_goal` can be `off`, `warn`, or `strict`, which gives a
  migration path from loose to disciplined planning.
- Goals do not grant authority or widen paths.
- The queue runner can filter by goal.

### Awkward Or Risky

- Current status/snapshot output can still feel ticket-centered rather than
  goal-centered.
- Because `require_serves_goal` is currently warn-mode, unlinked work can
  still accumulate.
- Goal success criteria are human-written and may be too broad for automatic
  progress assessment.

### Compatibility Constraint

Any redesign must keep goals as first-class intent artifacts. A new queue,
dashboard, or detail surface should show goal linkage and unlinked-work
warnings instead of treating goals as optional metadata.

### Redesign Posture

Keep and elevate.

## 2. Decisions

### What Exists Now

Decisions are structured human-judgment artifacts under:

```text
decisions/open/
decisions/decided/
memory/decisions/
```

Key commands and files:

- `./bin/palari decide create`
- `./bin/palari decide list`
- `./bin/palari decide show`
- `./bin/palari decide inbox`
- `./bin/palari decide record`
- `./bin/palari decide lint`
- `contracts/goals-and-decisions.md`
- `lib/palari/decisions.bash`
- `adapters/planning/decision_inbox.py`

### Why It Matters

Decisions are how AI brings judgment back to the human. Instead of blocking on
vague "needs human" status, an agent should ask one explicit question with
options, tradeoffs, a recommendation, a respond-by date, and a safe default.

### What Works Well

- Decisions distinguish agent preparation from human judgment.
- Open decisions surface above plannable work in `palari run --dry-run` and
  snapshot operator inboxes.
- Defaults are explicitly forbidden from containing accept, merge, push,
  deploy, spend, credentials, or other human-gated actions.
- Decided decisions flow into memory so future packets can cite them.

### Awkward Or Risky

- Decision artifacts can still be underused compared with ticket comments or
  chat instructions.
- The relationship between ticket status `needs-human` and a formal decision
  artifact may not be obvious enough.
- Decisions need to be visible in any future control board, otherwise the
  operating loop collapses back into status noise.

### Compatibility Constraint

Any redesign must preserve the "decisions out" part of the loop. Human
judgment should be represented as decisions, not hidden inside ticket prose or
chat memory.

### Redesign Posture

Keep and make more central.

## 3. Tickets And Proposals

### What Exists Now

Tickets are scoped implementation units under:

```text
tickets/proposed/
tickets/open/
tickets/closed/
```

Proposals are planning artifacts that may be adopted into tickets. Current
ticket lifecycle statuses are:

```text
open
claimed
blocked
needs-human
in-review
reopened
accepted
```

Key commands and files:

- `./bin/palari ticket create`
- `./bin/palari ticket claim`
- `./bin/palari ticket heartbeat`
- `./bin/palari ticket audit`
- `./bin/palari propose create`
- `./bin/palari propose adopt`
- `./bin/palari propose packet`
- `contracts/ticket-lifecycle.md`
- `contracts/lead.md`
- `lib/palari/tickets_workspace.bash`
- `lib/palari/proposals.bash`

### Why It Matters

Tickets make delegated AI work bounded, reviewable, and auditable. Proposals
let planning happen before execution authority is granted.

### What Works Well

- Ticket frontmatter carries risk, allowed paths, forbidden paths, target
  branch, verification commands, review requirements, and acceptance mode.
- Proposal adoption prevents a planner from becoming an implementation agent.
- Ticket lifecycle is explicit and accepted tickets move to the closed queue.
- Claims and claim leases make active work visible.

### Awkward Or Risky

- Ticket files can become overloaded: scope, status, claim data, reports,
  acceptance, and local worktree hints all compete for attention.
- Claim leases are useful but not truly cross-machine atomic; the contract is
  honest about this limitation.
- Stacked-ticket evidence and branch state can be hard to reason about.
- Founder/operator experience can become too much paperwork for small fixes.

### Compatibility Constraint

Any redesign must preserve tickets as scoped execution units and proposals as
planning-before-authority. It may simplify how status is displayed, but it
should not make ticket text itself an authority source.

### Redesign Posture

Keep, but simplify presentation and separate definition from execution
attempts.

## 4. Queue Dry-Run

### What Exists Now

`palari run --dry-run` is a read-only queue planner. Running `palari run`
without `--dry-run` fails closed.

Key commands and files:

- `./bin/palari run --dry-run`
- `./bin/palari run --dry-run --until blocked`
- `./bin/palari run --dry-run --goal GOAL-ID`
- `./bin/palari run --dry-run --json`
- `docs/autonomy/queue-runner-dry-run.md`
- `lib/palari/run.bash`

### Why It Matters

The dry-run queue answers "what happens next?" without doing anything. This is
one of the most important safety properties in Palari: the system may plan,
but it does not silently claim, edit, accept, merge, push, deploy, or call
external services.

### What Works Well

- It is explicitly read-only.
- Open decisions surface first as stop items.
- Goal filtering keeps prioritization traceable.
- It can express safe next commands without executing them.

### Awkward Or Risky

- The dry-run planner is currently more of a command output than a true daily
  operator console.
- If output is too verbose or too ticket-centered, it may not replace manual
  chat-based process management.
- Future supervised/autonomous modes could become dangerous if introduced
  before dry-run state is trusted.

### Compatibility Constraint

Any redesign must keep dry-run semantics fail-closed. A future queue UI should
remain a projection over repo state and should not mutate lifecycle state
unless a separate explicit command is invoked.

### Redesign Posture

Keep and elevate into the main "what needs attention next" surface.

## 5. Status, Snapshot, And Dashboard Surfaces

### What Exists Now

Status and snapshot commands provide read models over tickets, git, evidence,
operator inbox state, authority, gate, memory, and Company OS data.

Key commands and files:

- `./bin/palari status --next`
- `./bin/palari snapshot --json`
- `./bin/palari state`
- `./bin/palari web`
- `lib/palari/init_adopt.bash`
- `lib/palari/state.bash`
- `lib/palari/adapters_snapshot.bash`
- `lib/palari/dashboard_snapshot.bash`
- `adapters/snapshot/fast_snapshot.py`
- `adapters/web/server.py`

Current sampled state on this branch reported no active tickets and the next
action: create or adopt a ticket. It also reported workspace changes because
these architecture docs are uncommitted.

### Why It Matters

The read model is the natural foundation for any future control board. It is
where Palari can answer the operator's core question without requiring manual
file archaeology.

### What Works Well

- `status --next` gives a plain-language next action.
- `snapshot --json` exposes machine-readable state for dashboards or tools.
- Snapshot includes an operator inbox model and Company OS fields.
- The dashboard is explicitly not an authority surface.

### Awkward Or Risky

- Snapshot output can omit inactive artifact families from the most obvious
  counts, so the current system may look smaller than it is if only one output
  is inspected.
- Multiple read models can disagree or emphasize different things.
- The dashboard can become tempting as a mutation surface, which the dogfood
  guidance explicitly warns against.

### Compatibility Constraint

Any redesign should build on computed read models, but must keep mutation
commands explicit and auditable. The read model should include goals,
decisions, workflows, human coverage, and outcomes as first-class concepts.

### Redesign Posture

Keep, consolidate, and make more truthful across artifact families.

## 6. Worktree-First Execution

### What Exists Now

Meaningful edits are expected to happen in ticket branches and ticket
worktrees, not the canonical checkout.

Key commands and files:

- `./bin/palari worktree TICKET-ID`
- `./bin/palari worktree closeout TICKET-ID`
- `./bin/palari evidence refresh TICKET-ID`
- `contracts/worktree-first.md`
- `lib/palari/tickets_workspace.bash`
- `palari.config.yaml` `worktree_base`

### Why It Matters

Worktrees isolate agent work from accepted main and from unrelated user or
agent changes. They also give packets, scope checks, and evidence a stable
execution surface.

### What Works Well

- The worktree-first contract is explicit.
- Closeout checks branch, worktree, scope, evidence, reports, and next
  commands before review.
- Worktree isolation makes parallel agent work safer than editing in one main
  checkout.

### Awkward Or Risky

- Worktree path resolution has been a real pain point, especially when creating
  stacked worktrees from inside another worktree.
- Worktrees are infrastructure, but the founder has had to reason about them
  too often.
- Local worktree cleanup can create process overhead.

### Compatibility Constraint

Any redesign must keep path/worktree boundaries clear and must hide worktree
complexity behind truthful commands where possible. Worktree paths must be
stable and canonical.

### Redesign Posture

Keep, but make it less visible and less surprising.

## 7. Specialist, Reviewer, And Acceptor Packets

### What Exists Now

Packets provide role-specific context for specialists, reviewers, and
acceptors.

Key commands and files:

- `./bin/palari packet TICKET-ID specialist`
- `./bin/palari packet TICKET-ID reviewer`
- `.palari/packets/`
- `lib/palari/agents_review_scope.bash`
- `contracts/adapters.md`
- `roles/active/`

### Why It Matters

Packets make AI work more reliable by giving each role the right scope,
constraints, evidence expectations, and memory context without relying on chat
history.

### What Works Well

- Role-specific packets support fresh-context work after compaction.
- The specialist/reviewer split preserves no-self-review.
- Packets can include memory and related context selected by Palari.

### Awkward Or Risky

- Packet generation can feel like another artifact to manage.
- If packets are stale relative to branch/evidence state, they can mislead an
  agent.
- Current packet surfaces are mostly CLI/file based rather than integrated
  into one ticket detail view.

### Compatibility Constraint

Any redesign must preserve role-specific context packaging, especially for
fresh-context review and agent handoff.

### Redesign Posture

Keep, but integrate into ticket detail and review surfaces.

## 8. Scope Checks

### What Exists Now

Scope checks compare changed paths against ticket `allowed_paths` and
`forbidden_paths`.

Key commands and files:

- `./bin/palari scope-check TICKET-ID`
- `./bin/palari scope-check TICKET-ID --base origin/main`
- `./bin/palari scope-overlaps TICKET-ID`
- `contracts/scope-and-paths.md`
- `lib/palari/agents_review_scope.bash`
- `palari.config.yaml` default forbidden paths and overlap settings

### Why It Matters

Path scope is the most direct guardrail around agent edits. It turns "stay in
scope" from a prompt into a repo-native check.

### What Works Well

- Forbidden paths win over allowed paths.
- Default forbidden paths cover common secret and production surfaces.
- Scope checks work locally and against a base branch.
- Overlap checks use allowed paths as a concurrency primitive.

### Awkward Or Risky

- Path checks are not secret scanners and can never be enough alone.
- Overlap rules can be noisy or underpowered depending on repo shape.
- Generated artifacts can confuse scope unless hygiene rules stay current.

### Compatibility Constraint

Any redesign must preserve explicit allowed/forbidden path gates and must keep
scope failure visible as a hard blocker.

### Redesign Posture

Keep.

## 9. CI Evidence And Evidence Scoring

### What Exists Now

`palari ci` produces evidence bundles under `reports/evidence/TICKET-ID/`.
Evidence scoring rates whether the proof surface is complete enough for review
or acceptance.

Standard bundle:

```text
verification.log
junit.xml
palari.sarif
manifest.json
```

Key commands and files:

- `./bin/palari ci TICKET-ID`
- `./bin/palari evidence score TICKET-ID`
- `./bin/palari evidence score TICKET-ID --strict`
- `./bin/palari evidence refresh TICKET-ID`
- `docs/autonomy/evidence-quality-scoring.md`
- `contracts/review-and-acceptance.md`
- `lib/palari/ci_accept.bash`
- `lib/palari/evidence_quality.bash`
- `lib/palari/evidence_truthfulness.bash`

### Why It Matters

Evidence is what makes review and acceptance inspectable. It records what was
run and whether the ticket's own checks actually passed.

### What Works Well

- Evidence manifests include hashes and freshness fields.
- Empty JUnit and fake evidence are scored poorly.
- Skipped checks, expected failures, fixme counts, and follow-up tickets are
  modeled explicitly.
- GitHub adapter can package evidence as artifacts and SARIF.

### Awkward Or Risky

- Evidence freshness has created operational friction, especially in stacked
  work.
- Committed evidence can be confused with CI-attested evidence.
- Evidence scoring can become another ritual if it does not directly answer
  acceptability.

### Compatibility Constraint

Any redesign must keep evidence tied to a specific head and must not let
reports substitute for machine evidence. Stale evidence must remain visible.

### Redesign Posture

Keep, but model more clearly as "evidence runs" rather than paperwork.

## 10. Fresh-Context Review

### What Exists Now

Fresh-context review is required for review-gated or higher-risk work.
Reviewers inspect ticket, diff, reports, evidence, and relevant source/tests.

Key commands and files:

- `./bin/palari packet TICKET-ID reviewer`
- `reports/POS-XXXX-reviewer-note.md`
- `contracts/review-and-acceptance.md`
- `lib/palari/agents_review_scope.bash`
- `docs/autonomy/dogfooding-workflow.md`

### Why It Matters

Review prevents implementation agents from self-certifying. It also gives a
future agent enough context to trust, reopen, or continue the work.

### What Works Well

- Review is clearly separate from acceptance.
- Reviewer notes are required artifacts for gated work.
- Evidence scoring treats tiny placeholder reviewer notes as missing.
- The review contract says reviewers recommend accept, reopen, or needs-human.

### Awkward Or Risky

- The process can become slow and theatrical if every small internal repair
  requires full ritual.
- Reviewer notes are partly structured by convention rather than schema.
- The reviewed head, evidence head, and branch head need clearer computed
  alignment.

### Compatibility Constraint

Any redesign must preserve no-self-review for meaningful work and must make
review findings more structured, not less visible.

### Redesign Posture

Keep, but simplify and structure.

## 11. Human Roles, Human Profiles, And Coverage

### What Exists Now

Palari has two related role systems:

1. Repo roles under `roles/active`, `roles/proposed`, and `roles/revoked`.
2. Human governance profiles under `humans/active`, `humans/proposed`, and
   `humans/revoked`.

Active human profile:

- `HUMAN-ADMIN`
- `person_id: PERSON-QUETZA`
- alias support for `admin` and `founder`
- R5 authority with `may_approve_policy_changes: true`

Active repo roles include:

- `ROLE-ROOT`
- `ROLE-ENGINEERING-LEAD`
- `ROLE-SPECIALIST`
- `ROLE-REVIEWER`
- `ROLE-RESEARCH-LEAD`
- `ROLE-RESEARCH-EVALUATOR`
- `ROLE-SAFETY-REVIEWER`

Proposed roles include:

- `ROLE-PRODUCT-LEAD`
- `ROLE-DESIGN-LEAD`
- `ROLE-QA-LEAD`
- `ROLE-RELEASE-LEAD`
- `ROLE-AUTONOMY-COORDINATOR`

Key commands and files:

- `./bin/palari role list`
- `./bin/palari role lint`
- `./bin/palari role packet`
- `./bin/palari human create`
- `./bin/palari human list`
- `./bin/palari human show`
- `./bin/palari human lint`
- `./bin/palari human coverage WF-ID`
- `./bin/palari human org-plan`
- `contracts/authority-and-lifecycle.md`
- `contracts/human-governance.md`
- `lib/palari/roles.bash`
- `lib/palari/humans.bash`

### Why It Matters

The combination of human roles and AI roles is the core Company AI OS idea.
Humans carry authority, accountability, taste, risk ownership, and final
judgment. AI roles carry bounded capability: plan, draft, execute scoped work,
review, or propose decisions. Palari's value is coordinating those roles
without confusing capability for authority.

### What Works Well

- Role authority narrows from parent to child.
- Roles can define allowed paths, forbidden paths, max risk, delegation, and
  escalation rules.
- Human profiles model skills, authority ceilings, capacity, aliases, and
  constraints.
- Stable `person_id` prevents aliases from satisfying quorum separation.
- R5 authority requires explicit policy-change approval capability.

### Awkward Or Risky

- There are two concepts named "role": repo authority roles and human
  governance roles. This is conceptually powerful but easy to confuse.
- Proposed founder/operator roles exist but are not active; redesign should
  not assume they are already adopted.
- Human capacity and HGL planning are still approximate, not a real staffing
  or scheduling system.

### Compatibility Constraint

Any redesign must make human roles and AI roles first-class. It must not
collapse role authority into ticket labels or agent prompts. Human profiles
and AI role packets need to remain distinct.

### Redesign Posture

Keep and elevate as the center of the Company AI OS model.

## 12. AI Roles And Agent Execution Surfaces

### What Exists Now

Palari is executor-agnostic but supports several agent/executor surfaces:

- deterministic mock executor
- opencode executor
- Codex executor
- OpenRouter text-artifact executor
- adapter documentation for Codex, MCP, opencode, openclaude, and plugins

Key commands and files:

- `./bin/palari agent run TICKET-ID --executor mock`
- `./bin/palari agent run TICKET-ID --executor opencode`
- `./bin/palari agent run TICKET-ID --executor codex`
- `./bin/palari agent run TICKET-ID --executor openrouter`
- `./bin/palari model routes`
- `./bin/palari model show TICKET-ID`
- `contracts/adapters.md`
- `lib/palari/agents_review_scope.bash`
- `lib/palari/models.bash`
- `adapters/codex/`
- `adapters/mcp/`
- `adapters/openrouter/`

### Why It Matters

Palari should govern replaceable workers rather than become one more agent
runtime. This supports a Company AI OS where many AI roles or providers can
participate while Palari keeps authority and evidence boundaries.

### What Works Well

- Agent adapters are forbidden from accepting work, pushing, merging, or
  owning lifecycle authority.
- Executor evidence is written under the ticket evidence directory.
- Model routing maps risk tier to model class and records model choice into
  evidence.
- OpenRouter is optional and disabled by default.

### Awkward Or Risky

- External executors can still be complex and slow to validate.
- "Agent role" language can drift into implying authority unless role packets
  and contracts stay clear.
- Model/provider evidence is still early and may not fully capture cost,
  latency, or reliability.

### Compatibility Constraint

Any redesign must keep Palari as the authority layer around workers, not the
worker itself. AI role capability must remain subordinate to scope, risk,
broker, evidence, review, and human gates.

### Redesign Posture

Keep as adapters, not core authority.

## 13. Workflows And Company AI OS Planning

### What Exists Now

Workflows are company/process planning artifacts above tickets:

```text
workflows/proposed/
workflows/active/
workflows/closed/
```

Key commands and files:

- `./bin/palari workflow create`
- `./bin/palari workflow list`
- `./bin/palari workflow show`
- `./bin/palari workflow plan`
- `./bin/palari workflow lint`
- `./bin/palari workflow adopt`
- `./bin/palari workflow close`
- `contracts/workflows.md`
- `contracts/company-ai-os.md`
- `docs/autonomy/workflow-planning.md`
- `adapters/planning/workflow_plan.py`
- `adapters/planning/artifacts.py`
- `schemas/workflow.schema.json`

### Why It Matters

Workflows let Palari model recurring company processes rather than isolated
coding tickets. They connect goals, work units, expected human decisions,
risk ceiling, autonomy target, and human coverage.

### What Works Well

- Workflows do not grant authority.
- Planning output includes launch gate, autonomy ceiling, HGL, allowed modes,
  blocked modes, missing skills, bottlenecks, and next actions.
- R4/R5 work units require expected human decisions at or above risk.
- Workflow plans include a human decision map.

### Awkward Or Risky

- There may be no active workflow artifacts in the current repo state unless
  demo fixtures are created.
- Workflow planning can look abstract if not tied to current operational
  decisions and tickets.
- Workflow, goal, ticket, and decision relationships need a clearer visual or
  command-level map.

### Compatibility Constraint

Any redesign must preserve workflows above tickets and must not let workflows
widen ticket scope or bypass human authority.

### Redesign Posture

Keep and connect more visibly to goals, decisions, and queue state.

## 14. Human Governance Load

### What Exists Now

Human Governance Load estimates how much human judgment a workflow requires.

Key commands and files:

- `./bin/palari burden score WF-ID`
- `./bin/palari burden debt`
- `./bin/palari burden calibrate`
- `./bin/palari human coverage WF-ID`
- `./bin/palari human org-plan`
- `contracts/human-governance-load.md`
- `contracts/human-governance.md`
- `lib/palari/burden.bash`
- `adapters/planning/hgl.py`
- `adapters/planning/governance_debt.py`
- `adapters/planning/hgl_calibration.py`
- `adapters/planning/human_company_plan.py`

### Why It Matters

HGL makes human judgment visible and planned. For a Company AI OS, this is the
counterweight to naive autonomy: the system should know which decisions need
humans, what skills are missing, and where bottlenecks exist.

### What Works Well

- HGL accounts for risk, novelty, ambiguity, irreversibility, context, skill
  scarcity, and evidence quality.
- Coverage requires skill, authority, and available capacity.
- R5 coverage requires policy-change approval capability.
- `burden debt` reports missing coverage, bottlenecks, capacity pressure, weak
  evidence, policy-candidate opportunities, and R5 quorum gaps.

### Awkward Or Risky

- Scoring is necessarily approximate and can look more precise than it is.
- HGL is a planning signal, not a productivity score, and must remain framed
  that way.
- Capacity fields have already needed migration/compatibility care.

### Compatibility Constraint

Any redesign must preserve HGL as planning signal only. It must not become
employee surveillance, agent authority, or automatic acceptance.

### Redesign Posture

Keep, but explain more plainly and tie to decisions.

## 15. Policy Simulation

### What Exists Now

Policy artifacts live under:

```text
policies/proposed/
policies/active/
policies/revoked/
```

Current policy acceptance is simulation-only.

Key commands and files:

- `./bin/palari policy create`
- `./bin/palari policy list`
- `./bin/palari policy show`
- `./bin/palari policy lint`
- `./bin/palari policy simulate TICKET-ID`
- `./bin/palari policy candidates`
- `contracts/policy-acceptance.md`
- `lib/palari/policies.bash`
- `adapters/planning/policy_simulation.py`
- `adapters/planning/policy_candidates.py`
- `schemas/policy.schema.json`

### Why It Matters

Policy is how repeated human judgment may eventually become a rule. But
current Palari correctly keeps policy acceptance disabled until broker and R5
controls mature.

### What Works Well

- Simulation does not move tickets, accept work, merge, push, deploy, or
  trigger side effects.
- Policy suggestions are capped at R2 by default.
- R5 tickets are never policy-eligible.
- Unknown conditions fail closed.
- Outcome data can inform candidate confidence without activating policy.

### Awkward Or Risky

- "Policy" can sound like real authority even when it is simulation-only.
- Future redesign language must avoid implying policy acceptance exists.
- Candidate recommendations could be overtrusted if not clearly labeled
  advisory.

### Compatibility Constraint

Any redesign must preserve simulation-only semantics unless a future R5 change
explicitly authorizes real policy acceptance.

### Redesign Posture

Keep, with strong labeling.

## 16. Broker Evidence And Broker Boundaries

### What Exists Now

The broker is the boundary between agents and side effects. Current mode is
mock/local only.

Key commands and files:

- `./bin/palari broker status`
- `./bin/palari broker check`
- `./bin/palari broker run --mock`
- `./bin/palari broker evidence TICKET-ID`
- `./bin/palari broker sandbox`
- `contracts/broker.md`
- `contracts/company-ai-os.md`
- `lib/palari/broker.bash`
- `adapters/broker/mock_broker.py`
- `schemas/broker-action-request.schema.json`
- `schemas/broker-result.schema.json`
- `schemas/broker-observation.schema.json`

### Why It Matters

Agents should not own credentials or external writes. Broker boundaries are
how a future Palari can permit, deny, observe, and record side effects without
handing raw authority to agents.

### What Works Well

- Real side effects are disabled.
- Mock broker observations explicitly say `side_effects_enabled: false`.
- Permission checks can inspect a tool/action/resource without executing it.
- Local sandbox mode is narrow and honest about not being a security boundary.
- Broker evidence distinguishes observed/denied/failed from allowed.

### Awkward Or Risky

- Broker language can be mistaken for real side-effect capability.
- Local sandbox is useful but must not be oversold as hardened isolation.
- Future real broker connectors will be high-risk R5 work.

### Compatibility Constraint

Any redesign must keep agents away from credentials and external writes. It
must preserve fail-closed broker semantics and clear side-effect labels.

### Redesign Posture

Keep, but keep conservative.

## 17. Outcomes

### What Exists Now

Outcomes record what happened after governed work:

```text
outcomes/open/
outcomes/recorded/
```

Key commands and files:

- `./bin/palari outcome create`
- `./bin/palari outcome list`
- `./bin/palari outcome show`
- `./bin/palari outcome record`
- `./bin/palari outcome lint`
- `contracts/outcomes.md`
- `lib/palari/outcomes.bash`
- `schemas/outcome.schema.json`

### Why It Matters

Outcomes close the loop. They let Palari learn whether risk, HGL, evidence,
policy candidates, and human decisions were accurate after the work landed.

### What Works Well

- Outcomes do not accept work or prove business impact without linked
  evidence.
- Outcome impact fields can inform HGL calibration and policy candidates.
- Lint checks linked workflow, goal, ticket, decision, and evidence paths.

### Awkward Or Risky

- Outcome recording can be skipped if it feels like after-the-fact paperwork.
- Outcome fields can become noisy unless tied to real workflows and metrics.
- The redesign needs to make outcomes useful to the operator, not just to a
  future planner.

### Compatibility Constraint

Any redesign must preserve outcomes as learning signals only. They must not
grant policy authority or rewrite governance automatically.

### Redesign Posture

Keep, but integrate with workflow and policy learning views.

## 18. Forge-Proof Signed Gate

### What Exists Now

The optional ForgeGate kernel provides signed acceptance attestations when
`gate.enabled: true`.

Key commands and files:

- `./bin/palari gate init`
- `./bin/palari gate setup-ticket TICKET-ID`
- `./bin/palari gate attest-implement TICKET-ID`
- `./bin/palari gate attest-review TICKET-ID`
- `./bin/palari accept TICKET-ID --by HUMAN-ADMIN`
- `contracts/signed-acceptance.md`
- `lib/palari/gate.bash`
- `adapters/gate/palari_gate.py`
- `gate/`
- `layouts/palari-change.yml`
- `.palari/gate/`

### Why It Matters

Evidence files and `--by NAME` strings are not cryptographic authority. The
signed gate can prove that implement, test, and review attestations were
signed by authorized keys, bound to a commit, and connected by hash flow.

### What Works Well

- Gate mode is fail-closed when enabled.
- Attestations use narrowing delegation tokens.
- Dual control requires review by a different key.
- Ticket text cannot mint or widen authority.
- Private keys are gitignored.

### Awkward Or Risky

- Gate is optional and off by default.
- Cryptographic flow is powerful but complex for day-to-day founder use.
- It does not replace human quorum; the two controls are separate.

### Compatibility Constraint

Any redesign must not weaken ForgeGate semantics or conflate signed technical
attestation with human acceptance.

### Redesign Posture

Keep as optional high-integrity gate.

## 19. Human Acceptance And Quorum

### What Exists Now

Acceptance is explicit human authority:

```bash
./bin/palari accept TICKET-ID --by HUMAN-ADMIN
```

Config controls human quorum by risk:

```yaml
governance:
  default_human_approver: HUMAN-ADMIN
  required_human_approvals:
    R0: 0
    R1: 0
    R2: 0
    R3: 0
    R4: 0
    R5: 1
```

Key commands and files:

- `./bin/palari accept`
- `contracts/review-and-acceptance.md`
- `contracts/human-governance.md`
- `contracts/signed-acceptance.md`
- `lib/palari/ci_accept.bash`
- `humans/active/HUMAN-ADMIN-admin.md`
- `palari.config.yaml`

### Why It Matters

Acceptance is the difference between "work appears done" and "an authorized
human decided this repo may treat it as done."

### What Works Well

- Acceptance requires in-review status, named acceptor, lint, reports,
  current evidence, non-expired claim data when relevant, and scope gates.
- Human profiles provide stable identity and authority ceilings.
- Quorum is configurable by risk tier.
- Acceptance does not merge, push, deploy, or replace human judgment.

### Awkward Or Risky

- Acceptance can feel heavy when evidence/review/claim freshness disagree.
- Solo-founder mode needs to remain honest without pretending two humans exist.
- The system needs one clearer computed "ready for acceptance" answer.

### Compatibility Constraint

Any redesign must preserve explicit human authority and fail closed when
evidence, review, identity, or quorum requirements are not met.

### Redesign Posture

Keep and make easier to understand.

## 20. Branch, Merge, Cleanup, And GitHub Conventions

### What Exists Now

Palari separates implementation, acceptance, push, PR/merge, and deployment.
GitHub adapter work supports CI, artifacts, SARIF, ruleset commands, and
merge-protection integration.

Key commands and files:

- `./bin/palari github ci`
- `./bin/palari github ruleset-command`
- `./bin/palari github install-ruleset`
- `./bin/palari hygiene`
- `./bin/palari doctor lifecycle`
- `.github/workflows/`
- `contracts/adapters.md`
- `contracts/authority-and-lifecycle.md`
- `lib/palari/adapters_snapshot.bash`
- `lib/palari/hygiene.bash`

### Why It Matters

The repo source of truth must survive local worktrees, accepted tickets,
GitHub branches, evidence artifacts, and cleanup. Merge protection should be
external authority around main, while Palari provides the local governance
contract.

### What Works Well

- Push, merge, deploy, and acceptance are separate gates.
- GitHub adapter avoids reimplementing Palari parsing.
- Cleanup/hygiene concepts exist and are documented.
- Authority profiles distinguish team-safe, solo-founder, and strict postures.

### Awkward Or Risky

- Branch stacks can become hard to merge if evidence is refreshed across many
  ticket heads.
- Local/remote branch cleanup has required careful manual audits.
- Local acceptance state and GitHub PR state need clear synchronization.

### Compatibility Constraint

Any redesign must preserve the separation between accept, merge, push, and
deploy. A dashboard may show commands, but it must not silently perform them.

### Redesign Posture

Keep, simplify operator visibility.

## 21. External Maintainer Mode And Dogfooding Guidance

### What Exists Now

External maintainer mode is an emerging practice rather than a formal Palari
command. The dogfooding guidance records when to use normal Palari workflow
and how to reorient after context compaction.

Key files:

- `docs/autonomy/dogfooding-workflow.md`
- `contracts/worktree-first.md`
- `contracts/authority-and-lifecycle.md`

Current guidance says new governed work should start from clean synced main,
use tickets, claims, worktrees, packets, evidence, review, and human
acceptance. Recent practice has also identified a need for ordinary
maintainer branches when repairing Palari Orchestrator internals.

### Why It Matters

Palari cannot always be built through its own full ceremony. When the broken
thing is tickets, evidence, or worktrees, forcing every fix through the broken
mechanism can make the process slower and less safe.

### What Works Well

- Dogfooding guidance is explicit about reorientation and avoiding stale
  branches/worktrees.
- The canonical ticket loop is documented.
- The system already warns that dashboards and dry-run are not authority
  surfaces.

### Awkward Or Risky

- External maintainer mode is not yet a first-class documented contract.
- Without clear boundaries, it could become a loophole around governance.
- With too much ceremony, internal orchestrator repair becomes recursive and
  inefficient.

### Compatibility Constraint

Any redesign should explicitly define external maintainer mode for Palari
Orchestrator internals while preserving full governance for product,
customer-facing, high-risk, or authority-expanding work.

### Redesign Posture

Formalize carefully.

## 22. Memory, Skills, And Context

### What Exists Now

Palari has repo-native memory directories, skill scaffolding, and contracts for
governed memory/model providers.

Key commands and files:

- `./bin/palari memory`
- `./bin/palari skill list`
- `./bin/palari skill create`
- `./bin/palari skill lint`
- `contracts/feature-contracts-and-skills.md`
- `contracts/adapters.md`
- `adapters/memory/memory.py`
- `lib/palari/adapters_snapshot.bash`
- `memory/`
- `skills/`
- `agent-skills/`

### Why It Matters

Context recovery is one of Palari's reasons to exist. Agents need relevant
memory, skills, contracts, and prior decisions without treating chat history
as authority.

### What Works Well

- Memory and skills are guidance, not authority.
- Generated/adopter skills are separated from shipped Palari skills.
- Governed memory and model provider contracts explicitly forbid hidden
  authority or credential bypass.

### Awkward Or Risky

- Memory can become stale or contradictory.
- Skill sprawl can make packets harder to understand.
- Future external memory providers must not become hidden sources of truth.

### Compatibility Constraint

Any redesign must keep repo artifacts, not hidden memory, as authority.
Memory should cite and contextualize; it should not accept, approve, or grant.

### Redesign Posture

Keep as context layer, not authority layer.

## Current System Strengths

- Palari has a serious authority model, not just prompt conventions.
- Human/AI role separation is already present and should be treated as core.
- Goals and decisions create a real operating loop above tickets.
- Scope checks and worktrees provide practical local safety.
- Evidence, review, and acceptance are separate concepts.
- R5 governance and policy simulation boundaries are conservative.
- Broker side effects are honestly disabled.
- HGL makes human judgment visible instead of pretending autonomy is free.
- Outcomes create a learning loop.
- The system is repo-native and inspectable.

## Current System Pain Points

- The operator experience is too fragmented across files, commands, and
  reports.
- Ticket workflow can become too heavy for internal Palari repairs.
- Evidence freshness, reviewer notes, claim leases, and branch state can
  create friction and confusion.
- Worktree infrastructure has leaked into founder-level concern.
- The distinction between repo roles, human profiles, AI roles, and model
  providers is powerful but not yet easy to see.
- Current surfaces are still more ticket-centered than company-loop-centered.
- Policy, broker, and signed gates require careful labeling so they are not
  misunderstood as broader authority than they currently have.

## Redesign Compatibility Requirements

Any future redesign must preserve these requirements:

1. Goals remain first-class founder intent artifacts.
2. Decisions remain the structured way agents ask humans for judgment.
3. Human roles/profiles and AI roles/packets remain distinct.
4. Human authority is explicit and cannot be replaced by agent output,
   policy simulation, workflow metadata, memory, or ticket text.
5. Tickets remain scoped execution units with allowed and forbidden paths.
6. Worktree or equivalent execution isolation remains required for governed
   implementation work.
7. Scope checks remain hard gates.
8. Evidence remains tied to actual work and specific heads, not prose claims.
9. Fresh-context review remains separate from implementation and acceptance.
10. Acceptance remains explicit, human/governance-gated, and fail-closed.
11. Configured human quorum by risk remains enforceable and visible.
12. ForgeGate, when enabled, remains an additional signed authority gate and
    does not replace human quorum.
13. Policy acceptance remains simulation-only unless a future R5-approved
    change explicitly enables real policy authority.
14. Broker side effects remain disabled unless a future R5-approved broker
    boundary enables and enforces them.
15. HGL remains a planning signal, not employee surveillance, productivity
    scoring, or agent authority.
16. Outcomes remain learning signals and do not mutate authority.
17. Queue dry-run remains read-only and stops at human, credential,
    production, deploy, push, merge, or unclear-authority gates.
18. Dashboards and read models remain projections unless an explicit command
    performs a mutation.
19. Push, merge, deploy, and accept remain separate actions.
20. External maintainer mode must be explicitly bounded if introduced, not an
    informal loophole.
21. Repo artifacts remain the source of truth; memory and chat are context,
    not authority.
22. The redesign must make "what needs attention next" clearer without hiding
    why that next action is safe.

## Design Implication

The next redesign should not be "make Palari look like Linear" or "make it a
better ticket tracker." The deeper product is a governed company AI operating
loop:

```text
Human goals define intent.
AI roles prepare bounded work.
Human roles reserve judgment and authority.
Decisions capture judgment requests.
Evidence proves work.
Gates fail closed.
Outcomes teach the system what happened.
```

The most useful first redesign move is likely a clearer control-board/detail
read model that unifies this loop without changing authority semantics.
