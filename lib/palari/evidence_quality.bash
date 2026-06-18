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

evidence_score_truthfulness_summary() {
	local manifest="$1"
	[[ -s "$manifest" ]] || return 0
	python3 - "$manifest" <<'PY' || return 0
import json
import pathlib
import sys

try:
    data = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
except Exception:
    raise SystemExit(0)

skipped_checks = data.get("skipped_checks", [])
followups = data.get("follow_up_tickets", [])
skipped_count = data.get("skipped", 0)
expected_failures = data.get("expected_failures", 0)
fixme_count = data.get("fixme_count", 0)
skipped_acceptance = data.get("skipped_acceptance_criteria", False)
if not any((skipped_count, expected_failures, fixme_count, skipped_acceptance, followups)):
    raise SystemExit(0)
print(
    "  info       truthfulness: "
    f"skipped={skipped_count} "
    f"skipped_acceptance_criteria={str(bool(skipped_acceptance)).lower()} "
    f"skipped_checks={len(skipped_checks) if isinstance(skipped_checks, list) else 'invalid'} "
    f"expected_failures={expected_failures} "
    f"fixme_count={fixme_count} "
    f"follow_up_tickets={','.join(followups) if isinstance(followups, list) and followups else 'none'}"
)
PY
}

evidence_score_next_action() {
	local file="$1"
	shift
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
		printf 'human gate: %s\n' "$(accept_command_for_ticket "$file" "$ticket_id" "HUMAN" "./bin/palari")"
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

	if manifest_detail="$(ticket_evidence_manifest_current_valid "$ticket_id" "evidence score: invalid evidence manifest" 2>&1)"; then
		evidence_score_add 20 ok "manifest integrity and freshness"
	else
		evidence_score_add 20 missing "manifest integrity and freshness" "$manifest_detail"
	fi
	evidence_score_truthfulness_summary "$evidence_dir/manifest.json"

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
	evidence_score_next_action "$file" "$ticket_id" "$status" "$score"

	if [[ "$strict" == "true" && "$score" != "100" ]]; then
		return 1
	fi
	return 0
}

evidence_refresh_require_ticket_context() {
	local file="$1"
	local ticket_id="$2"
	local branch target_branch actual_branch worktree
	branch="$(ticket_declared_branch "$file" "$ticket_id")"
	target_branch="$(frontmatter_value "$file" target_branch)"
	[[ -n "$target_branch" ]] || target_branch="$DEFAULT_BRANCH"
	git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "evidence refresh requires a git repo"
	actual_branch="$(git -C "$ROOT" branch --show-current 2>/dev/null || true)"
	if [[ "$actual_branch" != "$branch" ]]; then
		printf 'evidence refresh: wrong checkout for %s\n' "$ticket_id" >&2
		printf 'ticket branch: %s\n' "$branch" >&2
		printf 'current branch: %s\n' "${actual_branch:-detached}" >&2
		printf 'next: ./bin/palari worktree %s\n' "$ticket_id" >&2
		return 1
	fi
	worktree="$(worktree_registered_path_for_branch "$branch")"
	if [[ -n "$worktree" && "$ROOT" != "$worktree" ]]; then
		printf 'evidence refresh: wrong worktree for %s\n' "$ticket_id" >&2
		printf 'expected worktree: %s\n' "$worktree" >&2
		printf 'current worktree: %s\n' "$ROOT" >&2
		printf 'next: cd %s\n' "$worktree" >&2
		return 1
	fi
	git -C "$ROOT" rev-parse --verify "$target_branch" >/dev/null 2>&1 || die "evidence refresh: missing target branch: $target_branch"
	branch_contains_ref_at "$ROOT" "$branch" "$target_branch" ||
		die "evidence refresh: ticket branch $branch does not contain $target_branch"
}

evidence_refresh_require_clean_worktree() {
	local ticket_id="$1"
	if [[ "$(git_changed_count_at "$ROOT")" == "0" ]]; then
		return 0
	fi
	printf 'evidence refresh: refusing to rewrite evidence for %s from a dirty worktree\n' "$ticket_id" >&2
	git -C "$ROOT" status --short -- . >&2
	printf 'next: commit, stash, or remove local changes, then rerun ./bin/palari evidence refresh %s\n' "$ticket_id" >&2
	return 1
}

