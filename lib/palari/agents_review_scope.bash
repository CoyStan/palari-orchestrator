opencode_config_content() {
	cat <<'JSON'
{"$schema":"https://opencode.ai/config.json","permission":{"*":"allow","question":"deny","plan_enter":"deny","plan_exit":"deny","webfetch":"deny","websearch":"deny","external_directory":"deny","bash":{"*":"allow","palari *":"deny","./bin/palari *":"deny","bin/palari *":"deny","git commit*":"deny","git push*":"deny","rm *":"deny"}}}
JSON
}

agent_run_gate() {
	local worktree="$1"
	local label="$2"
	local out_dir="$3"
	shift 3
	local code
	set +e
	(cd "$worktree" && "$@" >"$out_dir/$label.out" 2>"$out_dir/$label.err")
	code=$?
	set -e
	printf '%s\n' "$code" >"$out_dir/$label.exit"
	return "$code"
}

cmd_agent_run() {
	require_base_folders
	local ticket="${1:-}"
	shift || true
	[[ -n "$ticket" ]] || die "agent run requires ticket ID"
	local executor="" model="" prompt="" dry_run="false" no_gates="false" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--executor)
			executor="$2"
			shift 2
			;;
		--model)
			model="$2"
			shift 2
			;;
		--prompt)
			prompt="$2"
			shift 2
			;;
		--dry-run)
			dry_run="true"
			shift
			;;
		--no-gates)
			no_gates="true"
			shift
			;;
		*) die "unknown agent run option: $arg" ;;
		esac
	done
	[[ "$executor" == "opencode" ]] || die "agent run currently supports only --executor opencode"
	[[ -n "$prompt" ]] || prompt="Execute this Palari ticket from the attached packet. Stay inside allowed paths. Do not run any palari lifecycle command, git commit, git push, or palari accept."

	local file ticket_id worktree packet_tmp packet_path evidence_dir stdout stderr session session_export export_stderr command_file opencode_code=0 scope_code=0 ci_code=0
	file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
	ticket_id="$(frontmatter_value "$file" id)"
	[[ -n "$ticket_id" ]] || ticket_id="$ticket"
	worktree="$(ticket_declared_worktree "$file" "$ticket_id")"

	cmd_worktree "$ticket_id"
	packet_tmp="$(mktemp)"
	cmd_packet "$ticket_id" specialist >"$packet_tmp"
	mkdir -p "$worktree/$REPORTS_DIR" "$worktree/$EVIDENCE_DIR/$ticket_id/executor/opencode"
	packet_path="$worktree/$REPORTS_DIR/$ticket_id-opencode-packet.md"
	cp "$packet_tmp" "$packet_path"
	rm -f "$packet_tmp"

	evidence_dir="$worktree/$EVIDENCE_DIR/$ticket_id/executor/opencode"
	stdout="$evidence_dir/run.jsonl"
	stderr="$evidence_dir/run.stderr"
	session_export="$evidence_dir/session-export.json"
	export_stderr="$evidence_dir/session-export.stderr"
	command_file="$evidence_dir/command.txt"
	{
		printf 'executor: opencode\n'
		printf 'ticket: %s\n' "$ticket_id"
		printf 'worktree: %s\n' "$worktree"
		printf 'packet: %s\n' "$packet_path"
		printf 'model: %s\n' "${model:-opencode default}"
		printf 'command: opencode run --dir %s --file %s --format json --title palari-%s%s %s\n' \
			"$(shell_quote "$worktree")" \
			"$(shell_quote "$packet_path")" \
			"$ticket_id" \
			"$([[ -n "$model" ]] && printf ' --model %s' "$(shell_quote "$model")")" \
			"$(shell_quote "$prompt")"
		printf 'denied: palari *, ./bin/palari *, bin/palari *, git commit*, git push*, rm *\n'
	} >"$command_file"

	if [[ "$dry_run" == "true" ]]; then
		printf 'agent run: dry-run for %s\n' "$ticket_id"
		printf 'executor: opencode\n'
		printf 'worktree: %s\n' "$worktree"
		printf 'packet: %s\n' "$packet_path"
		printf 'evidence: %s\n' "${evidence_dir#"$worktree"/}"
		cat "$command_file"
		return 0
	fi

	command -v opencode >/dev/null 2>&1 || die "agent run --executor opencode requires opencode on PATH"
	set +e
	if [[ -n "$model" ]]; then
		OPENCODE_CONFIG_CONTENT="$(opencode_config_content)" \
		OPENCODE_DISABLE_AUTOUPDATE=1 \
		OPENCODE_DISABLE_PRUNE=1 \
			opencode run --model "$model" --dir "$worktree" --file "$packet_path" --format json --title "palari-$ticket_id" "$prompt" >"$stdout" 2>"$stderr"
	else
		OPENCODE_CONFIG_CONTENT="$(opencode_config_content)" \
		OPENCODE_DISABLE_AUTOUPDATE=1 \
		OPENCODE_DISABLE_PRUNE=1 \
			opencode run --dir "$worktree" --file "$packet_path" --format json --title "palari-$ticket_id" "$prompt" >"$stdout" 2>"$stderr"
	fi
	opencode_code=$?
	set -e
	printf '%s\n' "$opencode_code" >"$evidence_dir/run.exit"

	session="$(sed -n 's/.*"sessionID":"\([^"]*\)".*/\1/p' "$stdout" | tail -n 1)"
	printf '%s\n' "$session" >"$evidence_dir/session.id"
	if [[ -n "$session" ]]; then
		set +e
		opencode export "$session" >"$session_export" 2>"$export_stderr"
		printf '%s\n' "$?" >"$evidence_dir/session-export.exit"
		set -e
	else
		printf '{}\n' >"$session_export"
		printf 'no session id found in opencode JSON stream\n' >"$export_stderr"
		printf '1\n' >"$evidence_dir/session-export.exit"
	fi

	if [[ "$no_gates" != "true" ]]; then
		agent_run_gate "$worktree" scope-check "$evidence_dir" ./bin/palari scope-check "$ticket_id" || scope_code=$?
		agent_run_gate "$worktree" ci "$evidence_dir" ./bin/palari ci "$ticket_id" || ci_code=$?
	fi

	printf 'agent run: %s via opencode\n' "$ticket_id"
	printf 'opencode exit: %s\n' "$opencode_code"
	printf 'scope-check exit: %s\n' "$scope_code"
	printf 'ci exit: %s\n' "$ci_code"
	printf 'evidence: %s\n' "${evidence_dir#"$worktree"/}"
	((opencode_code == 0 && scope_code == 0 && ci_code == 0))
}

cmd_agent() {
	local sub="${1:-}"
	shift || true
	case "$sub" in
	run) cmd_agent_run "$@" ;;
	*) die "unknown agent command: ${sub:-}; try \`palari agent run TICKET-ID --executor opencode\`" ;;
	esac
}

