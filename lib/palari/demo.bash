# shellcheck shell=bash
# shellcheck disable=SC2153 # This module is sourced after core.bash and ticket helpers.
demo_ticket_ids=(DEM-0001 DEM-0002)
demo_refusal_id="DEM-0003"
demo_goal_id="GOAL-0099"
demo_decision_id="DEC-0099"
company_demo_goal_id="GOAL-9004"
company_demo_preferred_goal_id="GOAL-0100"
company_demo_legacy_workflow_id="WF-9004"
company_demo_growth_workflow_id="WF-9101"
company_demo_support_workflow_id="WF-9102"
company_demo_engineering_workflow_id="WF-9103"
company_demo_workflow_ids=("$company_demo_growth_workflow_id" "$company_demo_support_workflow_id" "$company_demo_engineering_workflow_id")
company_demo_outcome_id="OUT-9004"
company_demo_broker_ticket_id="DPC-9001"
company_demo_human_ids=(HUMAN-COS-FOUNDER HUMAN-COS-PRODUCT HUMAN-COS-TECH HUMAN-COS-CUSTOMER HUMAN-COS-PRIVACY)
company_demo_ticket_ids=(DPC-9001 DPC-9002 DPC-9003)
company_demo_decision_ids=(DEC-9001 DEC-9002 DEC-9003)

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

company_demo_goal_for_use() {
	if find_goal_file "$company_demo_preferred_goal_id" >/dev/null 2>&1; then
		printf '%s\n' "$company_demo_preferred_goal_id"
	else
		printf '%s\n' "$company_demo_goal_id"
	fi
}

company_demo_reset() {
	local id
	rm -f "$ROOT/$GOALS_ACTIVE_DIR/$company_demo_goal_id-"*.md "$ROOT/$GOALS_PROPOSED_DIR/$company_demo_goal_id-"*.md "$ROOT/$GOALS_CLOSED_DIR/$company_demo_goal_id-"*.md
	rm -f "$ROOT/$WORKFLOWS_ACTIVE_DIR/$company_demo_legacy_workflow_id-"*.md "$ROOT/$WORKFLOWS_PROPOSED_DIR/$company_demo_legacy_workflow_id-"*.md "$ROOT/$WORKFLOWS_CLOSED_DIR/$company_demo_legacy_workflow_id-"*.md
	for id in "${company_demo_workflow_ids[@]}"; do
		rm -f "$ROOT/$WORKFLOWS_ACTIVE_DIR/$id-"*.md "$ROOT/$WORKFLOWS_PROPOSED_DIR/$id-"*.md "$ROOT/$WORKFLOWS_CLOSED_DIR/$id-"*.md
	done
	for id in "${company_demo_human_ids[@]}"; do
		rm -f "$ROOT/$HUMANS_ACTIVE_DIR/$id-"*.md "$ROOT/$HUMANS_PROPOSED_DIR/$id-"*.md "$ROOT/$HUMANS_REVOKED_DIR/$id-"*.md
	done
	for id in "${company_demo_ticket_ids[@]}"; do
		demo_reset_ticket "$id"
	done
	for id in "${company_demo_decision_ids[@]}"; do
		rm -f "$ROOT/$DECISIONS_OPEN_DIR/$id-"*.md "$ROOT/$DECISIONS_DECIDED_DIR/$id-"*.md "$ROOT/$MEMORY_DIR/decisions/$id-"*.md
	done
	rm -f "$ROOT/$OUTCOMES_OPEN_DIR/$company_demo_outcome_id-"*.md "$ROOT/$OUTCOMES_RECORDED_DIR/$company_demo_outcome_id-"*.md
}

company_demo_exists() {
	local id
	find_goal_file "$company_demo_goal_id" >/dev/null 2>&1 && return 0
	find_workflow_file "$company_demo_legacy_workflow_id" >/dev/null 2>&1 && return 0
	for id in "${company_demo_workflow_ids[@]}"; do
		find_workflow_file "$id" >/dev/null 2>&1 && return 0
	done
	for id in "${company_demo_human_ids[@]}"; do
		find_human_file "$id" >/dev/null 2>&1 && return 0
	done
	for id in "${company_demo_ticket_ids[@]}"; do
		demo_ticket_exists "$id" && return 0
	done
	for id in "${company_demo_decision_ids[@]}"; do
		find_decision_file "$id" >/dev/null 2>&1 && return 0
	done
	find_outcome_file "$company_demo_outcome_id" >/dev/null 2>&1 && return 0
	return 1
}

