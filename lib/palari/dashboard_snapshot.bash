# shellcheck shell=bash
# shellcheck disable=SC2153 # This module is sourced after core and role/lifecycle modules.
snapshot_next_action_values() {
	local file="$1"
	local state="$2"
	local prefix="$3"
	local mode="${4:-full}"
	local id status target accepted_by accepted_at label detail command actor severity
	local evidence_ready="false" reports_ready="false"
	id="$(frontmatter_value "$file" id)"
	[[ -n "$id" ]] || id="$(ticket_title_from_file "$file")"
	status="$(frontmatter_value "$file" status)"
	[[ -n "$status" ]] || status="$([[ "$state" == "accepted" ]] && printf accepted || printf open)"
	target="$(frontmatter_value "$file" target_branch)"
	[[ -n "$target" ]] || target="$DEFAULT_BRANCH"
	case "$status" in
	accepted)
		accepted_by="$(frontmatter_value "$file" accepted_by)"
		accepted_at="$(frontmatter_value "$file" accepted_at)"
		label="Accepted"
		detail="Closed on the repository source of truth."
		if [[ -n "$accepted_by" || -n "$accepted_at" ]]; then
			detail="Accepted by ${accepted_by:-unknown}${accepted_at:+ at $accepted_at}."
		fi
		command=""
		actor="none"
		severity="clear"
		;;
	open)
		label="Claim and isolate"
		detail="Assign an owner and create the ticket worktree before implementation starts."
		command="./bin/palari ticket claim $id YOUR-NAME && ./bin/palari worktree $id"
		actor="orchestrator"
		severity="next"
		;;
	claimed)
		if [[ "$(ticket_lease_status "$file")" == "expired" ]]; then
			label="Renew or release claim"
			detail="The current claim lease is expired, so ownership is unclear."
			command="./bin/palari ticket heartbeat $id"
			actor="owner"
			severity="watch"
		else
			ticket_evidence_present_quiet "$id" && evidence_ready="true"
			snapshot_ticket_reports_ready_quiet "$mode" "$id" "$file" && reports_ready="true"
			if [[ "$evidence_ready" == "true" && "$reports_ready" == "true" ]]; then
				label="Move to review"
				detail="Evidence and required reports are present; hand the ticket to a fresh reviewer."
				command="./bin/palari ticket ready $id"
				actor="specialist"
				severity="next"
			else
				label="Finish evidence"
				detail="Complete scoped work, specialist reporting, and CI evidence before review."
				command="./bin/palari worktree $id && ./bin/palari packet $id specialist && ./bin/palari ci $id --base $target"
				actor="specialist"
				severity="next"
			fi
		fi
		;;
	in-review)
		if ! ticket_evidence_present_quiet "$id"; then
			label="Create evidence"
			detail="Review cannot complete until the standard evidence bundle exists."
			command="./bin/palari ci $id --base $target"
			actor="specialist"
			severity="blocked"
		elif ! snapshot_ticket_reports_ready_quiet "$mode" "$id" "$file"; then
			label="Complete review reports"
			detail="A reviewer or required custom/human report is missing."
			command="./bin/palari packet $id reviewer"
			actor="reviewer"
			severity="blocked"
		else
			label="Accept or reopen"
			detail="A human or authorized acceptor should accept the ticket or send it back."
			command="./bin/palari accept $id --by founder"
			actor="human"
			severity="waiting"
		fi
		;;
	blocked)
		label="Resolve blocker"
		detail="Inspect the ticket and write a handoff note so the block is visible."
		command="./bin/palari packet $id human"
		actor="orchestrator"
		severity="blocked"
		;;
	needs-human)
		label="Human decision required"
		detail="A person needs to resolve product direction, authority, or acceptance criteria."
		command="./bin/palari packet $id human"
		actor="human"
		severity="blocked"
		;;
	reopened)
		label="Continue revised work"
		detail="Claim the ticket again and continue from the updated reviewer guidance."
		command="./bin/palari ticket claim $id YOUR-NAME && ./bin/palari packet $id specialist"
		actor="specialist"
		severity="next"
		;;
	*)
		label="Inspect ticket state"
		detail="This ticket has an unexpected status."
		command="./bin/palari lint $id"
		actor="orchestrator"
		severity="watch"
		;;
	esac
	printf -v "${prefix}_label" '%s' "$label"
	printf -v "${prefix}_detail" '%s' "$detail"
	printf -v "${prefix}_command" '%s' "$command"
	printf -v "${prefix}_actor" '%s' "$actor"
	printf -v "${prefix}_severity" '%s' "$severity"
}