print_ticket_section_excerpt() {
	local file="$1"
	local heading="$2"
	local limit="${3:-5}"
	awk -v heading="$heading" -v limit="$limit" '
    $0 ~ "^##[[:space:]]+" heading "[[:space:]]*$" { in_section = 1; next }
    in_section && /^##[[:space:]]+/ { exit }
    in_section && NF {
      print "  " $0
      count += 1
      if (count >= limit) exit
    }
  ' "$file"
}

cmd_packet() {
	require_base_folders
	local ticket="${1:-}"
	local role="${2:-}"
	[[ -n "$ticket" && -n "$role" ]] || die "packet requires ticket ID and role"
	case "$role" in
	specialist | reviewer | acceptor | human) ;;
	*[!a-z0-9-]* | "") die "role must be specialist, reviewer, acceptor, human, or a lowercase custom review profile" ;;
	esac

	local file rel ticket_id title status risk priority requires_review requires_human required_reports
	local branch worktree target_branch worktree_head worktree_branch worktree_changed
	file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
	rel="${file#"$ROOT"/}"
	ticket_id="$(frontmatter_value "$file" id)"
	title="$(frontmatter_value "$file" title)"
	status="$(frontmatter_value "$file" status)"
	risk="$(frontmatter_value "$file" risk)"
	priority="$(frontmatter_value "$file" priority)"
	requires_review="$(frontmatter_value "$file" requires_review)"
	requires_human="$(frontmatter_value "$file" requires_human_confirmation)"
	required_reports="$(ticket_required_reports "$file" | paste -sd ', ' -)"
	[[ -n "$ticket_id" ]] || ticket_id="$ticket"
	branch="$(ticket_declared_branch "$file" "$ticket_id")"
	worktree="$(ticket_declared_worktree "$file" "$ticket_id")"
	target_branch="$(frontmatter_value "$file" target_branch)"
	[[ -n "$target_branch" ]] || target_branch="$DEFAULT_BRANCH"

	require_ticket_worktree_ready "$ticket_id" "$branch" "$worktree" "packet" "$target_branch"

	worktree_head="missing"
	worktree_branch="missing"
	worktree_changed="missing"
	if git -C "$worktree" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		worktree_head="$(git -C "$worktree" rev-parse --short HEAD)"
		worktree_branch="$(git -C "$worktree" branch --show-current)"
		worktree_changed="$(git_changed_count_at "$worktree") changed path(s)"
	fi

	printf 'Palari Orchestration mission packet\n'
	printf 'Role: %s\n' "$role"
	printf 'Ticket: %s - %s\n' "$ticket_id" "${title:-}"
	printf 'Ticket path: %s\n' "$rel"
	printf 'Status: %s\n' "${status:-missing}"
	printf 'Risk: %s\n' "${risk:-missing}"
	printf 'Priority: %s\n' "${priority:-missing}"
	printf 'Requires review: %s\n' "${requires_review:-missing}"
	printf 'Requires human confirmation: %s\n' "${requires_human:-missing}"
	printf 'Required reports: %s\n\n' "${required_reports:-none}"

	printf 'Worker rule:\n'
	printf '  Read this packet, the ticket, relevant source/tests/diffs/reports, and concrete evidence needed for the task.\n'
	printf '  Do not self-orient through broad process docs unless this packet names a trigger.\n\n'

	printf 'Git context:\n'
	printf '  Canonical repo: %s\n' "$ROOT"
	printf '  Target branch: %s\n' "$target_branch"
	printf '  Ticket branch: %s\n' "$branch"
	printf '  Ticket worktree: %s\n' "$worktree"
	printf '  Worktree branch: %s\n' "$worktree_branch"
	printf '  Worktree HEAD: %s\n' "$worktree_head"
	printf '  Worktree changed paths: %s\n' "$worktree_changed"
	printf '  Worker cd: cd %s\n\n' "$worktree"

	printf 'Mission:\n'
	print_ticket_section_excerpt "$file" "Goal" 5
	printf '\nAuthority:\n'
	case "$role" in
	specialist)
		printf '  Implement only inside ticket and packet scope. Move ready work to in-review; do not accept your own work.\n'
		;;
	reviewer)
		printf '  Fresh-context review mode. Inspect correctness, scope, verification, and completion contract. Do not implement fixes by default.\n'
		;;
	acceptor | human)
		printf '  Acceptance gate mode. Verify evidence, review state, scope, and authority before accepting. Do not accept missing gates.\n'
		;;
	*)
		# shellcheck disable=SC2016 # Backticks are literal Markdown in packet output.
		printf '  Custom review profile mode. Inspect the ticket through the `%s` lens and produce the matching required report if applicable.\n' "$role"
		;;
	esac
	printf '\n'
	print_frontmatter_list_block 'Allowed paths' "$file" allowed_paths
	print_frontmatter_list_block 'Forbidden paths' "$file" forbidden_paths
	print_frontmatter_list_block 'Verification' "$file" verification
	printf '\nStop conditions:\n'
	printf '  - needed edit is outside allowed paths\n'
	printf '  - forbidden path would be touched\n'
	printf '  - real risk exceeds ticket risk\n'
	printf '  - secrets, production, live external services, deploys, Docker, database mutation, or destructive commands become necessary without explicit scope\n'
	printf '  - acceptance criteria, product direction, or authority are unclear\n'
	printf '  - actor would need to accept its own substantive work\n\n'
	print_packet_memory "$ticket_id" "$role"
	printf 'Closeout:\n'
	printf '  - result state\n  - changed paths\n  - verification passed/failed/not run\n  - blockers or scope conflicts\n  - risks/follow-ups\n  - next action for orchestrator/human\n'
}

