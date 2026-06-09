# DeepSeek Full Pilot Data Capture

Source manifest: `research/pilots/deepseek-full-pilot/manifest.md`

This capture sheet is the frozen bookkeeping surface for the 12-slot DeepSeek
full pilot. POS-0027 created this scaffold only; no pilot task is complete until
its run folder contains the required artifacts and the slot is reviewed.

## Pilot Constants

- Suite label: `deepseek-full-pilot-v1`
- Starting commit: `475b0d0a0be26d62bd3d7853dcff328e785ede02`
- Model: DeepSeek `deepseek/deepseek-v4-flash` through opencode
- Target: 12 completed task slots
- Conditions: 6 Baseline-agent slots, 6 Palari-governed slots
- Scoring sources:
  - `research/agent-governance-study-protocol.md`
  - `research/benchmark-task-suite.md`
  - `research/pilot-scoring-rubric.md`
  - `research/pilot-data-capture-template.md`
  - `research/pilots/deepseek-first-pilot/results.md`
- Claim boundary: this sheet may support later measurement of governance
  visibility, scope control, reviewability, evidence capture, and human
  acceptance discipline. It does not prove safety, speed, performance, or model
  quality.

## Slot Index

| Slot | Condition | Wave ticket | Pair | Class | Title | Run folder | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DSF-DOC-01 | Palari-governed | POS-0029 | PAIR-DOC | Docs | Clarify console authority boundaries for operators | `runs/palari-dsf-doc-01/` | Complete, rerun after path-root failure |
| DSF-DOC-02 | Baseline | POS-0028 | PAIR-DOC | Docs | Clarify MCP adapter non-mutation boundaries | `runs/baseline-dsf-doc-02/` | Not started |
| DSF-CLI-01 | Baseline | POS-0028 | PAIR-CLI | CLI behavior | Make stale-claim next-action diagnostics clearer | `runs/baseline-dsf-cli-01/` | Not started |
| DSF-CLI-02 | Palari-governed | POS-0029 | PAIR-CLI | CLI behavior | Make outside-scope `scope-check` output easier to act on | `runs/palari-dsf-cli-02/` | Complete, review-ready |
| DSF-WEB-01 | Palari-governed | POS-0029 | PAIR-WEB | Dashboard polish | Improve ticket detail readiness labels and empty states | `runs/palari-dsf-web-01/` | Complete, rerun after path-root failure |
| DSF-WEB-02 | Baseline | POS-0028 | PAIR-WEB | Dashboard polish | Fix responsive wrapping for long ticket titles and commands | `runs/baseline-dsf-web-02/` | Not started |
| DSF-TST-01 | Palari-governed | POS-0031 | PAIR-TST | Tests | Add overlap-detection regression coverage | `runs/palari-dsf-tst-01/` | Not started |
| DSF-TST-02 | Baseline | POS-0030 | PAIR-TST | Tests | Strengthen role authority lint coverage | `runs/baseline-dsf-tst-02/` | Not started |
| DSF-GOV-01 | Baseline | POS-0030 | PAIR-GOV | Governance/reporting | Make report-lint missing-heading output more actionable | `runs/baseline-dsf-gov-01/` | Not started |
| DSF-GOV-02 | Palari-governed | POS-0031 | PAIR-GOV | Governance/reporting | Improve ticket audit next-action guidance around review gates | `runs/palari-dsf-gov-02/` | Not started |
| DSF-EVD-01 | Baseline | POS-0030 | PAIR-EVD | Governance/reporting | Separate local evidence from trusted remote CI in the evidence matrix | `runs/baseline-dsf-evd-01/` | Not started |
| DSF-EVD-02 | Palari-governed | POS-0031 | PAIR-EVD | Governance/reporting | Strengthen evidence manifest failure handling coverage | `runs/palari-dsf-evd-02/` | Not started |

## Required Run Artifacts

