# shellcheck shell=bash
# shellcheck disable=SC2153 # ROOT and *_DIR globals are sourced from core.bash.
#
# Goals are first-class repo artifacts. A goal is the unit a human/founder
# uses to direct autonomous work: proposals and tickets declare which goal
# they serve via `serves_goal`, and the queue runner prioritizes inside a
# goal. Goals never grant authority; roles do that. Goals only make intent
# machine-readable and traceable.

valid_goal_id() {
	local id="$1"
	[[ "$id" =~ ^GOAL-[0-9]{4}$ ]]
}

goal_dir_for_state() {
	case "$1" in
	active) printf '%s\n' "$GOALS_ACTIVE_DIR" ;;
	proposed) printf '%s\n' "$GOALS_PROPOSED_DIR" ;;
	closed) printf '%s\n' "$GOALS_CLOSED_DIR" ;;
	*) return 1 ;;
	esac
}

goal_files_in_state() {
	local state="$1" dir
	dir="$(goal_dir_for_state "$state")" || return 1
	[[ -d "$ROOT/$dir" ]] || return 0
	find "$ROOT/$dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | sort
}

find_goal_file() {
	local id="$1"
	local state="${2:-any}"
	local file states
	if [[ "$state" == "any" ]]; then
		states="active proposed closed"
	else
		states="$state"
	fi
	local s
	for s in $states; do
		while IFS= read -r file; do
			[[ -n "$file" ]] || continue
			[[ "$(frontmatter_value "$file" id)" == "$id" ]] && {
				printf '%s\n' "$file"
				return 0
			}
		done < <(goal_files_in_state "$s")
	done
	return 1
}

goal_tickets_serving() {
	# Print "STATUS<TAB>ID<TAB>TITLE" for every ticket serving the goal.
	local goal_id="$1" file
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		[[ "$(frontmatter_value "$file" serves_goal)" == "$goal_id" ]] || continue
		printf '%s\t%s\t%s\n' \
			"$(frontmatter_value "$file" status)" \
			"$(frontmatter_value "$file" id)" \
			"$(frontmatter_value "$file" title)"
	done < <(all_ticket_files)
}

