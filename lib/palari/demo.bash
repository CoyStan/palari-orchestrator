# shellcheck shell=bash
# shellcheck disable=SC2153 # This module is sourced after core.bash and ticket helpers.
demo_ticket_ids=(DEM-0001 DEM-0002)

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
	rm -f "$ROOT/$OPEN_DIR/$id-"*.md "$ROOT/$CLOSED_DIR/$id-"*.md
	rm -f "$ROOT/$REPORTS_DIR/$id-technical-report.md" "$ROOT/$REPORTS_DIR/$id-reviewer-note.md"
	rm -f "$ROOT/$HUMAN_REPORTS_DIR/$id-human-report.md"
	rm -f "$ROOT/$HANDOFFS_DIR/$id-handoff.md"
	rm -rf "$ROOT/$EVIDENCE_DIR/$id"
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

cmd_demo() {
	local force="false" id file now expires
	while (($# > 0)); do
		case "$1" in
		--force)
			force="true"
			shift
			;;
		*) die "unknown demo option: $1" ;;
		esac
	done
	cmd_init >/dev/null
	require_base_folders
	for id in "${demo_ticket_ids[@]}"; do
		if demo_ticket_exists "$id"; then
			[[ "$force" == "true" ]] || die "demo fixture already exists for $id; pass --force to replace demo fixtures"
			demo_reset_ticket "$id"
		fi
	done

	cmd_ticket_create DEM-0001 "Operator console quickstart" \
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

	printf 'demo: wrote local Palari operator fixtures\n'
	printf 'ticket: DEM-0001 in-review with reports and evidence\n'
	printf 'ticket: DEM-0002 needs human approval before implementation\n'
	printf 'next: ./bin/palari web\n'
}