snapshot_ticket_reports_ready_quiet() {
	local mode="$1"
	local ticket_id="$2"
	local file="$3"
	local risk status requires_review requires_human technical reviewer human required_report custom_report
	technical="false"
	reviewer="false"
	human="false"
	if [[ "$mode" == "full" ]]; then
		ticket_report_lint_quiet "$ticket_id"
		return $?
	fi
	risk="$(frontmatter_value "$file" risk)"
	status="$(frontmatter_value "$file" status)"
	requires_review="$(frontmatter_value "$file" requires_review)"
	requires_human="$(frontmatter_value "$file" requires_human_confirmation)"
	snapshot_fast_report_present "$REPORTS_DIR" "$ticket_id" technical && technical="true"
	snapshot_fast_report_present "$REPORTS_DIR" "$ticket_id" reviewer && reviewer="true"
	snapshot_fast_report_present "$HUMAN_REPORTS_DIR" "$ticket_id" human && human="true"
	if [[ "$status" == "in-review" || "$status" == "accepted" ]]; then
		[[ ! "$risk" =~ ^R[234]$ || "$technical" == "true" ]] || return 1
		[[ !( "$requires_review" == "true" || "$risk" =~ ^R[234]$ ) || "$reviewer" == "true" ]] || return 1
		[[ !( "$requires_human" == "true" || "$risk" =~ ^R[34]$ ) || "$human" == "true" ]] || return 1
	fi
	while IFS= read -r required_report; do
		[[ -n "$required_report" ]] || continue
		case "$required_report" in
		specialist | technical)
			[[ "$technical" == "true" ]] || return 1
			;;
		reviewer)
			[[ "$reviewer" == "true" ]] || return 1
			;;
		human | founder)
			[[ "$human" == "true" ]] || return 1
			;;
		*)
			custom_report="false"
			snapshot_fast_report_present "$REPORTS_DIR" "$ticket_id" "$required_report" && custom_report="true"
			[[ "$custom_report" == "true" ]] || return 1
			;;
		esac
	done < <(ticket_required_reports "$file" | awk '!seen[$0]++')
	return 0
}

snapshot_next_action_json() {
	local file="$1"
	local state="$2"
	local mode="${3:-full}"
	local action_label action_detail action_command action_actor action_severity
	snapshot_next_action_values "$file" "$state" action "$mode"
	printf '{"label":'
	json_string "$action_label"
	printf ',"detail":'
	json_string "$action_detail"
	printf ',"command":'
	json_string "$action_command"
	printf ',"actor":'
	json_string "$action_actor"
	printf ',"severity":'
	json_string "$action_severity"
	printf '}'
}

evidence_summary_json() {
	local ticket_id="$1"
	local dir="$ROOT/$EVIDENCE_DIR/$ticket_id"
	local rel="" first="true" count=0 name has_log="false" has_junit="false" has_sarif="false" has_manifest="false"
	[[ -d "$dir" ]] && rel="${dir#"$ROOT"/}"
	[[ -f "$dir/verification.log" ]] && has_log="true"
	[[ -f "$dir/junit.xml" ]] && has_junit="true"
	[[ -f "$dir/palari.sarif" ]] && has_sarif="true"
	[[ -f "$dir/manifest.json" ]] && has_manifest="true"
	printf '{"path":'
	json_string "$rel"
	printf ',"files":['
	for name in verification.log junit.xml palari.sarif manifest.json; do
		[[ -f "$dir/$name" ]] || continue
		[[ "$first" == "true" ]] || printf ','
		json_string "$name"
		first="false"
		count=$((count + 1))
	done
	printf '],"has_log":%s,"has_junit":%s,"has_sarif":%s,"has_manifest":%s,"file_count":%s}' \
		"$has_log" "$has_junit" "$has_sarif" "$has_manifest" "$count"
}