print_packet_memory() {
	local ticket_id="$1"
	local role="$2"
	if command -v python3 >/dev/null 2>&1 && [[ -f "$ROOT/adapters/memory/memory.py" ]]; then
		if python3 -B "$ROOT/adapters/memory/memory.py" --root "$ROOT" context "$ticket_id" --role "$role" --write-lock; then
			printf '\n'
			return 0
		fi
	fi
	printf 'Relevant Memory:\n'
	printf '  - none selected\n\n'
}

lint_one_ticket() {
	local file="$1"
	local errors=0 field value
	if ! has_frontmatter "$file"; then
		printf 'lint: %s: missing YAML frontmatter\n' "${file#"$ROOT"/}" >&2
		return 1
	fi
	for field in "${REQUIRED_FIELDS[@]}"; do
		if ! frontmatter_has_key "$file" "$field"; then
			printf 'lint: %s: missing required field: %s\n' "${file#"$ROOT"/}" "$field" >&2
			errors=$((errors + 1))
		fi
	done
	value="$(frontmatter_value "$file" id)"
	if [[ -n "$value" ]] && ! valid_ticket_id "$value"; then
		printf 'lint: %s: invalid id: %s\n' "${file#"$ROOT"/}" "$value" >&2
		errors=$((errors + 1))
	fi
	value="$(frontmatter_value "$file" status)"
	if [[ -n "$value" ]] && ! in_words "$value" "$VALID_STATUSES"; then
		printf 'lint: %s: invalid status: %s\n' "${file#"$ROOT"/}" "$value" >&2
		errors=$((errors + 1))
	fi
	value="$(frontmatter_value "$file" risk)"
	if [[ -n "$value" ]] && ! in_words "$value" "$VALID_RISKS"; then
		printf 'lint: %s: invalid risk: %s\n' "${file#"$ROOT"/}" "$value" >&2
		errors=$((errors + 1))
	fi
	value="$(frontmatter_value "$file" priority)"
	if [[ -n "$value" ]] && ! in_words "$value" "$VALID_PRIORITIES"; then
		printf 'lint: %s: invalid priority: %s\n' "${file#"$ROOT"/}" "$value" >&2
		errors=$((errors + 1))
	fi
	value="$(frontmatter_value "$file" requires_human_confirmation)"
	[[ -z "$value" || "$value" == "true" || "$value" == "false" ]] || {
		printf 'lint: %s: requires_human_confirmation must be true or false\n' "${file#"$ROOT"/}" >&2
		errors=$((errors + 1))
	}
	value="$(frontmatter_value "$file" requires_review)"
	[[ -z "$value" || "$value" == "true" || "$value" == "false" ]] || {
		printf 'lint: %s: requires_review must be true or false\n' "${file#"$ROOT"/}" >&2
		errors=$((errors + 1))
	}
	if [[ "$(frontmatter_list_count "$file" allowed_paths)" == "0" ]]; then
		printf 'lint: %s: allowed_paths must contain at least one item\n' "${file#"$ROOT"/}" >&2
		errors=$((errors + 1))
	fi
	if [[ "$(frontmatter_list_count "$file" forbidden_paths)" == "0" ]]; then
		printf 'lint: %s: forbidden_paths must contain at least one item\n' "${file#"$ROOT"/}" >&2
		errors=$((errors + 1))
	fi
	if [[ "$(frontmatter_list_count "$file" verification)" == "0" ]]; then
		printf 'lint: %s: verification must contain at least one item\n' "${file#"$ROOT"/}" >&2
		errors=$((errors + 1))
	fi
	return "$errors"
}

