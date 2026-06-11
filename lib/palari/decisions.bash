# shellcheck shell=bash
# shellcheck disable=SC2153 # ROOT and *_DIR globals are sourced from core.bash.
#
# Decisions are first-class artifacts for the "bring me decisions" loop.
# Agents may draft a decision (question, options with tradeoffs, a
# recommendation, a respond-by date, and a stated default), but only a human
# records the outcome. Recorded decisions move to decisions/decided and are
# mirrored into repo memory so future packets can cite them.

valid_decision_id() {
	local id="$1"
	[[ "$id" =~ ^DEC-[0-9]{4}$ ]]
}

decision_files_in_state() {
	local state="$1" dir
	case "$state" in
	open) dir="$DECISIONS_OPEN_DIR" ;;
	decided) dir="$DECISIONS_DECIDED_DIR" ;;
	*) return 1 ;;
	esac
	[[ -d "$ROOT/$dir" ]] || return 0
	find "$ROOT/$dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | sort
}

find_decision_file() {
	local id="$1"
	local state="${2:-any}"
	local states file s
	if [[ "$state" == "any" ]]; then
		states="open decided"
	else
		states="$state"
	fi
	for s in $states; do
		while IFS= read -r file; do
			[[ -n "$file" ]] || continue
			[[ "$(frontmatter_value "$file" id)" == "$id" ]] && {
				printf '%s\n' "$file"
				return 0
			}
		done < <(decision_files_in_state "$s")
	done
	return 1
}

open_decision_count() {
	decision_files_in_state open | wc -l | tr -d ' '
}

