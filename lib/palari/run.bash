# shellcheck shell=bash
# shellcheck disable=SC2153 # ROOT and *_DIR globals are sourced from core.bash.
#
# `palari run --dry-run` is the self-organization loop, in read-only form.
# It answers: what would Palari do next if asked to keep working until a real
# human gate blocks progress? It plans the queue; it does not claim tickets,
# create worktrees, spawn agents, accept, commit, push, merge, or deploy.
# Supervised and autonomous execution modes intentionally do not exist yet;
# `palari run` without --dry-run fails closed.

run_ticket_goal_matches() {
	local file="$1" goal_filter="$2"
	[[ -z "$goal_filter" ]] && return 0
	[[ "$(frontmatter_value "$file" serves_goal)" == "$goal_filter" ]]
}

run_ticket_skip_reason() {
	# Print a skip reason and return 0 if the ticket must be skipped.
	local file="$1" id="$2" status="$3"
	local overlap
	if [[ "$status" == "open" || "$status" == "reopened" ]]; then
		if [[ "$(frontmatter_list_count "$file" allowed_paths)" == "0" ]]; then
			printf 'allowed_paths is empty; scope is undefined\n'
			return 0
		fi
		if frontmatter_list_contains "$file" allowed_paths '**'; then
			printf 'allowed_paths contains "**"; scope is too broad for autonomous selection\n'
			return 0
		fi
		overlap="$(scope_overlap_summary_quiet "$file" || true)"
		if [[ -n "$overlap" ]]; then
			printf 'write scope overlaps another active ticket: %s\n' "$overlap"
			return 0
		fi
	fi
	if [[ "$status" == "claimed" && "$(ticket_lease_status "$file")" == "expired" ]]; then
		printf 'claim lease expired; ownership is unclear and must be renewed or released by the owner\n'
		return 0
	fi
	return 1
}

scope_overlap_summary_quiet() {
	# Best-effort one-line overlap summary using the core overlap checker.
	# scope_overlap_errors prints diagnostics to stderr and returns the count.
	local file="$1"
	local out
	out="$(scope_overlap_errors "$file" 2>&1 1>/dev/null)" && return 1
	printf '%s' "$out" | head -1
	return 0
}

run_plan_item() {
	# Emit one plan item in both human and machine form via globals.
	local kind="$1" id="$2" title="$3" reason="$4" role="$5" command="$6" stop_reason="$7"
	RUN_PLAN_HUMAN+="$(printf '%-6s %s  %s\n       reason: %s\n' "$kind" "$id" "$title" "$reason")"$'\n'
	[[ -n "$role" ]] && RUN_PLAN_HUMAN+="$(printf '       role lens: %s\n' "$role")"$'\n'
	[[ -n "$command" ]] && RUN_PLAN_HUMAN+="$(printf '       command: %s\n' "$command")"$'\n'
	[[ -n "$stop_reason" ]] && RUN_PLAN_HUMAN+="$(printf '       stop: %s\n' "$stop_reason")"$'\n'
	local item
	item="$(printf '{"kind":%s,"id":%s,"title":%s,"reason":%s,"role":%s,"command":%s,"stop_reason":%s}' \
		"$(json_string "$kind")" "$(json_string "$id")" "$(json_string "$title")" \
		"$(json_string "$reason")" "$(json_string "$role")" "$(json_string "$command")" \
		"$(json_string "$stop_reason")")"
	if [[ -n "$RUN_PLAN_JSON" ]]; then
		RUN_PLAN_JSON+=",$item"
	else
		RUN_PLAN_JSON="$item"
	fi
}

run_role_lens_for_status() {
	case "$1" in
	open | reopened | claimed) printf 'specialist\n' ;;
	in-review) printf 'reviewer\n' ;;
	blocked | needs-human) printf 'human\n' ;;
	*) printf 'orchestrator\n' ;;
	esac
}

cmd_run() {
	require_base_folders
	local dry_run="false" until_mode="blocked" goal_filter="" max_items=10 as_json="false" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--dry-run)
			dry_run="true"
			shift
			;;
		--until)
			until_mode="$2"
			shift 2
			;;
		--goal)
			goal_filter="$2"
			shift 2
			;;
		--max)
			max_items="$2"
			shift 2
			;;
		--json)
			as_json="true"
			shift
			;;
		help | -h | --help)
			cat <<'USAGE'
usage: palari run --dry-run [--until blocked] [--goal GOAL-ID] [--max N] [--json]

Plan what Palari would do next if asked to keep working until a human gate
blocks progress. Dry-run is read-only: it does not claim, isolate, execute,
accept, commit, push, merge, or deploy. Supervised/autonomous modes are not
implemented; `palari run` without --dry-run fails closed by design.