evidence_refresh_existing_evidence_ok() {
	local ticket_id="$1"
	local manifest="$ROOT/$EVIDENCE_DIR/$ticket_id/manifest.json"
	local detail
	[[ -e "$manifest" ]] || return 0
	if detail="$(ci_existing_evidence_valid "$ticket_id" 2>&1)"; then
		return 0
	fi
	printf 'evidence refresh: existing evidence for %s is invalid before refresh\n' "$ticket_id" >&2
	printf '%s\n' "$detail" >&2
	printf 'This is not a head_sha-only stale evidence state. Inspect or remove the invalid evidence before rerunning refresh.\n' >&2
	return 1
}

evidence_refresh_require_scope_ok() {
	local ticket_id="$1"
	local base_ref="$2"
	local scope_output
	scope_output="$(mktemp "${TMPDIR:-/tmp}/palari-evidence-refresh-scope.XXXXXX")"
	set +e
	(cmd_scope_check "$ticket_id" --base "$base_ref") >"$scope_output" 2>&1
	local code=$?
	set -e
	if ((code == 0)); then
		rm -f "$scope_output"
		return 0
	fi
	printf 'evidence refresh: refusing to rewrite evidence for %s because scope-check failed before CI\n' "$ticket_id" >&2
	cat "$scope_output" >&2
	rm -f "$scope_output"
	printf 'next: fix the branch diff or ticket allowed_paths, then rerun ./bin/palari evidence refresh %s --base %s\n' "$ticket_id" "$base_ref" >&2
	return 1
}

cmd_evidence_refresh() {
	require_base_folders
	local ticket="${1:-}"
	[[ -n "$ticket" ]] || die "evidence refresh requires ticket id"
	shift || true

	local base_ref="" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--base)
			base_ref="$2"
			shift 2
			;;
		*) die "unknown evidence refresh option: $arg" ;;
		esac
	done

	local file ticket_id status target_branch head accept_command
	file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
	ticket_id="$(frontmatter_value "$file" id)"
	[[ -n "$ticket_id" ]] || ticket_id="$ticket"
	status="$(frontmatter_value "$file" status)"
	case "$status" in
	open | claimed | reopened | in-review) ;;
	*) die "evidence refresh requires an active ticket; current status: ${status:-missing}" ;;
	esac
	target_branch="$(frontmatter_value "$file" target_branch)"
	[[ -n "$target_branch" ]] || target_branch="$DEFAULT_BRANCH"
	[[ -n "$base_ref" ]] || base_ref="$target_branch"

	evidence_refresh_require_ticket_context "$file" "$ticket_id"
	evidence_refresh_require_clean_worktree "$ticket_id"
	evidence_refresh_existing_evidence_ok "$ticket_id"
	evidence_refresh_require_scope_ok "$ticket_id" "$base_ref"

	cmd_ci "$ticket_id" --base "$base_ref"
	ticket_evidence_manifest_current_valid "$ticket_id" "evidence refresh: invalid refreshed evidence manifest"
	head="$(git -C "$ROOT" rev-parse --short HEAD)"
	accept_command="$(accept_command_for_ticket "$file" "$ticket_id" "HUMAN" "./bin/palari")"
	printf 'evidence refresh: ok for %s\n' "$ticket_id"
	printf 'head: %s\n' "$head"
	printf 'evidence: %s/%s\n' "$EVIDENCE_DIR" "$ticket_id"
	printf 'next: git add %s/%s\n' "$EVIDENCE_DIR" "$ticket_id"
	printf 'next: git commit -m "%s: refresh CI evidence"\n' "$ticket_id"
	printf 'next: ./bin/palari evidence score %s --strict\n' "$ticket_id"
	printf 'next: ./bin/palari report-lint %s\n' "$ticket_id"
	printf 'next: ./bin/palari worktree closeout %s\n' "$ticket_id"
	if [[ "$status" != "in-review" ]]; then
		printf 'next: ./bin/palari ticket ready %s\n' "$ticket_id"
	fi
	printf 'review: ./bin/palari packet %s reviewer\n' "$ticket_id"
	printf 'human acceptance remains separate: %s\n' "$accept_command"
}

cmd_evidence() {
	local sub="${1:-}"
	shift || true
	case "$sub" in
	refresh)
		cmd_evidence_refresh "$@"
		;;
	score)
		cmd_evidence_score "$@"
		;;
	help | -h | --help | "")
		cat <<'USAGE'
usage: palari evidence score ID [--strict]
       palari evidence refresh ID [--base REF]

Read ticket reports and CI evidence, then print a conservative 0-100 evidence
readiness score. The command is read-only. Use --strict to fail unless the score
is 100.

Refresh writes CI evidence for an active ticket from its clean ticket worktree.
It does not accept, merge, push, deploy, or move ticket status.
USAGE
		;;
	*) die "unknown evidence command: $sub" ;;
	esac
}