cmd_decide_create() {
	local id="${1:-}"
	local title="${2:-}"
	shift 2 || true
	[[ -n "$id" && -n "$title" ]] || die "decide create requires DEC-ID and title"
	valid_decision_id "$id" || die "invalid decision id: $id; use DEC-0001"
	! find_decision_file "$id" >/dev/null 2>&1 || die "decision id already in use: $id"

	local ticket="" goal="" recommend="" default_option="" respond_by="" raised_by="agent" arg
	local -a options=()
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--ticket)
			ticket="$2"
			shift 2
			;;
		--goal)
			goal="$2"
			shift 2
			;;
		--option)
			options+=("$2")
			shift 2
			;;
		--recommend)
			recommend="$2"
			shift 2
			;;
		--default)
			default_option="$2"
			shift 2
			;;
		--respond-by)
			respond_by="$2"
			shift 2
			;;
		--raised-by)
			raised_by="$2"
			shift 2
			;;
		*) die "unknown decide create option: $arg" ;;
		esac
	done
	((${#options[@]} >= 2)) || die "decide create needs at least two --option entries; a decision with one option is a notification"
	if [[ -n "$recommend" ]]; then
		[[ "$recommend" =~ ^[0-9]+$ ]] && ((recommend >= 1 && recommend <= ${#options[@]})) ||
			die "--recommend must be an option number between 1 and ${#options[@]}"
	fi
	if [[ -n "$default_option" ]]; then
		[[ "$default_option" =~ ^[0-9]+$ ]] && ((default_option >= 1 && default_option <= ${#options[@]})) ||
			die "--default must be an option number between 1 and ${#options[@]}"
	fi
	if [[ -n "$ticket" ]]; then
		find_ticket_file "$ticket" >/dev/null || die "ticket not found: $ticket"
	fi
	if [[ -n "$goal" ]]; then
		find_goal_file "$goal" >/dev/null || die "goal not found: $goal"
	fi

	local slug file created i
	mkdir -p "$ROOT/$DECISIONS_OPEN_DIR"
	slug="$(slugify "$title")"
	file="$ROOT/$DECISIONS_OPEN_DIR/$id-$slug.md"
	[[ ! -e "$file" ]] || die "decision file already exists: ${file#"$ROOT"/}"
	created="$(today_utc)"

	{
		printf -- '---\n'
		printf 'id: %s\n' "$id"
		printf 'title: %s\n' "$title"
		printf 'status: open\n'
		printf 'ticket: %s\n' "$ticket"
		printf 'goal: %s\n' "$goal"
		printf 'raised_by: %s\n' "$raised_by"
		write_yaml_list options "${options[@]}"
		printf 'recommended_option: %s\n' "$recommend"
		printf 'default_option: %s\n' "$default_option"
		printf 'respond_by: %s\n' "$respond_by"
		printf 'chosen_option:\n'
		printf 'decided_by:\n'
		printf 'decided_at:\n'
		printf 'created: %s\n' "$created"
		printf 'updated: %s\n' "$created"
		printf -- '---\n\n'
		printf '# %s %s\n\n' "$id" "$title"
		printf '## Question\n\nState the decision the human needs to make in one sentence.\n\n'
		printf '## Options\n\n'
		i=1
		for arg in "${options[@]}"; do
			printf '### Option %s: %s\n\nTradeoffs: describe cost, risk, and what this forecloses.\n\n' "$i" "$arg"
			i=$((i + 1))
		done
		printf '## Recommendation\n\n'
		if [[ -n "$recommend" ]]; then
			printf 'Option %s. Explain why in two or three sentences with evidence links.\n\n' "$recommend"
		else
			printf 'No recommendation recorded. Add one so the human decides in seconds, not minutes.\n\n'
		fi
		printf '## Default If No Response\n\n'
		if [[ -n "$default_option" ]]; then
			printf 'If there is no response by %s, work proceeds as Option %s. The default may not include accept, merge, push, deploy, spend, or any human-gated action.\n\n' "${respond_by:-the respond-by date}" "$default_option"
		else
			printf 'No default. Work on the linked scope pauses until a human records a choice.\n\n'
		fi
		printf '## Evidence\n\nLink reports, tickets, and data the options rest on.\n'
	} >"$file"
	printf 'decide create: %s\n' "${file#"$ROOT"/}"
	printf 'record the outcome with: ./bin/palari decide record %s --choice N --by NAME\n' "$id"
}

cmd_decide_list() {
	local state file id title respond_by ticket
	for state in open decided; do
		while IFS= read -r file; do
			[[ -n "$file" ]] || continue
			id="$(frontmatter_value "$file" id)"
			title="$(frontmatter_value "$file" title)"
			respond_by="$(frontmatter_value "$file" respond_by)"
			ticket="$(frontmatter_value "$file" ticket)"
			printf '%-8s %s  %s%s%s\n' "$state" "$id" "$title" \
				"${respond_by:+  respond by $respond_by}" \
				"${ticket:+  [$ticket]}"
		done < <(decision_files_in_state "$state")
	done
}

cmd_decide_show() {
	local id="${1:-}"
	[[ -n "$id" ]] || die "decide show requires DEC-ID"
	local file
	file="$(find_decision_file "$id")" || die "decision not found: $id"
	cat "$file"
}

cmd_decide_record() {
	local id="${1:-}"
	shift || true
	[[ -n "$id" ]] || die "decide record requires DEC-ID"
	local choice="" by="" note="" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--choice)
			choice="$2"
			shift 2
			;;
		--by)
			by="$2"
			shift 2
			;;
		--note)
			note="$2"
			shift 2
			;;
		*) die "unknown decide record option: $arg" ;;
		esac
	done
	[[ -n "$choice" ]] || die "decide record requires --choice N"
	[[ -n "$by" ]] || die "decide record requires --by NAME; recording a decision is a human action"

	local file option_count
	file="$(find_decision_file "$id" open)" || die "open decision not found: $id"
	option_count="$(frontmatter_list_count "$file" options)"
	[[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= option_count)) ||
		die "--choice must be an option number between 1 and $option_count"

	local chosen_text i=1 item
	chosen_text=""
	while IFS= read -r item; do
		if ((i == choice)); then
			chosen_text="$item"
			break
		fi
		i=$((i + 1))
	done < <(frontmatter_list_items "$file" options)

	update_frontmatter_scalars "$file" \
		"status"$'\035'"decided"$'\034' \
		"chosen_option"$'\035'"$choice"$'\034' \
		"decided_by"$'\035'"$by"$'\034' \
		"decided_at"$'\035'"$(now_utc)"$'\034' \
		"updated"$'\035'"$(today_utc)"$'\034'
	{
		printf '\n## Outcome\n\n'
		printf 'Chosen: Option %s (%s) by %s at %s.\n' "$choice" "$chosen_text" "$by" "$(now_utc)"
		[[ -z "$note" ]] || printf '\nNote: %s\n' "$note"
	} >>"$file"

	mkdir -p "$ROOT/$DECISIONS_DECIDED_DIR"
	local dest="$ROOT/$DECISIONS_DECIDED_DIR/$(basename "$file")"
	mv "$file" "$dest"

	# Mirror into repo memory so future packets can cite the decision.
	if [[ -d "$ROOT/$MEMORY_DIR" ]]; then
		local memory_file="$ROOT/$MEMORY_DIR/decisions/$id-$(slugify "$(frontmatter_value "$dest" title)").md"
		mkdir -p "$ROOT/$MEMORY_DIR/decisions"
		{
			printf -- '---\n'
			printf 'id: MEM-%s\n' "$id"
			printf 'type: decision\n'
			printf 'status: active\n'
			printf 'source: %s\n' "${dest#"$ROOT"/}"
			printf 'created: %s\n' "$(today_utc)"
			printf -- '---\n\n'
			printf '# Decision %s: %s\n\n' "$id" "$(frontmatter_value "$dest" title)"
			printf 'Chosen: Option %s (%s), decided by %s.\n' "$choice" "$chosen_text" "$by"
			[[ -z "$note" ]] || printf '\n%s\n' "$note"
		} >"$memory_file"
		printf 'memory: %s\n' "${memory_file#"$ROOT"/}"
	fi
	printf 'decide record: %s -> %s\n' "$id" "${dest#"$ROOT"/}"
}

cmd_decide_lint() {
	local issues=0 file id respond_by default_option line
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		id="$(frontmatter_value "$file" id)"
		if [[ "$(frontmatter_list_count "$file" options)" -lt 2 ]]; then
			printf 'decide lint: %s has fewer than two options\n' "$id"
			issues=$((issues + 1))
		fi
		respond_by="$(frontmatter_value "$file" respond_by)"
		default_option="$(frontmatter_value "$file" default_option)"
		if [[ -n "$default_option" && -z "$respond_by" ]]; then
			printf 'decide lint: %s declares a default option without a respond_by date\n' "$id"
			issues=$((issues + 1))
		fi
		while IFS= read -r line; do
			[[ -n "$line" ]] || continue
			printf 'decide lint: %s yaml safety: %s\n' "$id" "$line"
			issues=$((issues + 1))
		done < <(frontmatter_yaml_issues "$file")
	done < <(decision_files_in_state open)
	if ((issues > 0)); then
		printf 'decide lint: %s issue(s)\n' "$issues"
		return 1
	fi
	printf 'decide lint: ok\n'
}

cmd_decide() {
	local sub="${1:-}"
	shift || true
	case "$sub" in
	create)
		cmd_decide_create "$@"
		;;
	list)
		cmd_decide_list "$@"
		;;
	show)
		cmd_decide_show "$@"
		;;
	record)
		cmd_decide_record "$@"
		;;
	lint)
		cmd_decide_lint "$@"
		;;
	help | -h | --help | "")
		cat <<'USAGE'
usage: palari decide SUBCOMMAND

  create DEC-ID TITLE --option TEXT --option TEXT [...]
         [--recommend N] [--default N] [--respond-by YYYY-MM-DD]
         [--ticket TICKET-ID] [--goal GOAL-ID] [--raised-by NAME]
  list                                 List open and decided decisions.
  show DEC-ID                          Print a decision file.
  record DEC-ID --choice N --by NAME [--note TEXT]
                                       Record the human outcome and archive it.
  lint                                 Check open decisions for completeness.

A decision is the structured artifact agents bring to the human: a question,
two or more options with tradeoffs, a recommendation, a respond-by date, and
an explicit default. Agents draft decisions; only a human records them.
Defaults may never include accept, merge, push, deploy, spend, or any other
human-gated action.
USAGE
		;;
	*) die "unknown decide command: $sub" ;;
	esac
}