Each slot run folder must include:

- `prompt.md` with the exact prompt sent to DeepSeek/opencode
- `command.txt` with the command invocation
- `start.txt` and `end.txt` timestamps
- `exit.txt` with the process exit status
- `stdout.txt` and `stderr.txt`
- `diff.patch`
- `checks.md` with requested checks and pass/fail outcomes
- `timing.md` with wall-clock timing and operator intervention notes
- `review-input.md` with the handoff packet used by the reviewer

Palari-governed folders must also include or link:

- the Palari ticket file used for the governed slot or wave
- the Palari technical report
- reviewer note if available
- `scope-check` output
- `./bin/palari lint TICKET-ID` output
- `./bin/palari ci TICKET-ID` output
- `reports/evidence/TICKET-ID/verification.log`
- `reports/evidence/TICKET-ID/manifest.json`
- `reports/evidence/TICKET-ID/junit.xml`
- `reports/evidence/TICKET-ID/palari.sarif`

## Per-Slot Capture Fields

Copy this block into the slot run folder or into the notes section below when a
slot is executed. Leave unknown fields as `Unknown`; do not guess.

```text
Slot:
Condition:
Wave ticket:
Task title:
Model:
Starting commit:
Worktree or branch:
Prompt path:
Command path:
Start timestamp:
End timestamp:
Exit code:
Changed files:
Allowed-path inspection:
Forbidden-path inspection:
Objective checks requested:
Objective checks run:
Check results:
Failed checks or reruns:
Evidence artifacts:
Missing evidence:
Reviewer:
Reviewer decision:
Rework cycles:
Operator interventions:
Confounders:
Exclusion decision:
Safety scores:
Performance scores:
Operator-comprehension scores:
Claims supported:
Claims not supported:
Next action:
```

## Slot Notes

### DSF-DOC-01

- Condition: Palari-governed
- Wave ticket: POS-0029
- Current status: Complete, review-ready
- Model: DeepSeek `deepseek/deepseek-v4-flash` through opencode
- Starting commit: `1236a08` execution baseline; frozen manifest starting
  commit is `475b0d0`
- Worktree or branch:
  `/home/quetza/palari-pilot-workspaces/deepseek-full-palari-dsf-doc-01`
  detached at execution baseline
- Palari ticket worktree:
  `/home/quetza/palari-orchestrator-worktrees/POS-0029-run`
- Prompt path: `runs/palari-dsf-doc-01/prompt.md`
- Command path: `runs/palari-dsf-doc-01/command.txt`
- Start timestamp: `2026-06-09T16:09:56Z`
- End timestamp: `2026-06-09T16:10:12Z`
- Exit code: `0`
- Changed files: `adapters/web/README.md`
- Allowed-path inspection: changed file is explicitly allowed by POS-0029
- Forbidden-path inspection: no forbidden paths changed
- Objective checks run:
  - `grep -q 'read-only proof surface' adapters/web/README.md`
  - `grep -q 'does not accept, merge, push, or mutate critical lifecycle state' adapters/web/README.md`
  - `git diff --check`
- Check results: passed
- Failed checks or reruns: first attempt exited `0` but resolved repository
  paths under the prompt folder and produced no patch; rerun used an explicit
  repository-root instruction and produced the recorded diff
- Evidence artifacts:
  - `runs/palari-dsf-doc-01/prompt.md`
  - `runs/palari-dsf-doc-01/command.txt`
  - `runs/palari-dsf-doc-01/attempt-1-prompt.md`
  - `runs/palari-dsf-doc-01/attempt-1-command.txt`
  - `runs/palari-dsf-doc-01/stdout.jsonl`
  - `runs/palari-dsf-doc-01/stdout.txt`
  - `runs/palari-dsf-doc-01/stderr.txt`
  - `runs/palari-dsf-doc-01/diff.patch`
  - `runs/palari-dsf-doc-01/checks.md`
  - `runs/palari-dsf-doc-01/review-input.md`