Selection priority (from the queue-runner spec):
  1. Human gates and open decisions surface first, as stop items.
  2. Blocked tickets that can be repaired without new authority.
  3. Open or reopened tickets that can be claimed and isolated.
  4. Claimed tickets with active leases and missing evidence.
  5. In-review tickets needing reviewer notes.
USAGE
			return 0
			;;
		*) die "unknown run option: $arg" ;;
		esac
	done
	if [[ "$dry_run" != "true" ]]; then
		die "palari run requires --dry-run; supervised and autonomous execution are not implemented and fail closed (see docs/autonomy/queue-runner-dry-run.md)"
	fi
	[[ "$until_mode" == "blocked" ]] || die "unsupported --until mode: $until_mode (only 'blocked' exists)"
	[[ "$max_items" =~ ^[0-9]+$ ]] || die "--max must be a number"
	if [[ -n "$goal_filter" ]]; then
		valid_goal_id "$goal_filter" || die "invalid goal id: $goal_filter"
		find_goal_file "$goal_filter" >/dev/null || die "goal not found: $goal_filter"
	fi

	local RUN_PLAN_HUMAN="" RUN_PLAN_JSON=""
	local planned=0 stops=0 skips=0
	local file id title status reason role command skip_reason

	# 1. Open decisions are always stop items at the top of the plan.
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		id="$(frontmatter_value "$file" id)"
		title="$(frontmatter_value "$file" title)"
		run_plan_item "stop" "$id" "$title" \
			"open decision awaiting a human" "human" \
			"./bin/palari decide record $id --choice N --by NAME" \
			"human decision required"
		stops=$((stops + 1))
	done < <(decision_files_in_state open 2>/dev/null || true)

	# 2. Walk active tickets in spec priority order.
	local pass
	for pass in needs-human blocked open reopened claimed in-review; do
		while IFS= read -r file; do
			[[ -n "$file" ]] || continue
			status="$(frontmatter_value "$file" status)"
			[[ "$status" == "$pass" ]] || continue
			run_ticket_goal_matches "$file" "$goal_filter" || {
				skips=$((skips + 1))
				continue
			}
			id="$(frontmatter_value "$file" id)"
			title="$(frontmatter_value "$file" title)"
			role="$(run_role_lens_for_status "$status")"

			if [[ "$status" == "needs-human" ]]; then
				run_plan_item "stop" "$id" "$title" \
					"ticket is parked at a human gate" "human" \
					"./bin/palari packet $id human" \
					"human decision or acceptance required"
				stops=$((stops + 1))
				continue
			fi

			if skip_reason="$(run_ticket_skip_reason "$file" "$id" "$status")"; then
				run_plan_item "skip" "$id" "$title" "$skip_reason" "" "" ""
				skips=$((skips + 1))
				continue
			fi

			local action_label action_command action_actor action_severity action_detail
			snapshot_next_action_values "$file" "active" action
			reason="$action_detail"
			command="$action_command"
			if [[ "$action_actor" == "human" ]]; then
				run_plan_item "stop" "$id" "$title" "$reason" "human" "$command" "$action_label"
				stops=$((stops + 1))
				continue
			fi
			if ((planned >= max_items)); then
				run_plan_item "skip" "$id" "$title" "plan budget reached (--max $max_items)" "" "" ""
				skips=$((skips + 1))
				continue
			fi
			if model_routing_enabled; then
				reason="$reason [model class: $(ticket_model_class "$file")]"
			fi
			run_plan_item "next" "$id" "$title" "$reason" "$role" "$command" ""
			planned=$((planned + 1))
		done < <(ticket_files)
	done

	local summary
	if ((planned == 0 && stops == 0)); then
		summary="no actionable work: the queue is empty or everything is skipped; create or adopt a ticket"
	elif ((planned == 0)); then
		summary="no agent-safe work remains; every remaining item waits on a human"
	else
		summary="$planned step(s) plannable before the next human gate"
	fi

	if [[ "$as_json" == "true" ]]; then
		printf '{"mode":"dry-run","until":"blocked","goal":%s,"plan":[%s],"planned":%s,"stops":%s,"skips":%s,"summary":%s}\n' \
			"$(json_string "$goal_filter")" "$RUN_PLAN_JSON" "$planned" "$stops" "$skips" "$(json_string "$summary")"
	else
		printf 'Palari queue dry-run (read-only)\n'
		[[ -z "$goal_filter" ]] || printf 'goal filter: %s\n' "$goal_filter"
		printf '\n'
		if [[ -n "$RUN_PLAN_HUMAN" ]]; then
			printf '%s' "$RUN_PLAN_HUMAN"
		else
			printf '  (empty queue)\n'
		fi
		printf '\nplanned: %s  stops: %s  skips: %s\n' "$planned" "$stops" "$skips"
		printf 'summary: %s\n' "$summary"
		printf 'note: dry-run changed nothing; copy a printed command to act, or record decisions first\n'
	fi
}