validate_headings() {
	local label="$1"
	local file="$2"
	shift 2
	local errors=0 heading
	for heading in "$@"; do
		if ! grep -Eq "^##[[:space:]]+${heading}[[:space:]]*$" "$file"; then
			printf 'report-lint: %s: missing heading: ## %s\n' "${file#"$ROOT"/}" "$heading" >&2
			errors=$((errors + 1))
		fi
	done
	return "$errors"
}

cmd_report_lint() {
	require_base_folders
	local ticket="${1:-}"
	local errors=0 file ticket_id risk status requires_review requires_human technical human reviewer handoff required_report custom_report
	local -a files=()
	if [[ -n "$ticket" ]]; then
		file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
		files+=("$file")
	else
		while IFS= read -r file; do [[ -n "$file" ]] && files+=("$file"); done < <(all_ticket_files)
	fi

	for file in "${files[@]}"; do
		ticket_id="$(frontmatter_value "$file" id)"
		[[ -n "$ticket_id" ]] || ticket_id="$(ticket_title_from_file "$file")"
		risk="$(frontmatter_value "$file" risk)"
		status="$(frontmatter_value "$file" status)"
		requires_review="$(frontmatter_value "$file" requires_review)"
		requires_human="$(frontmatter_value "$file" requires_human_confirmation)"
		technical="$(find_report_file "$REPORTS_DIR" "$ticket_id" '(^# .*Technical Report$|^## Files Changed$|^## Verification$|^## Risks / Follow-Ups$)' || true)"
		reviewer="$(find_report_file "$REPORTS_DIR" "$ticket_id" '(^# .*Reviewer Note$|^## Review Result$|^## Required Changes$)' || true)"
		human="$(find_report_file "$HUMAN_REPORTS_DIR" "$ticket_id" || true)"
		handoff="$(find_report_file "$HANDOFFS_DIR" "$ticket_id" || true)"

		if [[ "$status" == "in-review" || "$status" == "accepted" ]]; then
			if [[ "$risk" =~ ^R[234]$ && -z "$technical" ]]; then
				printf 'report-lint: %s: missing technical/specialist report for %s work\n' "$ticket_id" "$risk" >&2
				errors=$((errors + 1))
			fi
			if [[ ("$requires_review" == "true" || "$risk" =~ ^R[234]$) && -z "$reviewer" ]]; then
				printf 'report-lint: %s: missing fresh-context reviewer note\n' "$ticket_id" >&2
				errors=$((errors + 1))
			fi
			if [[ ("$requires_human" == "true" || "$risk" =~ ^R[34]$) && -z "$human" ]]; then
				printf 'report-lint: %s: missing human/founder report for required human gate\n' "$ticket_id" >&2
				errors=$((errors + 1))
			fi
			while IFS= read -r required_report; do
				[[ -n "$required_report" ]] || continue
				case "$required_report" in
				specialist | technical)
					if [[ -z "$technical" ]]; then
						printf 'report-lint: %s: missing required report: %s\n' "$ticket_id" "$required_report" >&2
						errors=$((errors + 1))
					fi
					;;
				reviewer)
					if [[ -z "$reviewer" ]]; then
						printf 'report-lint: %s: missing required report: reviewer\n' "$ticket_id" >&2
						errors=$((errors + 1))
					fi
					;;
				human | founder)
					if [[ -z "$human" ]]; then
						printf 'report-lint: %s: missing required report: %s\n' "$ticket_id" "$required_report" >&2
						errors=$((errors + 1))
					fi
					;;
				*)
					custom_report="$(find_named_report_file "$ticket_id" "$required_report" || true)"
					if [[ -z "$custom_report" ]]; then
						printf 'report-lint: %s: missing required report: %s\n' "$ticket_id" "$required_report" >&2
						errors=$((errors + 1))
					fi
					;;
				esac
			done < <(ticket_required_reports "$file" | awk '!seen[$0]++')
		fi
		if [[ "$status" == "blocked" || "$status" == "needs-human" ]] && [[ -z "$handoff" ]]; then
			printf 'report-lint: %s: %s ticket should have a handoff note\n' "$ticket_id" "$status" >&2
			errors=$((errors + 1))
		fi
		[[ -z "$technical" ]] || validate_headings technical "$technical" "Files Changed" "Verification" "CI Evidence" "Risks / Follow-Ups" || errors=$((errors + 1))
		[[ -z "$reviewer" ]] || validate_headings reviewer "$reviewer" "Review Result" "Findings" "Verification Reviewed" "Required Changes" "Recommendation" || errors=$((errors + 1))
		[[ -z "$human" ]] || validate_headings human "$human" "Why This Mattered" "What Changed" "What I Should Know" "What To Check" "Recommended Next Move" || errors=$((errors + 1))
	done
	((errors == 0)) || {
		printf 'report-lint: failed with %s issue(s)\n' "$errors" >&2
		exit 1
	}
	[[ -n "$ticket" ]] && printf 'report-lint: ok for %s\n' "$ticket" || printf 'report-lint: ok\n'
}