snapshot_fast_report_present() {
	local dir="$1"
	local ticket_id="$2"
	local kind="$3"
	local slug="${kind,,}"
	slug="${slug//_/-}"
	case "$kind" in
	technical | specialist)
		compgen -G "$ROOT/$dir/${ticket_id}-technical-report.md" >/dev/null && return 0
		compgen -G "$ROOT/$dir/${ticket_id}-specialist-report.md" >/dev/null && return 0
		compgen -G "$ROOT/$dir/${ticket_id}"'*technical*.md' >/dev/null && return 0
		compgen -G "$ROOT/$dir/${ticket_id}"'*specialist*.md' >/dev/null && return 0
		;;
	reviewer)
		compgen -G "$ROOT/$dir/${ticket_id}-reviewer-note.md" >/dev/null && return 0
		compgen -G "$ROOT/$dir/${ticket_id}"'*review*.md' >/dev/null && return 0
		;;
	human | founder)
		compgen -G "$ROOT/$dir/${ticket_id}"'*.md' >/dev/null && return 0
		compgen -G "$ROOT/$dir/${ticket_id}"'*.markdown' >/dev/null && return 0
		;;
	*)
		compgen -G "$ROOT/$dir/${ticket_id}"*"${slug}"'*.md' >/dev/null && return 0
		compgen -G "$ROOT/$dir/${ticket_id}"*"${slug}"'*.markdown' >/dev/null && return 0
		;;
	esac
	return 1
}

reports_summary_json() {
	local ticket_id="$1"
	local file="$2"
	local required_report first="true"
	local technical="false" reviewer="false" human="false" custom_present
	snapshot_fast_report_present "$REPORTS_DIR" "$ticket_id" technical && technical="true"
	snapshot_fast_report_present "$REPORTS_DIR" "$ticket_id" reviewer && reviewer="true"
	snapshot_fast_report_present "$HUMAN_REPORTS_DIR" "$ticket_id" human && human="true"
	printf '{"technical":%s,"reviewer":%s,"human":%s,"custom":[' "$technical" "$reviewer" "$human"
	while IFS= read -r required_report; do
		[[ -n "$required_report" ]] || continue
		case "$required_report" in
		specialist | technical | reviewer | human | founder) continue ;;
		esac
		custom_present="false"
		snapshot_fast_report_present "$REPORTS_DIR" "$ticket_id" "$required_report" && custom_present="true"
		[[ "$first" == "true" ]] || printf ','
		printf '{"name":'
		json_string "$required_report"
		printf ',"present":%s}' "$custom_present"
		first="false"
	done < <(ticket_required_reports "$file" | awk '!seen[$0]++')
	printf ']}'
}