company_demo_write_workflow_details() {
	local file="$1"
	local scenario="$2"
	python3 - "$file" "$scenario" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
scenario = sys.argv[2]
text = path.read_text(encoding="utf-8")
fixtures = {
    "growth": {
        "work_units": [
            "WU-9101|research|R2|Map beta activation signals",
            "WU-9102|draft|R3|Prepare growth experiment options",
        ],
        "decisions": [
            "R3|choose|product_strategy:L4|Choose the next beta growth experiment|novelty=medium|ambiguity=medium|evidence=normal",
        ],
    },
    "support": {
        "work_units": [
            "WU-9201|triage|R1|Classify common support requests",
            "WU-9202|draft|R2|Draft internal support replies",
        ],
        "decisions": [
            "R2|approve|customer_support:L3|Approve low-risk support reply pattern|novelty=low|ambiguity=low|evidence=strong",
        ],
    },
    "engineering": {
        "work_units": [
            "WU-9301|design|R4|Design broker boundary hardening",
            "WU-9302|review|R5|Review privacy boundary before autonomous governance",
        ],
        "decisions": [
            "R4|approve|technical_governance:L4|Approve broker boundary design|context=high|evidence=normal",
            "R5|approve|privacy:L5|Approve privacy boundary before autonomous governance|novelty=high|ambiguity=high|irreversibility=high|evidence=weak",
        ],
    },
}
fixture = fixtures[scenario]
text = text.replace("work_units:\n", "work_units:\n" + "".join(f"  - {item}\n" for item in fixture["work_units"]))
text = text.replace("expected_decisions:\n", "expected_decisions:\n" + "".join(f"  - {item}\n" for item in fixture["decisions"]))
path.write_text(text, encoding="utf-8")
PY
}

company_demo_write_broker_evidence() {
	local ticket_id="$1"
	local out_dir="$ROOT/$EVIDENCE_DIR/$ticket_id/broker/RUN-COMPANY-OS-DEMO"
	local stdout_file="$out_dir/stdout.txt"
	local stderr_file="$out_dir/stderr.txt"
	local stdout_hash stderr_hash
	mkdir -p "$out_dir"
	printf 'company os demo broker observation\n' >"$stdout_file"
	: >"$stderr_file"
	: >"$out_dir/changed_paths.txt"
	stdout_hash="$(sha256_file "$stdout_file")"
	stderr_hash="$(sha256_file "$stderr_file")"
	cat >"$out_dir/command.json" <<DOC
{
  "command": ["printf", "company os demo broker observation"],
  "created_at": "2026-01-01T00:00:00Z",
  "credentials_available_to_agents": false,
  "cwd": "$ROOT",
  "mode": "mock",
  "network_or_hosted_api_access": false,
  "schema_version": "1",
  "side_effects_enabled": false,
  "ticket": "$ticket_id"
}
DOC
	cat >"$out_dir/summary.json" <<DOC
{
  "artifacts": {
    "changed_paths": "changed_paths.txt",
    "command": "command.json",
    "stderr": "stderr.txt",
    "stdout": "stdout.txt"
  },
  "changed_paths": [],
  "command": ["printf", "company os demo broker observation"],
  "created_at": "2026-01-01T00:00:00Z",
  "credentials_available_to_agents": false,
  "cwd": "$ROOT",
  "executed": true,
  "exit_code": 0,
  "mode": "mock",
  "network_or_hosted_api_access": false,
  "refusal_reason": "",
  "refused": false,
  "schema_version": "1",
  "side_effects_enabled": false,
  "stderr_sha256": "$stderr_hash",
  "stdout_sha256": "$stdout_hash",
  "ticket": "$ticket_id",
  "timed_out": false
}
DOC
}