cmd_lint() {
	require_base_folders
	local ticket="${1:-}"
	local errors=0 file
	if [[ -n "$ticket" ]]; then
		file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
		lint_one_ticket "$file" || errors=$((errors + 1))
	else
		while IFS= read -r file; do
			[[ -n "$file" ]] || continue
			lint_one_ticket "$file" || errors=$((errors + 1))
		done < <(all_ticket_files)
	fi
	((errors == 0)) || {
		printf 'lint: failed with %s issue(s)\n' "$errors" >&2
		exit 1
	}
	if [[ -z "$ticket" ]]; then
		cmd_propose_lint
	fi
	cmd_report_lint "$ticket"
	[[ -n "$ticket" ]] && printf 'lint: ok for %s\n' "$ticket" || printf 'lint: ok\n'
}

select_scope_ticket() {
	local ticket="${1:-}"
	local file selected="" count=0
	if [[ -n "$ticket" ]]; then
		find_ticket_file "$ticket"
		return
	fi
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		if [[ "$(frontmatter_value "$file" status)" == "claimed" ]]; then
			selected="$file"
			count=$((count + 1))
		fi
	done < <(ticket_files)
	((count == 1)) || die "scope-check requires an explicit ticket ID unless exactly one ticket is claimed"
	printf '%s\n' "$selected"
}

