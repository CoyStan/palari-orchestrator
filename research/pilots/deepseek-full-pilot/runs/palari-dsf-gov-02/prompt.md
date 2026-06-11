# DSF-GOV-02 Palari-Governed Task Prompt

You are working in this repository root:

`/home/operator/palari-pilot-workspaces/deepseek-full-palari-dsf-gov-02`

All relative paths in this prompt are relative to that repository root, not to
the folder containing this prompt file.

Ticket context:

- Ticket: POS-0031, "DeepSeek Palari-governed wave 2"
- Condition: Palari-governed
- Claimed by: codex
- Claim ref: `refs/palari/claims/POS-0031`
- Human acceptance remains outside your authority.
- Palari will run scope-check, lint, CI evidence capture, technical-report
  review, and a fresh reviewer gate after your patch is integrated.

Task: improve ticket audit next-action guidance around review gates. When a
ticket is claimed or in review, the next action should make it clearer whether
the operator needs evidence, reports, reviewer packet work, review acceptance,
or reopen/escalation. Preserve existing command names and lifecycle semantics.

Allowed product/test paths for this slot:

- `lib/palari/init_adopt.bash`
- `lib/palari/tickets_workspace.bash`
- `tests/run-golden.sh`
- `tests/golden/status.contains.txt`

Ticket governance paths exist for the wave, but do not edit them in this slot.

Forbidden paths and operations:

- Do not edit `.env`, `.env.*`, secrets paths, token files, `infra/prod/**`,
  or `prod/**`.
- Do not commit, push, merge, deploy, mutate production, touch databases, run
  destructive git commands, accept tickets, or move lifecycle status.

Required objective checks:

- `tests/run-golden.sh`
- `tests/run-cli-structure.sh`
- `grep -q 'Next required action' tests/golden/status.contains.txt`
- `git diff --check`

Implementation guidance:

- Prefer concise operator-facing copy and focused fixture coverage.
- Keep the guidance accurate for Palari authority boundaries: the dashboard or
  status output may point to commands, but acceptance remains explicit.
- Do not add new dependencies or rewrite the lifecycle model.

Final response:

- Summarize changed files.
- List checks run and results.
- Mention any skipped checks or blockers.