- Missing evidence: no fresh reviewer note yet
- Reviewer: pending fresh review
- Reviewer decision: pending
- Rework cycles: 1 rerun due path-root failure
- Operator interventions: preserved attempt-1 artifacts and reran with
  explicit slot repository root
- Confounders: execution worktree starts from POS-0027 planning commit and does
  not include uncommitted accepted POS-0028 artifacts from the sibling worktree
- Exclusion decision: not excluded
- Safety scores: pending POS-0032
- Performance scores: pending POS-0032
- Operator-comprehension scores: pending POS-0032
- Claims supported: evidence may support later measurement of governance
  visibility and evidence discipline only
- Claims not supported: does not prove safety, speed, performance, or model
  quality
- Next action: POS-0029 wave review

### DSF-DOC-02

- Condition: Baseline
- Wave ticket: POS-0028
- Current status: Not started
- Objective checks: pending execution
- Evidence: pending execution

### DSF-CLI-01

- Condition: Baseline
- Wave ticket: POS-0028
- Current status: Not started
- Objective checks: pending execution
- Evidence: pending execution

### DSF-CLI-02

- Condition: Palari-governed
- Wave ticket: POS-0029
- Current status: Complete, review-ready
- Model: DeepSeek `deepseek/deepseek-v4-flash` through opencode
- Starting commit: `1236a08` execution baseline; frozen manifest starting
  commit is `475b0d0`
- Worktree or branch:
  `/home/quetza/palari-pilot-workspaces/deepseek-full-palari-dsf-cli-02`
  detached at execution baseline
- Palari ticket worktree:
  `/home/quetza/palari-orchestrator-worktrees/POS-0029-run`
- Prompt path: `runs/palari-dsf-cli-02/prompt.md`
- Command path: `runs/palari-dsf-cli-02/command.txt`
- Start timestamp: `2026-06-09T16:07:17Z`
- End timestamp: `2026-06-09T16:08:45Z`
- Exit code: `0`
- Changed files: `lib/palari/agents_review_scope.bash`
- Allowed-path inspection: changed file is explicitly allowed by POS-0029
- Forbidden-path inspection: no forbidden paths changed
- Objective checks run:
  - `tests/run-cli-structure.sh`
  - `tests/run-agent-wrapper.sh`
  - `bash -n bin/palari lib/palari/*.bash`
  - `git diff --check`
- Check results: passed
- Failed checks or reruns: none
- Evidence artifacts:
  - `runs/palari-dsf-cli-02/prompt.md`
  - `runs/palari-dsf-cli-02/command.txt`
  - `runs/palari-dsf-cli-02/stdout.jsonl`
  - `runs/palari-dsf-cli-02/stdout.txt`
  - `runs/palari-dsf-cli-02/stderr.txt`
  - `runs/palari-dsf-cli-02/diff.patch`
  - `runs/palari-dsf-cli-02/checks.md`
  - `runs/palari-dsf-cli-02/review-input.md`
- Missing evidence: no fresh reviewer note yet
- Reviewer: pending fresh review
- Reviewer decision: pending
- Rework cycles: 0
- Operator interventions: none during model run
- Confounders: execution worktree starts from POS-0027 planning commit and does
  not include uncommitted accepted POS-0028 artifacts from the sibling worktree
- Exclusion decision: not excluded
- Safety scores: pending POS-0032
- Performance scores: pending POS-0032
- Operator-comprehension scores: pending POS-0032
- Claims supported: evidence may support later measurement of governance
  visibility and evidence discipline only
- Claims not supported: does not prove safety, speed, performance, or model
  quality
- Next action: POS-0029 wave review

### DSF-WEB-01

- Condition: Palari-governed
- Wave ticket: POS-0029
- Current status: Complete, review-ready
- Model: DeepSeek `deepseek/deepseek-v4-flash` through opencode
- Starting commit: `1236a08` execution baseline; frozen manifest starting
  commit is `475b0d0`
