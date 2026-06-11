# shellcheck shell=bash
# shellcheck disable=SC2153 # This module is sourced after core.bash and ticket helpers.
demo_ticket_ids=(DEM-0001 DEM-0002)
demo_refusal_id="DEM-0003"
demo_goal_id="GOAL-0099"
demo_decision_id="DEC-0099"

demo_ticket_exists() {
	local id="$1"
	find_ticket_file "$id" >/dev/null 2>&1 && return 0
	[[ -e "$ROOT/$REPORTS_DIR/$id-technical-report.md" ]] && return 0
	[[ -e "$ROOT/$REPORTS_DIR/$id-reviewer-note.md" ]] && return 0
	[[ -e "$ROOT/$HUMAN_REPORTS_DIR/$id-human-report.md" ]] && return 0
	[[ -e "$ROOT/$HANDOFFS_DIR/$id-handoff.md" ]] && return 0
	[[ -e "$ROOT/$EVIDENCE_DIR/$id" ]] && return 0
	return 1
}

demo_reset_ticket() {
	local id="$1"
	[[ -n "$id" ]] || die "demo reset requires a ticket id"
	rm -f "$ROOT/$OPEN_DIR/$id-"*.md "$ROOT/$CLOSED_DIR/$id-"*.md
	rm -f "$ROOT/$REPORTS_DIR/$id-technical-report.md" "$ROOT/$REPORTS_DIR/$id-reviewer-note.md"
	rm -f "$ROOT/$HUMAN_REPORTS_DIR/$id-human-report.md"
	rm -f "$ROOT/$HANDOFFS_DIR/$id-handoff.md"
	rm -rf "$ROOT/$EVIDENCE_DIR/${id:?}"
}

demo_reset_goal_and_decision() {
	rm -f "$ROOT/$GOALS_ACTIVE_DIR/$demo_goal_id-"*.md "$ROOT/$GOALS_PROPOSED_DIR/$demo_goal_id-"*.md "$ROOT/$GOALS_CLOSED_DIR/$demo_goal_id-"*.md
	rm -f "$ROOT/$DECISIONS_OPEN_DIR/$demo_decision_id-"*.md "$ROOT/$DECISIONS_DECIDED_DIR/$demo_decision_id-"*.md
}

demo_refusal_exists() {
	demo_ticket_exists "$demo_refusal_id" && return 0
	[[ -e "$ROOT/$EVIDENCE_DIR/$demo_refusal_id/executor/mock" ]] && return 0
	return 1
}

demo_write_review_ready_reports() {
	mkdir -p "$ROOT/$REPORTS_DIR"
	cat >"$ROOT/$REPORTS_DIR/DEM-0001-technical-report.md" <<'DOC'
# DEM-0001 Technical Report

## Files Changed

```text
docs/operator-console-quickstart.md
tickets/open/DEM-0001-operator-console-quickstart.md
```

## Verification

- Passed: manual demo evidence review
- Passed: operator can see queue, role, evidence, and accept command in the console

## CI Evidence

- Demo evidence is available under `reports/evidence/DEM-0001/`.

## Risks / Follow-Ups

- Replace this fixture with real agent evidence before using Palari for production work.
DOC
	cat >"$ROOT/$REPORTS_DIR/DEM-0001-reviewer-note.md" <<'DOC'
# DEM-0001 Reviewer Note

## Review Result

Fresh-context review recommends human acceptance for the demo fixture.

## Findings

- The fixture demonstrates a bounded ticket moving from delegated work to review.
- Reports and evidence are present so the console can show acceptance readiness.

## Scope Reviewed

- Ticket scope stayed in docs, tickets, and reports.
- No production, secret, deployment, or authority paths are included.

## Verification Reviewed

- Demo evidence bundle is present.
- The operator console can render the ticket as ready for acceptance.

## Required Changes

- None for the local demo fixture.

## Recommendation

- Accept only as a demo sample. Real work still needs real implementation evidence.
DOC
}

demo_write_refusal_handoff() {
	mkdir -p "$ROOT/$HANDOFFS_DIR"
	cat >"$ROOT/$HANDOFFS_DIR/DEM-0003-handoff.md" <<'DOC'
# DEM-0003 Handoff

Ticket: DEM-0003

## Current State

This demo ticket is blocked because a deterministic mock executor attempted to
write `.env`, which is a forbidden path.

## Blocker

Scope-check refused the change. The executor evidence is preserved under
`reports/evidence/DEM-0003/executor/mock/`.

## Recommendation

Inspect the preserved executor evidence, keep the ticket blocked, and use the
fixture to verify that Palari surfaces forbidden-path refusals without accepting
or advancing the work.
DOC
}