snapshot_ticket_fast_json() {
	local file="$1"
	local state="$2"
	local ticket_id title status risk priority stream rel claimed_by claimed_at claim_ref expires heartbeat branch worktree lease_status
	local created_by_role delegated_to_role accepted_by accepted_at implemented_by
	ticket_id="$(frontmatter_value "$file" id)"
	[[ -n "$ticket_id" ]] || ticket_id="$(ticket_title_from_file "$file")"
	title="$(frontmatter_value "$file" title)"
	[[ -n "$title" ]] || title="$ticket_id"
	status="$(frontmatter_value "$file" status)"
	[[ -n "$status" ]] || status="$([[ "$state" == "accepted" ]] && printf accepted || printf open)"
	risk="$(frontmatter_value "$file" risk)"
	priority="$(frontmatter_value "$file" priority)"
	stream="$(frontmatter_value "$file" stream)"
	rel="${file#"$ROOT"/}"
	claimed_by="$(frontmatter_value "$file" claimed_by)"
	claimed_at="$(frontmatter_value "$file" claimed_at)"
	claim_ref="$(frontmatter_value "$file" claim_ref)"
	expires="$(frontmatter_value "$file" claim_expires_at)"
	heartbeat="$(frontmatter_value "$file" claim_heartbeat_at)"
	created_by_role="$(frontmatter_value "$file" created_by_role)"
	[[ -n "$created_by_role" ]] || created_by_role="$(frontmatter_value "$file" issued_by_role)"
	delegated_to_role="$(frontmatter_value "$file" delegated_to_role)"
	[[ -n "$delegated_to_role" ]] || delegated_to_role="$(frontmatter_value "$file" delegate_to_role)"
	accepted_by="$(frontmatter_value "$file" accepted_by)"
	accepted_at="$(frontmatter_value "$file" accepted_at)"
	implemented_by="$(frontmatter_value "$file" implemented_by)"
	branch="$(ticket_declared_branch "$file" "$ticket_id")"
	worktree="$(ticket_declared_worktree "$file" "$ticket_id")"
	lease_status="$(ticket_lease_status "$file")"
	printf '{"id":'
	json_string "$ticket_id"
	printf ',"title":'
	json_string "$title"
	printf ',"status":'
	json_string "$status"
	printf ',"risk":'
	json_string "${risk:-R1}"
	printf ',"priority":'
	json_string "${priority:-P2}"
	printf ',"stream":'
	json_string "${stream:-process}"
	printf ',"state":'
	json_string "$state"
	printf ',"path":'
	json_string "$rel"
	printf ',"allowed_paths":'
	json_frontmatter_list "$file" allowed_paths
	printf ',"forbidden_paths":'
	json_frontmatter_list "$file" forbidden_paths
	printf ',"verification":'
	json_frontmatter_list "$file" verification
	printf ',"required_reports":'
	ticket_required_reports_json "$file"
	printf ',"claimed_by":'
	json_string "$claimed_by"
	printf ',"claimed_at":'
	json_string "$claimed_at"
	printf ',"created_by_role":'
	json_string "$created_by_role"
	printf ',"delegated_to_role":'
	json_string "$delegated_to_role"
	printf ',"accepted_by":'
	json_string "$accepted_by"
	printf ',"accepted_at":'
	json_string "$accepted_at"
	printf ',"implemented_by":'
	json_string "$implemented_by"
	printf ',"claim_ref":'
	json_string "$claim_ref"
	printf ',"claim_expires_at":'
	json_string "$expires"
	printf ',"claim_heartbeat_at":'
	json_string "$heartbeat"
	printf ',"requires_review":%s,"requires_human_confirmation":%s' \
		"$(json_bool "$(frontmatter_value "$file" requires_review)")" \
		"$(json_bool "$(frontmatter_value "$file" requires_human_confirmation)")"
	printf ',"branch":'
	json_string "$branch"
	printf ',"worktree":'
	json_string "$worktree"
	printf ',"evidence":'
	evidence_summary_json "$ticket_id"
	printf ',"reports":'
	reports_summary_json "$ticket_id" "$file"
	printf ',"next_action":'
	snapshot_next_action_json "$file" "$state" fast
	printf ',"lease":{"status":'
	json_string "$lease_status"
	printf ',"expires_at":'
	json_string "$expires"
	printf ',"seconds_remaining":'
	ticket_lease_remaining "$file"
	printf '}}'
}

snapshot_role_lint_json() {
	local file errors=0 count=0 tmp
	tmp="$(mktemp)"
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		lint_one_role "$file" >>"$tmp" 2>&1 || errors=$((errors + 1))
		count=$((count + 1))
	done < <(role_files)
	role_lint_graph_checks >>"$tmp" 2>&1 || errors=$((errors + 1))
	printf '{"ok":%s,"issues":%s,"checked":%s,"command":"./bin/palari role lint","detail":' \
		"$(json_bool "$([[ "$errors" == "0" ]] && printf true || printf false)")" "$errors" "$count"
	json_string "$(cat "$tmp")"
	printf '}'
	rm -f "$tmp"
}

