# shellcheck shell=bash
# shellcheck disable=SC2153 # ROOT/EVIDENCE_DIR are sourced from core.bash.

evidence_score_add() {
	local points="$1"
	local ok="$2"
	local label="$3"
	local detail="${4:-}"
	if [[ "$ok" == "ok" ]]; then
		score=$((score + points))
		printf '  ok      +%s %s\n' "$points" "$label"
	else
		missing=$((missing + 1))
		printf '  missing +0  %s\n' "$label"
		[[ -z "$detail" ]] || printf '          %s\n' "$detail"
	fi
}

evidence_score_rating() {
	local score="$1"
	if ((score >= 95)); then
		printf 'ready\n'
	elif ((score >= 75)); then
		printf 'needs-review\n'
	else
		printf 'needs-evidence\n'
	fi
}

evidence_score_next_action() {
	local ticket_id="$1"
	local status="$2"
	local score="$3"
	if ((score < 75)); then
		printf 'run or repair evidence: ./bin/palari ci %s\n' "$ticket_id"
	elif ((score < 100)); then
		printf 'add missing report/review artifacts, then rerun: ./bin/palari evidence score %s\n' "$ticket_id"
	elif [[ "$status" == "claimed" || "$status" == "reopened" ]]; then
		printf 'move to review: ./bin/palari ticket ready %s\n' "$ticket_id"
	elif [[ "$status" == "in-review" ]]; then
		printf 'human gate: ./bin/palari accept %s --by HUMAN\n' "$ticket_id"
	else
		printf 'monitor only; ticket status is %s\n' "$status"
	fi
}

cmd_evidence_score() {
	require_base_folders
	local ticket="${1:-}"
	[[ -n "$ticket" ]] || die "evidence score requires ticket id"
	shift || true

	local strict="false" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--strict)
			strict="true"
			shift
			;;
		*) die "unknown evidence score option: $arg" ;;
		esac
	done

	local file ticket_id title status risk requires_review requires_human evidence_dir
	file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
	ticket_id="$(frontmatter_value "$file" id)"
	title="$(frontmatter_value "$file" title)"
	status="$(frontmatter_value "$file" status)"
	risk="$(frontmatter_value "$file" risk)"
	requires_review="$(frontmatter_value "$file" requires_review)"
	requires_human="$(frontmatter_value "$file" requires_human_confirmation)"
	evidence_dir="$ROOT/$EVIDENCE_DIR/$ticket_id"

	local score=0 missing=0 name manifest_detail technical reviewer human lint_ok scope_ok
	printf 'Evidence quality: %s - %s\n' "$ticket_id" "$title"
	printf 'status: %s\n' "$status"
	printf 'checks:\n'

	for name in verification.log junit.xml palari.sarif manifest.json; do
		if [[ ! -s "$evidence_dir/$name" ]]; then
			evidence_score_add 5 missing "$EVIDENCE_DIR/$ticket_id/$name"
			continue
		fi
		if [[ "$name" == "junit.xml" ]]; then
			# Presence is not proof: the junit file must contain at least one
			# testcase and report no failures or errors, otherwise an executor
			# could satisfy the gate with an empty or failing report.
			if ! grep -Fq '<testcase' "$evidence_dir/$name"; then
				evidence_score_add 5 missing "$EVIDENCE_DIR/$ticket_id/$name" "junit.xml exists but contains no <testcase> entries"
				continue
			fi
			if grep -Eq 'failures="[1-9][0-9]*"|errors="[1-9][0-9]*"' "$evidence_dir/$name"; then
				evidence_score_add 5 missing "$EVIDENCE_DIR/$ticket_id/$name" "junit.xml reports failures or errors"
				continue
			fi
		fi
		evidence_score_add 5 ok "$EVIDENCE_DIR/$ticket_id/$name"
	done

	if manifest_detail="$(ci_existing_evidence_valid "$ticket_id" 2>&1)"; then
		evidence_score_add 20 ok "manifest integrity"
	else
		evidence_score_add 20 missing "manifest integrity" "$manifest_detail"
	fi

	technical="$(find_report_file "$REPORTS_DIR" "$ticket_id" '(^# .*Technical Report$|^## Files Changed$|^## Verification$|^## Risks / Follow-Ups$)' || true)"
	if [[ -n "$technical" ]]; then
		evidence_score_add 15 ok "technical report"
	else
		evidence_score_add 15 missing "technical report" "expected reports/${ticket_id}-technical-report.md or equivalent"
	fi

	reviewer="$(find_report_file "$REPORTS_DIR" "$ticket_id" '(^# .*Reviewer Note$|^## Review Result$|^## Required Changes$)' || true)"
	if [[ "$requires_review" == "true" || "$risk" =~ ^R[2345]$ ]]; then
		if [[ -z "$reviewer" ]]; then
			evidence_score_add 15 missing "fresh reviewer note" "required for review-gated or R2+ work"
		elif [[ "$(wc -c <"$reviewer" | tr -d ' ')" -lt 200 ]]; then
			evidence_score_add 15 missing "fresh reviewer note" "reviewer note is too thin to be a real review (< 200 bytes)"
		else
			evidence_score_add 15 ok "fresh reviewer note"
		fi
	else
		evidence_score_add 15 ok "fresh reviewer note not required"
	fi

	human="$(find_report_file "$HUMAN_REPORTS_DIR" "$ticket_id" || true)"
	if [[ "$requires_human" == "true" || "$risk" =~ ^R[345]$ ]]; then
		if [[ -n "$human" ]]; then
			evidence_score_add 10 ok "human/founder report"
		else
			evidence_score_add 10 missing "human/founder report" "required for human-gated or R3+ work"
		fi
	else
		evidence_score_add 10 ok "human/founder report not required"
	fi

	lint_ok="missing"
	scope_ok="missing"
	if [[ -s "$evidence_dir/verification.log" ]]; then
		grep -Fq 'lint: ok' "$evidence_dir/verification.log" && lint_ok="ok"
		grep -Fq 'scope-check: ok' "$evidence_dir/verification.log" && scope_ok="ok"
	fi
	evidence_score_add 10 "$lint_ok" "lint pass marker in verification.log"
	evidence_score_add 10 "$scope_ok" "scope-check pass marker in verification.log"

	printf 'score: %s/100\n' "$score"
	printf 'rating: %s\n' "$(evidence_score_rating "$score")"
	printf 'next_action: '
	evidence_score_next_action "$ticket_id" "$status" "$score"

	if [[ "$strict" == "true" && "$score" != "100" ]]; then
		return 1
	fi
	return 0
}

cmd_evidence() {
	local sub="${1:-}"
	shift || true
	case "$sub" in
	score)
		cmd_evidence_score "$@"
		;;
	help | -h | --help | "")
		cat <<'USAGE'
usage: palari evidence score ID [--strict]

Read ticket reports and CI evidence, then print a conservative 0-100 evidence
readiness score. The command is read-only. Use --strict to fail unless the score
is 100.
USAGE
		;;
	*) die "unknown evidence command: $sub" ;;
	esac
}