demo_write_refusal_evidence() {
	local id="$1"
	local out_dir="$ROOT/$EVIDENCE_DIR/$id/executor/mock"
	mkdir -p "$out_dir"
	cat >"$out_dir/command.txt" <<'DOC'
executor: mock
ticket: DEM-0003
scenario: forbidden-path
plan: append one line to .env (a default forbidden path)
note: deterministic local edit; no AI tool, network, or credentials involved
DOC
	cat >"$out_dir/run.stdout" <<'DOC'
mock: attempted to edit .env (forbidden path)
DOC
	: >"$out_dir/run.stderr"
	printf '0\n' >"$out_dir/run.exit"
	: >"$out_dir/scope-check.out"
	cat >"$out_dir/scope-check.err" <<'DOC'
scope-check: .env forbidden by ticket DEM-0003
DOC
	printf '1\n' >"$out_dir/scope-check.exit"
	printf 'not-run\n' >"$out_dir/ci.exit"
}

demo_write_human_gate_notes() {
	mkdir -p "$ROOT/$HUMAN_REPORTS_DIR" "$ROOT/$HANDOFFS_DIR"
	cat >"$ROOT/$HUMAN_REPORTS_DIR/DEM-0002-human-report.md" <<'DOC'
# DEM-0002 Human Report

## Why This Mattered

This higher-risk governance change should not be handed to an agent until a
founder or operator approves the scope and risk.

## What Changed

- The ticket is intentionally stopped at `needs-human`.
- No implementation evidence has been created yet.

## What I Should Know

The sample exists to show how Palari makes human gates visible before work
continues.

## What To Check

- Is the proposed scope acceptable?
- Does the risk level match the decision being delegated?
- Should an agent receive a packet for this work?

## Recommended Next Move

Keep the ticket in `needs-human` until a founder or operator approves the
scope, risk, and acceptance criteria.
DOC
	cat >"$ROOT/$HANDOFFS_DIR/DEM-0002-handoff.md" <<'DOC'
# DEM-0002 Handoff

Ticket: DEM-0002

## Current State

This demo ticket is paused at `needs-human` to show the operator gate.

## Blocker

A human needs to approve the scope, risk, and next packet before implementation.

## Recommendation

Use the console to inspect the ticket, then decide whether to reopen, block, or
keep it waiting for human approval.
DOC
}

demo_write_evidence() {
	local id="$1"
	local out_dir="$ROOT/$EVIDENCE_DIR/$id"
	local log="$out_dir/verification.log"
	local junit="$out_dir/junit.xml"
	local sarif="$out_dir/palari.sarif"
	local manifest="$out_dir/manifest.json"
	local head_sha
	mkdir -p "$out_dir"
	head_sha="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || true)"
	cat >"$log" <<'DOC'
# Palari Demo Evidence

- Ticket: DEM-0001
- Result: sample evidence bundle for the local operator console
- Note: no external agent or CI runner was invoked; this fixture exists so new
  users can inspect the Palari review and acceptance surfaces immediately.

## verification 1

Skipped manual/descriptive check: `manual demo evidence review`
DOC
	cat >"$junit" <<'DOC'
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="palari-demo" tests="1" failures="0" skipped="1">
  <testcase classname="palari" name="demo evidence"><skipped message="sample fixture; no agent run invoked"/></testcase>
</testsuite>
DOC
	cat >"$sarif" <<'DOC'
{
  "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
  "version": "2.1.0",
  "runs": [
    {
      "tool": {"driver": {"name": "palari-demo"}},
      "automationDetails": {"id": "palari/DEM-0001"},
      "results": []
    }
  ]
}
DOC
	{
		printf '{\n'
		printf '  "schema_version": "1",\n'
		printf '  "generator": "palari-ci",\n'
		printf '  "ticket": '
		json_string "$id"
		printf ',\n  "base_ref": "local demo fixture",\n'
		printf '  "head_sha": '
		json_string "$head_sha"
		printf ',\n  "created_at": '
		json_string "$(now_utc)"
		printf ',\n  "status": "passed",\n'
		printf '  "tests": 1,\n'
		printf '  "failures": 0,\n'
		printf '  "skipped": 1,\n'
		printf '  "artifacts": [\n'
		printf '    {"name":"verification.log","sha256":'
		json_string "$(sha256_file "$log")"
		printf '},\n'
		printf '    {"name":"junit.xml","sha256":'
		json_string "$(sha256_file "$junit")"
		printf '},\n'
		printf '    {"name":"palari.sarif","sha256":'
		json_string "$(sha256_file "$sarif")"
		printf '}\n'
		printf '  ]\n'
		printf '}\n'
	} >"$manifest"
}