snapshot_role_json() {
	local file="$1"
	local id title status parent tier risk rel
	id="$(frontmatter_value "$file" id)"
	title="$(frontmatter_value "$file" title)"
	status="$(frontmatter_value "$file" status)"
	parent="$(frontmatter_value "$file" parent_role)"
	tier="$(frontmatter_value "$file" tier)"
	risk="$(frontmatter_value "$file" max_risk)"
	rel="${file#"$ROOT"/}"
	printf '{"id":'
	json_string "$id"
	printf ',"title":'
	json_string "$title"
	printf ',"status":'
	json_string "$status"
	printf ',"parent_role":'
	json_string "$parent"
	printf ',"tier":'
	json_string "$tier"
	printf ',"max_risk":'
	json_string "$risk"
	printf ',"path":'
	json_string "$rel"
	printf ',"allowed_paths":'
	json_frontmatter_list "$file" allowed_paths
	printf ',"forbidden_paths":'
	json_frontmatter_list "$file" forbidden_paths
	printf ',"can_delegate_to":'
	json_frontmatter_list "$file" can_delegate_to
	printf ',"must_escalate_when":'
	json_frontmatter_list "$file" must_escalate_when
	printf ',"memory_tags":'
	json_frontmatter_list "$file" memory_tags
	printf ',"capabilities":{"may_create_roles":'
	json_string "$(frontmatter_value "$file" may_create_roles)"
	printf ',"may_create_tickets":%s,"may_execute_tickets":%s,"may_review_tickets":%s,"may_accept_tickets":%s}' \
		"$(json_bool "$(frontmatter_value "$file" may_create_tickets)")" \
		"$(json_bool "$(frontmatter_value "$file" may_execute_tickets)")" \
		"$(json_bool "$(frontmatter_value "$file" may_review_tickets)")" \
		"$(json_bool "$(frontmatter_value "$file" may_accept_tickets)")"
	printf ',"provenance":{"issued_by":'
	json_string "$(frontmatter_value "$file" issued_by)"
	printf ',"accepted_by":'
	json_string "$(frontmatter_value "$file" accepted_by)"
	printf ',"accepted_at":'
	json_string "$(frontmatter_value "$file" accepted_at)"
	printf ',"created":'
	json_string "$(frontmatter_value "$file" created)"
	printf ',"revoked_by":'
	json_string "$(frontmatter_value "$file" revoked_by)"
	printf ',"revoked_at":'
	json_string "$(frontmatter_value "$file" revoked_at)"
	printf '}}'
}

snapshot_role_fast_json() {
	local file="$1"
	local id title status tier risk rel
	id="$(frontmatter_value "$file" id)"
	title="$(frontmatter_value "$file" title)"
	status="$(frontmatter_value "$file" status)"
	tier="$(frontmatter_value "$file" tier)"
	risk="$(frontmatter_value "$file" max_risk)"
	rel="${file#"$ROOT"/}"
	printf '{"id":'
	json_string "$id"
	printf ',"title":'
	json_string "$title"
	printf ',"status":'
	json_string "$status"
	printf ',"tier":'
	json_string "$tier"
	printf ',"max_risk":'
	json_string "$risk"
	printf ',"path":'
	json_string "$rel"
	printf ',"allowed_paths":'
	json_frontmatter_list "$file" allowed_paths
	printf '}'
}

snapshot_role_items_json() {
	local mode="${1:-fast}"
	local file first="true"
	printf '['
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		[[ "$first" == "true" ]] || printf ','
		if [[ "$mode" == "full" ]]; then
			snapshot_role_json "$file"
		else
			snapshot_role_fast_json "$file"
		fi
		first="false"
	done < <(role_files)
	printf ']'
}

snapshot_role_lint_shallow_json() {
	local count
	count="$(role_files | wc -l | tr -d ' ')"
	printf '{"ok":true,"issues":0,"checked":%s,"mode":"shallow","command":"./bin/palari role lint","detail":' "$count"
	json_string "Skipped in the fast snapshot; run ./bin/palari role lint or ./bin/palari snapshot --json --full for full diagnostics."
	printf '}'
}