cmd_demo_company_os() {
	local force="$1"
	local goal_id workflow_file ticket_id decision_id outcome_evidence outcome_file
	cmd_init >/dev/null
	require_base_folders
	if company_demo_exists; then
		[[ "$force" == "true" ]] || die "company OS demo fixtures already exist; pass --force to replace demo fixtures"
		company_demo_reset
	fi

	goal_id="$(company_demo_goal_for_use)"
	if ! find_goal_file "$goal_id" >/dev/null 2>&1; then
		cmd_goal_create "$goal_id" "Company OS demo" \
			--owner founder \
			--success "The demo shows workflow, human coverage, policy candidate, broker evidence, and outcome state without external services" >/dev/null
	fi

	cmd_human_create HUMAN-COS-FOUNDER "Founder General Manager" \
		--skill company_governance:L5 \
		--skill operations:L5 \
		--role founder_general_manager \
		--capacity-hgl 70 \
		--authority-max-risk R5 \
		--may-approve-policy-changes >/dev/null
	cmd_human_adopt HUMAN-COS-FOUNDER --by founder >/dev/null

	cmd_human_create HUMAN-COS-PRODUCT "Product Growth Governor" \
		--skill product_strategy:L4 \
		--skill growth:L4 \
		--role product_growth_governor \
		--capacity-hgl 35 \
		--authority-max-risk R3 >/dev/null
	cmd_human_adopt HUMAN-COS-PRODUCT --by founder >/dev/null

	cmd_human_create HUMAN-COS-TECH "Technical Security Governor" \
		--skill technical_governance:L4 \
		--skill security:L4 \
		--role technical_security_governor \
		--capacity-hgl 40 \
		--authority-max-risk R4 >/dev/null
	cmd_human_adopt HUMAN-COS-TECH --by founder >/dev/null

	cmd_human_create HUMAN-COS-CUSTOMER "Customer Brand Governor" \
		--skill customer_support:L3 \
		--skill brand:L3 \
		--role customer_brand_governor \
		--capacity-hgl 30 \
		--authority-max-risk R2 >/dev/null
	cmd_human_adopt HUMAN-COS-CUSTOMER --by founder >/dev/null

	cmd_human_create HUMAN-COS-PRIVACY "Proposed Privacy Governor" \
		--skill privacy:L5 \
		--role privacy_governor \
		--capacity-hgl 20 \
		--authority-max-risk R5 \
		--may-approve-policy-changes >/dev/null

	cmd_workflow_create "$company_demo_growth_workflow_id" "Growth beta experiment" \
		--goal "$goal_id" \
		--owner founder \
		--risk-ceiling R3 \
		--success-metric "Product governor can choose a beta growth experiment with visible bottleneck" >/dev/null
	workflow_file="$(find_workflow_file "$company_demo_growth_workflow_id" proposed)"
	company_demo_write_workflow_details "$workflow_file" growth
	cmd_workflow_adopt "$company_demo_growth_workflow_id" --by founder >/dev/null

	cmd_workflow_create "$company_demo_support_workflow_id" "Support reply patterns" \
		--goal "$goal_id" \
		--owner founder \
		--risk-ceiling R2 \
		--success-metric "Support work shows green high-autonomy governance with low-risk evidence" >/dev/null
	workflow_file="$(find_workflow_file "$company_demo_support_workflow_id" proposed)"
	company_demo_write_workflow_details "$workflow_file" support
	cmd_workflow_adopt "$company_demo_support_workflow_id" --by founder >/dev/null

	cmd_workflow_create "$company_demo_engineering_workflow_id" "Engineering broker boundary" \
		--goal "$goal_id" \
		--owner founder \
		--risk-ceiling R5 \
		--success-metric "Engineering work stays simulation-only until privacy coverage exists" >/dev/null
	workflow_file="$(find_workflow_file "$company_demo_engineering_workflow_id" proposed)"
	company_demo_write_workflow_details "$workflow_file" engineering
	cmd_workflow_adopt "$company_demo_engineering_workflow_id" --by founder >/dev/null

	for index in 0 1 2; do
		ticket_id="${company_demo_ticket_ids[$index]}"
		decision_id="${company_demo_decision_ids[$index]}"
		cmd_ticket_create "$ticket_id" "Company OS demo docs approval $((index + 1))" \
			--goal "$goal_id" \
			--stream demo \
			--risk R1 \
			--priority P2 \
			--allowed README.md \
			--allowed "reports/evidence/$ticket_id/**" \
			--verify "test -f README.md" >/dev/null
		cmd_decide_create "$decision_id" "Approve company OS demo docs change $((index + 1))" \
			--ticket "$ticket_id" \
			--goal "$goal_id" \
			--option "Approve demo docs-only change" \
			--option "Request more review" \
			--recommend 1 \
			--raised-by demo >/dev/null
		cmd_decide_record "$decision_id" --choice 1 --by founder --note "Deterministic company OS demo decision." >/dev/null
		rm -f "$ROOT/$MEMORY_DIR/decisions/$decision_id-"*.md
	done

	company_demo_write_broker_evidence "$company_demo_broker_ticket_id"
	outcome_evidence="$EVIDENCE_DIR/$company_demo_broker_ticket_id/broker/RUN-COMPANY-OS-DEMO/summary.json"
	cmd_outcome_create "$company_demo_outcome_id" \
		--workflow "$company_demo_support_workflow_id" \
		--status observed \
		--goal "$goal_id" \
		--ticket "$company_demo_broker_ticket_id" \
		--decision DEC-9001 \
		--evidence "$outcome_evidence" \
		--title "Company OS demo outcome" >/dev/null
	outcome_file="$(find_outcome_file "$company_demo_outcome_id" open)"
	update_frontmatter_scalars "$outcome_file" \
		"metric_name"$'\035'"support_resolution_rate"$'\034' \
		"metric_before"$'\035'"0.70"$'\034' \
		"metric_after"$'\035'"0.82"$'\034' \
		"metric_delta"$'\035'"0.12"$'\034' \
		"risk_predicted"$'\035'"R1"$'\034' \
		"risk_actual"$'\035'"R1"$'\034' \
		"hgl_predicted"$'\035'"3"$'\034' \
		"hgl_actual"$'\035'"1"$'\034' \
		"human_decisions_predicted"$'\035'"1"$'\034' \
		"human_decisions_actual"$'\035'"1"$'\034' \
		"review_outcome"$'\035'"passed"$'\034' \
		"policy_candidate"$'\035'"true"$'\034' \
		"notes"$'\035'"successful low-risk demo outcome"$'\034'
	cmd_outcome_record "$company_demo_outcome_id" --by founder >/dev/null

	printf 'demo: wrote Company OS fixtures\n'
	printf 'goal: %s active\n' "$goal_id"
	printf 'workflow: %s growth yellow conditional autonomy\n' "$company_demo_growth_workflow_id"
	printf 'workflow: %s support green high autonomy\n' "$company_demo_support_workflow_id"
	printf 'workflow: %s engineering red simulation only\n' "$company_demo_engineering_workflow_id"
	printf 'humans: founder, product/growth, technical/security, and customer/brand active\n'
	printf 'proposed human: HUMAN-COS-PRIVACY privacy L5 not active\n'
	printf 'missing skill: privacy:L5 active coverage\n'
	printf 'policy candidate: run ./bin/palari policy candidates\n'
	printf 'broker evidence: %s\n' "$outcome_evidence"
	printf 'outcome: %s recorded\n' "$company_demo_outcome_id"
	printf 'inspect: ./bin/palari workflow plan %s && ./bin/palari workflow plan %s && ./bin/palari workflow plan %s\n' "$company_demo_growth_workflow_id" "$company_demo_support_workflow_id" "$company_demo_engineering_workflow_id"
	printf 'snapshot: ./bin/palari snapshot --json && ./bin/palari web --check\n'
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
	local force="false" agent_refusal="false" company_os="false" id file now expires
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
		--company-os)
			company_os="true"
			shift
			;;
		*) die "unknown demo option: $1" ;;
		esac
	done
	if [[ "$agent_refusal" == "true" && "$company_os" == "true" ]]; then
		die "choose one demo mode: --agent-refusal or --company-os"
	fi
	if [[ "$agent_refusal" == "true" ]]; then
		cmd_demo_agent_refusal "$force"
		return 0
	fi
	if [[ "$company_os" == "true" ]]; then
		cmd_demo_company_os "$force"
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