cmd_goal_create() {
	local id="${1:-}"
	local title="${2:-}"
	shift 2 || true
	[[ -n "$id" && -n "$title" ]] || die "goal create requires GOAL-ID and title"
	valid_goal_id "$id" || die "invalid goal id: $id; use GOAL-0001"

	local owner="founder" due="" parent="" status="active" arg
	local -a success=()
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--owner)
			owner="$2"
			shift 2
			;;
		--success)
			success+=("$2")
			shift 2
			;;
		--due)
			due="$2"
			shift 2
			;;
		--parent)
			parent="$2"
			shift 2
			;;
		--proposed)
			status="proposed"
			shift
			;;
		*) die "unknown goal create option: $arg" ;;
		esac
	done
	((${#success[@]} > 0)) || die "goal create needs at least one --success criterion (how a human will judge the goal is met)"
	if [[ -n "$parent" ]]; then
		valid_goal_id "$parent" || die "invalid parent goal id: $parent"
		find_goal_file "$parent" >/dev/null || die "parent goal not found: $parent"
	fi

	local dir slug file created
	dir="$(goal_dir_for_state "$status")"
	mkdir -p "$ROOT/$dir"
	slug="$(slugify "$title")"
	file="$ROOT/$dir/$id-$slug.md"
	[[ ! -e "$file" ]] || die "goal already exists: ${file#"$ROOT"/}"
	find_goal_file "$id" >/dev/null 2>&1 && die "goal id already in use: $id"
	created="$(today_utc)"

	{
		printf -- '---\n'
		printf 'id: %s\n' "$id"
		printf 'title: %s\n' "$title"
		printf 'status: %s\n' "$status"
		printf 'owner: %s\n' "$owner"
		printf 'parent_goal: %s\n' "$parent"
		printf 'due: %s\n' "$due"
		write_yaml_list success_criteria "${success[@]}"
		printf 'closed_as:\n'
		printf 'closed_by:\n'
		printf 'closed_at:\n'
		printf 'created: %s\n' "$created"
		printf 'updated: %s\n' "$created"
		printf -- '---\n\n'
		printf '# %s %s\n\n' "$id" "$title"
		printf '## Why\n\nState why this goal matters and what changes when it is met.\n\n'
		printf '## Success Criteria\n\n'
		for arg in "${success[@]}"; do printf -- '- %s\n' "$arg"; done
		printf '\n## Boundaries\n\nList what this goal explicitly does not cover.\n\n'
		printf '## Linked Work\n\nProposals and tickets serving this goal declare `serves_goal: %s`.\n' "$id"
	} >"$file"
	printf 'goal create: %s\n' "${file#"$ROOT"/}"
	printf 'link work to it with: ./bin/palari ticket create TICKET-ID TITLE --goal %s ...\n' "$id"
}

cmd_goal_list() {
	local state file id title due open_count
	for state in active proposed closed; do
		while IFS= read -r file; do
			[[ -n "$file" ]] || continue
			id="$(frontmatter_value "$file" id)"
			title="$(frontmatter_value "$file" title)"
			due="$(frontmatter_value "$file" due)"
			open_count=0
			while IFS=$'\t' read -r tstatus _ _; do
				[[ "$tstatus" == "accepted" ]] || open_count=$((open_count + 1))
			done < <(goal_tickets_serving "$id")
			printf '%-9s %s  %s%s  (open tickets: %s)\n' \
				"$state" "$id" "$title" "${due:+  due $due}" "$open_count"
		done < <(goal_files_in_state "$state")
	done
}

cmd_goal_show() {
	local id="${1:-}"
	[[ -n "$id" ]] || die "goal show requires GOAL-ID"
	local file
	file="$(find_goal_file "$id")" || die "goal not found: $id"
	printf 'Goal: %s - %s\n' "$id" "$(frontmatter_value "$file" title)"
	printf 'status: %s\n' "$(frontmatter_value "$file" status)"
	printf 'owner: %s\n' "$(frontmatter_value "$file" owner)"
	printf 'due: %s\n' "$(frontmatter_value "$file" due)"
	printf 'file: %s\n' "${file#"$ROOT"/}"
	print_frontmatter_list_block "success criteria" "$file" success_criteria
	printf 'serving tickets:\n'
	local found="false" tstatus tid ttitle
	while IFS=$'\t' read -r tstatus tid ttitle; do
		found="true"
		printf '  %-11s %s  %s\n' "$tstatus" "$tid" "$ttitle"
	done < <(goal_tickets_serving "$id")
	[[ "$found" == "true" ]] || printf '  (none yet)\n'
}

goal_close() {
	local id="$1" outcome="$2" by="$3"
	[[ -n "$id" ]] || die "goal $outcome requires GOAL-ID"
	[[ -n "$by" ]] || die "goal $outcome requires --by NAME (a human closes goals)"
	local file
	file="$(find_goal_file "$id" active)" || file="$(find_goal_file "$id" proposed)" || die "open goal not found: $id"
	local target="$ROOT/$GOALS_CLOSED_DIR/$(basename "$file")"
	mkdir -p "$ROOT/$GOALS_CLOSED_DIR"
	update_frontmatter_scalars "$file" \
		"status"$'\035'"closed"$'\034' \
		"closed_as"$'\035'"$outcome"$'\034' \
		"closed_by"$'\035'"$by"$'\034' \
		"closed_at"$'\035'"$(now_utc)"$'\034' \
		"updated"$'\035'"$(today_utc)"$'\034'
	mv "$file" "$target"
	printf 'goal %s: %s -> %s\n' "$outcome" "$id" "${target#"$ROOT"/}"
}

cmd_goal_adopt() {
	local id="${1:-}"
	shift || true
	[[ -n "$id" ]] || die "goal adopt requires GOAL-ID"
	local by="" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--by)
			by="$2"
			shift 2
			;;
		*) die "unknown goal adopt option: $arg" ;;
		esac
	done
	[[ -n "$by" ]] || die "goal adopt requires --by NAME (a human adopts goals)"
	local file target
	file="$(find_goal_file "$id" proposed)" || die "proposed goal not found: $id"
	mkdir -p "$ROOT/$GOALS_ACTIVE_DIR"
	target="$ROOT/$GOALS_ACTIVE_DIR/$(basename "$file")"
	update_frontmatter_scalars "$file" \
		"status"$'\035'"active"$'\034' \
		"updated"$'\035'"$(today_utc)"$'\034'
	mv "$file" "$target"
	printf 'goal adopt: %s -> %s (by %s)\n' "$id" "${target#"$ROOT"/}" "$by"
}