cmd_scope_check() {
	require_base_folders
	local ticket="" base_ref="" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--base)
			base_ref="$2"
			shift 2
			;;
		--*) die "unknown scope-check option: $arg" ;;
		*)
			ticket="$arg"
			shift
			;;
		esac
	done
	local file ticket_id path pattern changed_count=0 errors=0
	local -a allowed=()
	local -a forbidden=()
	file="$(select_scope_ticket "$ticket")" || exit $?
	ticket_id="$(frontmatter_value "$file" id)"
	[[ -n "$ticket_id" ]] || ticket_id="$(ticket_title_from_file "$file")"
	while IFS= read -r pattern; do [[ -n "$pattern" ]] && allowed+=("$pattern"); done < <(frontmatter_list_items "$file" allowed_paths)
	while IFS= read -r pattern; do [[ -n "$pattern" ]] && forbidden+=("$pattern"); done < <(frontmatter_list_items "$file" forbidden_paths)
	((${#allowed[@]} > 0)) || die "ticket $ticket_id has no allowed_paths"
	((${#forbidden[@]} > 0)) || die "ticket $ticket_id has no forbidden_paths"

	while IFS= read -r path; do
		[[ -n "$path" ]] || continue
		changed_count=$((changed_count + 1))
		pattern="$(check_path_against_patterns "$path" "${forbidden[@]}" || true)"
		if [[ -n "$pattern" ]]; then
			printf 'scope-check: %s forbidden by ticket %s (rule: %s)\n' "$path" "$ticket_id" "$pattern" >&2
			errors=$((errors + 1))
			continue
		fi
		pattern="$(check_path_against_patterns "$path" "${allowed[@]}" || true)"
		if [[ -z "$pattern" ]]; then
			printf 'scope-check: %s outside allowed_paths for ticket %s\n' "$path" "$ticket_id" >&2
			printf 'scope-check: allowed rules: %s\n' "${allowed[*]}" >&2
			errors=$((errors + 1))
		fi
	done < <(git_changed_paths "$base_ref")
	((errors == 0)) || {
		printf 'scope-check: failed for %s with %s issue(s)\n' "$ticket_id" "$errors" >&2
		exit 1
	}
	printf 'scope-check: ok for %s (%s changed path(s))\n' "$ticket_id" "$changed_count"
}

cmd_scope_overlaps() {
	require_base_folders
	local ticket="${1:-}"
	local file errors=0
	if [[ -n "$ticket" ]]; then
		file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
		if scope_overlap_errors "$file"; then
			printf 'scope-overlaps: ok for %s\n' "$(frontmatter_value "$file" id)"
		else
			exit 1
		fi
	else
		while IFS= read -r file; do
			[[ -n "$file" ]] || continue
			if ! scope_overlap_errors "$file"; then
				errors=$((errors + 1))
			fi
		done < <(ticket_files)
		((errors == 0)) || exit 1
		printf 'scope-overlaps: ok\n'
	fi
}

scope_check_ticket_set() {
	local base_ref="$1"
	shift
	local ticket_ids=("$@")
	local file ticket_id path pattern changed_count=0 errors=0 label
	local -a allowed=()
	local -a forbidden=()
	((${#ticket_ids[@]} > 0)) || die "multi-ticket scope-check requires at least one ticket"
	for ticket_id in "${ticket_ids[@]}"; do
		file="$(find_ticket_file "$ticket_id")" || die "ticket not found: $ticket_id"
		while IFS= read -r pattern; do [[ -n "$pattern" ]] && allowed+=("$pattern"); done < <(frontmatter_list_items "$file" allowed_paths)
		while IFS= read -r pattern; do [[ -n "$pattern" ]] && forbidden+=("$pattern"); done < <(frontmatter_list_items "$file" forbidden_paths)
	done
	((${#allowed[@]} > 0)) || die "multi-ticket scope has no allowed_paths"
	((${#forbidden[@]} > 0)) || die "multi-ticket scope has no forbidden_paths"
	label="$(
		IFS=,
		printf '%s' "${ticket_ids[*]}"
	)"
	while IFS= read -r path; do
		[[ -n "$path" ]] || continue
		changed_count=$((changed_count + 1))
		pattern="$(check_path_against_patterns "$path" "${forbidden[@]}" || true)"
		if [[ -n "$pattern" ]]; then
			printf 'scope-check: %s forbidden by ticket set %s (rule: %s)\n' "$path" "$label" "$pattern" >&2
			errors=$((errors + 1))
			continue
		fi
		pattern="$(check_path_against_patterns "$path" "${allowed[@]}" || true)"
		if [[ -z "$pattern" ]]; then
			printf 'scope-check: %s outside union allowed_paths for ticket set %s\n' "$path" "$label" >&2
			printf 'scope-check: allowed rules: %s\n' "${allowed[*]}" >&2
			errors=$((errors + 1))
		fi
	done < <(git_changed_paths "$base_ref")
	((errors == 0)) || {
		printf 'scope-check: failed for ticket set %s with %s issue(s)\n' "$label" "$errors" >&2
		return 1
	}
	printf 'scope-check: ok for ticket set %s (%s changed path(s))\n' "$label" "$changed_count"
}