cmd_demo_agent_refusal() {
	local force="$1"
	local file
	cmd_init >/dev/null
	require_base_folders
	if demo_refusal_exists; then
		[[ "$force" == "true" ]] || die "demo agent-refusal fixture already exists for $demo_refusal_id; pass --force to replace demo fixtures"
		demo_reset_ticket "$demo_refusal_id"
	fi
	cmd_ticket_create "$demo_refusal_id" "Mock agent forbidden-path refusal" \
		--stream demo \
		--risk R1 \
		--priority P1 \
		--allowed "docs/**" \
		--allowed "tickets/**" \
		--allowed "reports/**" \
		--verify "mock executor forbidden-path refusal fixture" \
		--review >/dev/null
	file="$(find_ticket_file "$demo_refusal_id")"
	update_frontmatter_scalars "$file" \
		"status"$'\035'"blocked"$'\034' \
		"updated"$'\035'"$(today_utc)"$'\034'
	demo_write_refusal_handoff
	demo_write_refusal_evidence "$demo_refusal_id"
	printf 'demo: wrote mock-agent refusal fixture\n'
	printf 'ticket: %s blocked after mock executor attempted forbidden .env\n' "$demo_refusal_id"
	printf 'evidence: %s/%s/executor/mock\n' "$EVIDENCE_DIR" "$demo_refusal_id"
	printf 'inspect: ./bin/palari lint %s && ./bin/palari web\n' "$demo_refusal_id"
}

cmd_demo() {
	local force="false" agent_refusal="false" id file now expires
	while (($# > 0)); do
		case "$1" in
		--force)
			force="true"
			shift
			;;
		--agent-refusal)
			agent_refusal="true"
			shift
			;;
		*) die "unknown demo option: $1" ;;
		esac
	done
	if [[ "$agent_refusal" == "true" ]]; then
		cmd_demo_agent_refusal "$force"
		return 0
	fi
	cmd_init >/dev/null
	require_base_folders
	for id in "${demo_ticket_ids[@]}"; do
		if demo_ticket_exists "$id"; then
			[[ "$force" == "true" ]] || die "demo fixture already exists for $id; pass --force to replace demo fixtures"
			demo_reset_ticket "$id"
		fi
	done
	if find_goal_file "$demo_goal_id" >/dev/null 2>&1 || find_decision_file "$demo_decision_id" >/dev/null 2>&1; then
		[[ "$force" == "true" ]] || die "demo goal/decision fixtures already exist; pass --force to replace demo fixtures"
		demo_reset_goal_and_decision
	fi

	cmd_goal_create "$demo_goal_id" "Demo: evaluate Palari governance" \
		--owner founder \
		--success "An operator can see the queue, role boundary, evidence, decisions, and human gate" >/dev/null

	cmd_ticket_create DEM-0001 "Operator console quickstart" \
		--goal "$demo_goal_id" \
		--stream demo \
		--risk R1 \
		--priority P1 \
		--allowed "docs/**" \
		--allowed "tickets/**" \
		--allowed "reports/**" \
		--verify "manual demo evidence review" \
		--review \
		--by-role ROLE-ENGINEERING-LEAD \
		--delegate-to-role ROLE-SPECIALIST >/dev/null
	file="$(find_ticket_file DEM-0001)"
	now="$(now_utc)"
	expires="$(iso_from_epoch "$(($(epoch_utc) + 604800))")"
	update_frontmatter_scalars "$file" \
		"status"$'\035'"in-review"$'\034' \
		"claimed_by"$'\035'"demo-specialist"$'\034' \
		"claimed_at"$'\035'"$now"$'\034' \
		"claim_heartbeat_at"$'\035'"$now"$'\034' \
		"claim_expires_at"$'\035'"$expires"$'\034' \
		"updated"$'\035'"$(today_utc)"$'\034'
	demo_write_review_ready_reports
	demo_write_evidence DEM-0001

	cmd_ticket_create DEM-0002 "Human approval gate" \
		--goal "$demo_goal_id" \
		--stream demo \
		--risk R2 \
		--priority P0 \
		--allowed "docs/**" \
		--allowed "tickets/**" \
		--allowed "reports/**" \
		--verify "manual founder approval before implementation" \
		--review \
		--human \
		--by-role ROLE-ENGINEERING-LEAD >/dev/null
	file="$(find_ticket_file DEM-0002)"
	update_frontmatter_scalars "$file" \
		"status"$'\035'"needs-human"$'\034' \
		"updated"$'\035'"$(today_utc)"$'\034'
	demo_write_human_gate_notes

	cmd_decide_create "$demo_decision_id" "Demo: choose console refresh interval" \
		--ticket DEM-0001 \
		--goal "$demo_goal_id" \
		--option "5 seconds (snappier, more polling)" \
		--option "30 seconds (calmer, may lag)" \
		--recommend 2 --default 2 --respond-by "$(today_utc)" \
		--raised-by demo-specialist >/dev/null

	printf 'demo: wrote local Palari operator fixtures\n'
	printf 'goal: %s active with both demo tickets linked\n' "$demo_goal_id"
	printf 'ticket: DEM-0001 in-review with reports and evidence\n'
	printf 'ticket: DEM-0002 needs human approval before implementation\n'
	printf 'decision: %s open; record it with ./bin/palari decide record %s --choice N --by YOU\n' "$demo_decision_id" "$demo_decision_id"
	printf 'plan: ./bin/palari run --dry-run\n'
	printf 'next: ./bin/palari web\n'
}
