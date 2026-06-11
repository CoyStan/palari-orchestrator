# shellcheck shell=bash
# shellcheck disable=SC2153 # This module is sourced after core and role/lifecycle modules.
snapshot_next_action_values() {
	local file="$1"
	local state="$2"
	local prefix="$3"
	local id status target accepted_by accepted_at label detail command actor severity
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
		elif ticket_evidence_present_quiet "$id" && ticket_report_lint_quiet "$id"; then
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
		;;
	in-review)
		if ! ticket_evidence_present_quiet "$id"; then
			label="Create evidence"
			detail="Review cannot complete until the standard evidence bundle exists."
			command="./bin/palari ci $id --base $target"
			actor="specialist"
			severity="blocked"
		elif ! ticket_report_lint_quiet "$id"; then
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

snapshot_next_action_json() {
	local file="$1"
	local state="$2"
	local action_label action_detail action_command action_actor action_severity
	snapshot_next_action_values "$file" "$state" action
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

snapshot_role_items_json() {
	local file first="true"
	printf '['
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		[[ "$first" == "true" ]] || printf ','
		snapshot_role_json "$file"
		first="false"
	done < <(role_files)
	printf ']'
}

snapshot_roles_json() {
	local active proposed revoked
	active="$(role_files_for_dir "$ROLES_ACTIVE_DIR" | wc -l | tr -d ' ')"
	proposed="$(role_files_for_dir "$ROLES_PROPOSED_DIR" | wc -l | tr -d ' ')"
	revoked="$(role_files_for_dir "$ROLES_REVOKED_DIR" | wc -l | tr -d ' ')"
	printf '{"counts":{"active":%s,"proposed":%s,"revoked":%s},"lint":' "$active" "$proposed" "$revoked"
	snapshot_role_lint_json
	printf ',"items":'
	snapshot_role_items_json
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
	local id title status category category_label action_label action_detail action_command action_actor action_severity
	id="$(frontmatter_value "$file" id)"
	[[ -n "$id" ]] || id="$(ticket_title_from_file "$file")"
	title="$(frontmatter_value "$file" title)"
	status="$(frontmatter_value "$file" status)"
	snapshot_next_action_values "$file" "active" action
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
	local file first="true"
	snapshot_operator_inbox_counts_reset
	printf '['
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		[[ "$first" == "true" ]] || printf ','
		snapshot_inbox_item_json "$file"
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
	local file count=0
	file=""
	while IFS= read -r file; do
		[[ -n "$file" ]] && break
	done < <(ticket_files)
	if [[ -n "$file" ]]; then
		printf '{"has_active_work":true,"next_action":'
		snapshot_next_action_json "$file" "active"
		printf ',"inbox":'
		snapshot_operator_inbox_json
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