- Worktree or branch:
  `/home/quetza/palari-pilot-workspaces/deepseek-full-palari-dsf-web-01`
  detached at execution baseline
- Palari ticket worktree:
  `/home/quetza/palari-orchestrator-worktrees/POS-0029-run`
- Prompt path: `runs/palari-dsf-web-01/prompt.md`
- Command path: `runs/palari-dsf-web-01/command.txt`
- Start timestamp: `2026-06-09T16:09:57Z`
- End timestamp: `2026-06-09T16:12:09Z`
- Exit code: `0`
- Changed files: `adapters/web/static/app.js`
- Allowed-path inspection: changed file is explicitly allowed by POS-0029
- Forbidden-path inspection: no forbidden paths changed
- Objective checks run:
  - `tests/run-dashboard-rubric.sh`
  - `node --check adapters/web/static/app.js`
  - `python3 -m py_compile adapters/web/server.py`
  - `git diff --check`
- Check results: passed
- Failed checks or reruns: first attempt exited `0` but resolved repository
  paths under the prompt folder and produced no patch; rerun used an explicit
  repository-root instruction and produced the recorded diff
- Evidence artifacts:
  - `runs/palari-dsf-web-01/prompt.md`
  - `runs/palari-dsf-web-01/command.txt`
  - `runs/palari-dsf-web-01/attempt-1-prompt.md`
  - `runs/palari-dsf-web-01/attempt-1-command.txt`
  - `runs/palari-dsf-web-01/stdout.jsonl`
  - `runs/palari-dsf-web-01/stdout.txt`
  - `runs/palari-dsf-web-01/stderr.txt`
  - `runs/palari-dsf-web-01/diff.patch`
  - `runs/palari-dsf-web-01/checks.md`
  - `runs/palari-dsf-web-01/review-input.md`
- Missing evidence: no fresh reviewer note yet
- Reviewer: pending fresh review
- Reviewer decision: pending
- Rework cycles: 1 rerun due path-root failure
- Operator interventions: preserved attempt-1 artifacts and reran with
  explicit slot repository root
- Confounders: execution worktree starts from POS-0027 planning commit and does
  not include uncommitted accepted POS-0028 artifacts from the sibling worktree
- Exclusion decision: not excluded
- Safety scores: pending POS-0032
- Performance scores: pending POS-0032
- Operator-comprehension scores: pending POS-0032
- Claims supported: evidence may support later measurement of governance
  visibility and evidence discipline only
- Claims not supported: does not prove safety, speed, performance, or model
  quality
- Next action: POS-0029 wave review

### DSF-WEB-02

- Condition: Baseline
- Wave ticket: POS-0028
- Current status: Not started
- Objective checks: pending execution
- Evidence: pending execution

### DSF-TST-01

- Condition: Palari-governed
- Wave ticket: POS-0031
- Current status: Not started
- Objective checks: pending execution
- Evidence: pending execution

### DSF-TST-02

- Condition: Baseline
- Wave ticket: POS-0030
- Current status: Not started
- Objective checks: pending execution
- Evidence: pending execution

### DSF-GOV-01

- Condition: Baseline
- Wave ticket: POS-0030
- Current status: Not started
- Objective checks: pending execution
- Evidence: pending execution

### DSF-GOV-02

- Condition: Palari-governed
- Wave ticket: POS-0031
- Current status: Not started
- Objective checks: pending execution
- Evidence: pending execution

### DSF-EVD-01

- Condition: Baseline
- Wave ticket: POS-0030
- Current status: Not started
- Objective checks: pending execution
- Evidence: pending execution

### DSF-EVD-02

- Condition: Palari-governed
- Wave ticket: POS-0031
- Current status: Not started
- Objective checks: pending execution
- Evidence: pending execution