snapshot_roles_json() {
	local mode="${1:-fast}"
	local active proposed revoked
	active="$(role_files_for_dir "$ROLES_ACTIVE_DIR" | wc -l | tr -d ' ')"
	proposed="$(role_files_for_dir "$ROLES_PROPOSED_DIR" | wc -l | tr -d ' ')"
	revoked="$(role_files_for_dir "$ROLES_REVOKED_DIR" | wc -l | tr -d ' ')"
	printf '{"counts":{"active":%s,"proposed":%s,"revoked":%s},"lint":' "$active" "$proposed" "$revoked"
	if [[ "$mode" == "full" ]]; then
		snapshot_role_lint_json
	else
		snapshot_role_lint_shallow_json
	fi
	printf ',"items":'
	snapshot_role_items_json "$mode"
	printf '}'
}

snapshot_inbox_category() {
	local status="$1"
	local actor="$2"
	local severity="$3"
	local label="$4"
	if [[ "$actor" == "human" || "$status" == "needs-human" ]]; then
		printf 'human-gate\n'
	elif [[ "$severity" == "blocked" || "$status" == "blocked" ]]; then
		printf 'blocked\n'
	elif [[ "$actor" == "reviewer" ]]; then
		printf 'review-needed\n'
	elif [[ "$label" == "Finish evidence" || "$label" == "Create evidence" ]]; then
		printf 'evidence-needed\n'
	elif [[ "$severity" == "next" ]]; then
		printf 'can-continue\n'
	elif [[ "$severity" == "watch" ]]; then
		printf 'watch\n'
	else
		printf 'monitor\n'
	fi
}

snapshot_inbox_label() {
	case "$1" in
	human-gate) printf 'Needs human decision\n' ;;
	blocked) printf 'Blocked\n' ;;
	review-needed) printf 'Review needed\n' ;;
	evidence-needed) printf 'Evidence needed\n' ;;
	can-continue) printf 'Can continue\n' ;;
	watch) printf 'Watch\n' ;;
	*) printf 'Monitor\n' ;;
	esac
}

snapshot_inbox_item_json() {
	local file="$1"
	local mode="${2:-fast}"
	local id title status category category_label action_label action_detail action_command action_actor action_severity
	id="$(frontmatter_value "$file" id)"
	[[ -n "$id" ]] || id="$(ticket_title_from_file "$file")"
	title="$(frontmatter_value "$file" title)"
	status="$(frontmatter_value "$file" status)"
	snapshot_next_action_values "$file" "active" action "$mode"
	category="$(snapshot_inbox_category "$status" "$action_actor" "$action_severity" "$action_label")"
	SNAPSHOT_LAST_INBOX_CATEGORY="$category"
	category_label="$(snapshot_inbox_label "$category")"
	printf '{"ticket_id":'
	json_string "$id"
	printf ',"title":'
	json_string "$title"
	printf ',"status":'
	json_string "$status"
	printf ',"category":'
	json_string "$category"
	printf ',"category_label":'
	json_string "$category_label"
	printf ',"label":'
	json_string "$action_label"
	printf ',"detail":'
	json_string "$action_detail"
	printf ',"command":'
	json_string "$action_command"
	printf ',"actor":'
	json_string "$action_actor"
	printf ',"severity":'
	json_string "$action_severity"
	printf '}'
}

snapshot_operator_inbox_counts_reset() {
	SNAPSHOT_INBOX_HUMAN=0
	SNAPSHOT_INBOX_BLOCKED=0
	SNAPSHOT_INBOX_REVIEW=0
	SNAPSHOT_INBOX_EVIDENCE=0
	SNAPSHOT_INBOX_CONTINUE=0
	SNAPSHOT_INBOX_WATCH=0
	SNAPSHOT_INBOX_MONITOR=0
}

snapshot_operator_inbox_count_category() {
	case "$1" in
	human-gate) SNAPSHOT_INBOX_HUMAN=$((SNAPSHOT_INBOX_HUMAN + 1)) ;;
	blocked) SNAPSHOT_INBOX_BLOCKED=$((SNAPSHOT_INBOX_BLOCKED + 1)) ;;
	review-needed) SNAPSHOT_INBOX_REVIEW=$((SNAPSHOT_INBOX_REVIEW + 1)) ;;
	evidence-needed) SNAPSHOT_INBOX_EVIDENCE=$((SNAPSHOT_INBOX_EVIDENCE + 1)) ;;
	can-continue) SNAPSHOT_INBOX_CONTINUE=$((SNAPSHOT_INBOX_CONTINUE + 1)) ;;
	watch) SNAPSHOT_INBOX_WATCH=$((SNAPSHOT_INBOX_WATCH + 1)) ;;
	*) SNAPSHOT_INBOX_MONITOR=$((SNAPSHOT_INBOX_MONITOR + 1)) ;;
	esac
}