cmd_goal_lint() {
	local issues=0 state file id status line
	for state in active proposed closed; do
		while IFS= read -r file; do
			[[ -n "$file" ]] || continue
			id="$(frontmatter_value "$file" id)"
			status="$(frontmatter_value "$file" status)"
			if ! valid_goal_id "$id"; then
				printf 'goal lint: invalid id in %s\n' "${file#"$ROOT"/}"
				issues=$((issues + 1))
			fi
			if [[ "$status" != "$state" && ! ("$state" == "closed" && "$status" == "closed") ]]; then
				printf 'goal lint: %s status %s does not match directory %s\n' "$id" "$status" "$state"
				issues=$((issues + 1))
			fi
			if [[ "$(frontmatter_list_count "$file" success_criteria)" == "0" ]]; then
				printf 'goal lint: %s has no success criteria\n' "$id"
				issues=$((issues + 1))
			fi
			while IFS= read -r line; do
				[[ -n "$line" ]] || continue
				printf 'goal lint: %s yaml safety: %s\n' "$id" "$line"
				issues=$((issues + 1))
			done < <(frontmatter_yaml_issues "$file")
		done < <(goal_files_in_state "$state")
	done
	# Orphan check: tickets pointing at goals that do not exist.
	local goal_ref
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		goal_ref="$(frontmatter_value "$file" serves_goal)"
		[[ -n "$goal_ref" ]] || continue
		if ! find_goal_file "$goal_ref" >/dev/null 2>&1; then
			printf 'goal lint: ticket %s serves unknown goal %s\n' \
				"$(frontmatter_value "$file" id)" "$goal_ref"
			issues=$((issues + 1))
		fi
	done < <(ticket_files)
	if ((issues > 0)); then
		printf 'goal lint: %s issue(s)\n' "$issues"
		return 1
	fi
	printf 'goal lint: ok\n'
}

cmd_goal() {
	local sub="${1:-}"
	shift || true
	case "$sub" in
	create)
		cmd_goal_create "$@"
		;;
	list)
		cmd_goal_list "$@"
		;;
	show)
		cmd_goal_show "$@"
		;;
	adopt)
		cmd_goal_adopt "$@"
		;;
	achieve)
		goal_close "${1:-}" achieved "$(goal_by_flag "$@")"
		;;
	drop)
		goal_close "${1:-}" dropped "$(goal_by_flag "$@")"
		;;
	lint)
		cmd_goal_lint "$@"
		;;
	help | -h | --help | "")
		cat <<'USAGE'
usage: palari goal SUBCOMMAND

  create GOAL-ID TITLE --success TEXT [--success TEXT ...]
         [--owner NAME] [--due YYYY-MM-DD] [--parent GOAL-ID] [--proposed]
  list                       List goals by state with open ticket counts.
  show GOAL-ID               Show a goal and the tickets serving it.
  adopt GOAL-ID --by NAME    Promote a proposed goal to active (human action).
  achieve GOAL-ID --by NAME  Close a goal as achieved (human action).
  drop GOAL-ID --by NAME     Close a goal as dropped (human action).
  lint                       Check goal files and serves_goal references.

Goals make founder intent machine-readable. Tickets and proposals link to a
goal with `serves_goal: GOAL-ID` (`--goal` on ticket/propose create), which is
what the queue runner uses to prioritize and what makes "why is this the next
ticket" answerable from repo state alone. Goals never grant authority.
USAGE
		;;
	*) die "unknown goal command: $sub" ;;
	esac
}

goal_by_flag() {
	# Extract --by NAME from trailing args of achieve/drop.
	local by="" arg
	while (($# > 0)); do
		arg="$1"
		if [[ "$arg" == "--by" ]]; then
			by="${2:-}"
			shift 2 || break
		else
			shift
		fi
	done
	printf '%s' "$by"
}