snapshot_operator_inbox_json() {
	local mode="${1:-fast}"
	local file first="true"
	snapshot_operator_inbox_counts_reset
	printf '['
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		[[ "$first" == "true" ]] || printf ','
		snapshot_inbox_item_json "$file" "$mode"
		snapshot_operator_inbox_count_category "$SNAPSHOT_LAST_INBOX_CATEGORY"
		first="false"
	done < <(ticket_files)
	printf ']'
}

snapshot_operator_inbox_counts_json() {
	printf '{"human_gate":%s,"blocked":%s,"review_needed":%s,"evidence_needed":%s,"can_continue":%s,"watch":%s,"monitor":%s}' \
		"${SNAPSHOT_INBOX_HUMAN:-0}" "${SNAPSHOT_INBOX_BLOCKED:-0}" "${SNAPSHOT_INBOX_REVIEW:-0}" \
		"${SNAPSHOT_INBOX_EVIDENCE:-0}" "${SNAPSHOT_INBOX_CONTINUE:-0}" "${SNAPSHOT_INBOX_WATCH:-0}" \
		"${SNAPSHOT_INBOX_MONITOR:-0}"
}

snapshot_open_decisions_json() {
	# Open decisions are part of the founder inbox: structured questions an
	# agent has brought to the human, with options, a recommendation, and a
	# respond-by date. Additive JSON; existing console consumers are unchanged.
	local file first="true" id title respond_by ticket goal recommend
	printf '['
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		id="$(frontmatter_value "$file" id)"
		title="$(frontmatter_value "$file" title)"
		respond_by="$(frontmatter_value "$file" respond_by)"
		ticket="$(frontmatter_value "$file" ticket)"
		goal="$(frontmatter_value "$file" goal)"
		recommend="$(frontmatter_value "$file" recommended_option)"
		[[ "$first" == "true" ]] || printf ','
		printf '{"id":%s,"title":%s,"respond_by":%s,"ticket":%s,"goal":%s,"recommended_option":%s,"command":%s}' \
			"$(json_string "$id")" "$(json_string "$title")" "$(json_string "$respond_by")" \
			"$(json_string "$ticket")" "$(json_string "$goal")" "$(json_string "$recommend")" \
			"$(json_string "./bin/palari decide record $id --choice N --by NAME")"
		first="false"
	done < <(decision_files_in_state open 2>/dev/null || true)
	printf ']'
}

snapshot_operator_json() {
	local mode="${1:-fast}"
	local file count=0
	file=""
	while IFS= read -r file; do
		[[ -n "$file" ]] && break
	done < <(ticket_files)
	if [[ -n "$file" ]]; then
		printf '{"has_active_work":true,"next_action":'
		snapshot_next_action_json "$file" "active" "$mode"
		printf ',"inbox":'
		snapshot_operator_inbox_json "$mode"
		printf ',"inbox_counts":'
		snapshot_operator_inbox_counts_json
		printf ',"open_decisions":'
		snapshot_open_decisions_json
		printf '}'
	else
		printf '{"has_active_work":false,"next_action":{"label":"Create or adopt a ticket","detail":"No active tickets are waiting; define the next scoped slice when there is work to delegate.","command":"./bin/palari ticket create TICKET-ID TITLE --allowed PATH --verify COMMAND","actor":"human","severity":"clear"},"inbox":[],"inbox_counts":{"human_gate":0,"blocked":0,"review_needed":0,"evidence_needed":0,"can_continue":0,"watch":0,"monitor":0},"open_decisions":'
		snapshot_open_decisions_json
		printf '}'
	fi
	: "$count"
}
