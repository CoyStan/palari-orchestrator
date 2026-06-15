# shellcheck shell=bash
# shellcheck disable=SC2153 # ROOT and outcome globals are sourced from core.bash.
#
# Outcomes record what happened after governed work. They do not accept work or
# prove impact unless evidence is linked.

valid_outcome_id() {
	local id="$1"
	[[ "$id" =~ ^OUT-[A-Z0-9][A-Z0-9-]*$ ]]
}

valid_optional_decimal() {
	local value="$1"
	[[ -z "$value" || "$value" =~ ^-?[0-9]+([.][0-9]+)?$ ]]
}

valid_optional_nonnegative_int() {
	local value="$1"
	[[ -z "$value" || "$value" =~ ^[0-9]+$ ]]
}

valid_optional_bool() {
	local value="$1"
	[[ -z "$value" || "$value" == "true" || "$value" == "false" ]]
}

outcome_dir_for_lifecycle() {
	case "$1" in
	open) printf '%s\n' "$OUTCOMES_OPEN_DIR" ;;
	recorded) printf '%s\n' "$OUTCOMES_RECORDED_DIR" ;;
	*) return 1 ;;
	esac
}

outcome_files_in_lifecycle() {
	local lifecycle="$1" dir
	dir="$(outcome_dir_for_lifecycle "$lifecycle")" || return 1
	[[ -d "$ROOT/$dir" ]] || return 0
	find "$ROOT/$dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | sort
}

all_outcome_files() {
	local lifecycle
	for lifecycle in open recorded; do
		outcome_files_in_lifecycle "$lifecycle"
	done
}

find_outcome_file() {
	local id="$1" lifecycle="${2:-any}"
	local lifecycles file state
	if [[ "$lifecycle" == "any" ]]; then
		lifecycles="open recorded"
	else
		lifecycles="$lifecycle"
	fi
	for state in $lifecycles; do
		while IFS= read -r file; do
			[[ -n "$file" ]] || continue
			[[ "$(frontmatter_value "$file" id)" == "$id" ]] && {
				printf '%s\n' "$file"
				return 0
			}
		done < <(outcome_files_in_lifecycle "$state")
	done
	return 1
}

cmd_outcome_create() {
	local id="${1:-}"
	shift || true
	[[ -n "$id" ]] || die "outcome create requires OUT-ID"
	valid_outcome_id "$id" || die "invalid outcome id: $id; use OUT-0001"
	! find_outcome_file "$id" >/dev/null 2>&1 || die "outcome id already in use: $id"

	local workflow="" status="" goal="" ticket="" decision="" title="" arg
	local -a evidence=()
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--workflow)
			workflow="$2"
			shift 2
			;;
		--status)
			status="$2"
			shift 2
			;;
		--goal)
			goal="$2"
			shift 2
			;;
		--ticket)
			ticket="$2"
			shift 2
			;;
		--decision)
			decision="$2"
			shift 2
			;;
		--evidence)
			evidence+=("$2")
			shift 2
			;;
		--title)
			title="$2"
			shift 2
			;;
		*) die "unknown outcome create option: $arg" ;;
		esac
	done
	[[ -n "$workflow" ]] || die "outcome create requires --workflow WF-ID"
	[[ -n "$status" ]] || die "outcome create requires --status observed|pending|invalidated"
	case "$status" in observed | pending | invalidated) ;; *) die "outcome status must be observed, pending, or invalidated" ;; esac
	find_workflow_file "$workflow" >/dev/null || die "workflow not found: $workflow"
	[[ -z "$goal" ]] || find_goal_file "$goal" >/dev/null || die "goal not found: $goal"
	[[ -z "$ticket" ]] || find_ticket_file "$ticket" >/dev/null || die "ticket not found: $ticket"
	[[ -z "$decision" ]] || find_decision_file "$decision" >/dev/null || die "decision not found: $decision"
	[[ -n "$title" ]] || title="Outcome for $workflow"

	local evidence_path
	for evidence_path in "${evidence[@]}"; do
		[[ -e "$ROOT/$evidence_path" ]] || die "evidence path not found: $evidence_path"
	done

	local dir slug file created
	dir="$OUTCOMES_OPEN_DIR"
	mkdir -p "$ROOT/$dir"
	slug="$(slugify "$title")"
	file="$ROOT/$dir/$id-$slug.md"
	created="$(today_utc)"
	{
		printf -- '---\n'
		printf 'id: %s\n' "$id"
		printf 'title: %s\n' "$title"
		printf 'status: %s\n' "$status"
		printf 'lifecycle: open\n'
		printf 'workflow: %s\n' "$workflow"
		printf 'goal: %s\n' "$goal"
		printf 'ticket: %s\n' "$ticket"
		printf 'decision: %s\n' "$decision"
		if ((${#evidence[@]} > 0)); then
			write_yaml_list linked_evidence "${evidence[@]}"
		else
			printf 'linked_evidence:\n'
		fi
		printf 'metric_name:\n'
		printf 'metric_before:\n'
		printf 'metric_after:\n'
		printf 'metric_delta:\n'
		printf 'risk_predicted:\n'
		printf 'risk_actual:\n'
		printf 'hgl_predicted:\n'
		printf 'hgl_actual:\n'
		printf 'human_decisions_predicted:\n'
		printf 'human_decisions_actual:\n'
		printf 'review_outcome:\n'
		printf 'rollback_used: false\n'
		printf 'policy_candidate: false\n'
		printf 'notes:\n'
		printf 'recorded_by:\n'
		printf 'recorded_at:\n'
		printf 'created: %s\n' "$created"
		printf 'updated: %s\n' "$created"
		printf -- '---\n\n'
		printf '# %s %s\n\n' "$id" "$title"
		printf '## Summary\n\nDescribe what happened and what changed.\n\n'
		printf '## Evidence\n\nLink evidence. Outcomes do not prove impact unless evidence is linked.\n\n'
		printf '## Policy / HGL Notes\n\nRecord whether this outcome should inform future policies or burden estimates.\n'
	} >"$file"
	printf 'outcome create: %s\n' "${file#"$ROOT"/}"
	printf 'record when reviewed: ./bin/palari outcome record %s --by NAME\n' "$id"
}

cmd_outcome_list() {
	local workflow_filter="" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--workflow)
			workflow_filter="$2"
			shift 2
			;;
		*) die "unknown outcome list option: $arg" ;;
		esac
	done
	local lifecycle file id title status workflow
	for lifecycle in open recorded; do
		while IFS= read -r file; do
			[[ -n "$file" ]] || continue
			workflow="$(frontmatter_value "$file" workflow)"
			[[ -z "$workflow_filter" || "$workflow" == "$workflow_filter" ]] || continue
			id="$(frontmatter_value "$file" id)"
			title="$(frontmatter_value "$file" title)"
			status="$(frontmatter_value "$file" status)"
			printf '%-8s %s  %s  status:%s workflow:%s\n' "$lifecycle" "$id" "$title" "${status:-missing}" "${workflow:-missing}"
		done < <(outcome_files_in_lifecycle "$lifecycle")
	done
}

cmd_outcome_show() {
	local id="${1:-}"
	[[ -n "$id" ]] || die "outcome show requires OUT-ID"
	local file
	file="$(find_outcome_file "$id")" || die "outcome not found: $id"
	cat "$file"
}

cmd_outcome_lint() {
	local errors=0 file id status lifecycle workflow goal ticket decision item yaml_issue value
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		id="$(frontmatter_value "$file" id)"
		status="$(frontmatter_value "$file" status)"
		lifecycle="$(frontmatter_value "$file" lifecycle)"
		workflow="$(frontmatter_value "$file" workflow)"
		goal="$(frontmatter_value "$file" goal)"
		ticket="$(frontmatter_value "$file" ticket)"
		decision="$(frontmatter_value "$file" decision)"
		if ! valid_outcome_id "$id"; then
			printf 'outcome lint: invalid id in %s\n' "${file#"$ROOT"/}"
			errors=$((errors + 1))
		fi
		case "$status" in observed | pending | invalidated) ;; *)
			printf 'outcome lint: %s invalid status: %s\n' "$id" "${status:-missing}"
			errors=$((errors + 1))
			;;
		esac
		case "$lifecycle" in open | recorded) ;; *)
			printf 'outcome lint: %s invalid lifecycle: %s\n' "$id" "${lifecycle:-missing}"
			errors=$((errors + 1))
			;;
		esac
		case "${file#"$ROOT"/}" in
		"$OUTCOMES_OPEN_DIR"/*)
			[[ "$lifecycle" == "open" ]] || {
				printf 'outcome lint: %s lifecycle %s does not match open directory\n' "$id" "$lifecycle"
				errors=$((errors + 1))
			}
			;;
		"$OUTCOMES_RECORDED_DIR"/*)
			[[ "$lifecycle" == "recorded" ]] || {
				printf 'outcome lint: %s lifecycle %s does not match recorded directory\n' "$id" "$lifecycle"
				errors=$((errors + 1))
			}
			;;
		esac
		[[ -n "$workflow" ]] && find_workflow_file "$workflow" >/dev/null || {
			printf 'outcome lint: %s references missing workflow: %s\n' "$id" "${workflow:-missing}"
			errors=$((errors + 1))
		}
		[[ -z "$goal" ]] || find_goal_file "$goal" >/dev/null || {
			printf 'outcome lint: %s references missing goal: %s\n' "$id" "$goal"
			errors=$((errors + 1))
		}
		[[ -z "$ticket" ]] || find_ticket_file "$ticket" >/dev/null || {
			printf 'outcome lint: %s references missing ticket: %s\n' "$id" "$ticket"
			errors=$((errors + 1))
		}
		[[ -z "$decision" ]] || find_decision_file "$decision" >/dev/null || {
			printf 'outcome lint: %s references missing decision: %s\n' "$id" "$decision"
			errors=$((errors + 1))
		}
		while IFS= read -r item; do
			[[ -n "$item" ]] || continue
			[[ -e "$ROOT/$item" ]] || {
				printf 'outcome lint: %s missing linked evidence: %s\n' "$id" "$item"
				errors=$((errors + 1))
			}
		done < <(frontmatter_list_items "$file" linked_evidence)
		for value in risk_predicted risk_actual; do
			item="$(frontmatter_value "$file" "$value")"
			if [[ -n "$item" && ! " $VALID_RISKS " == *" $item "* ]]; then
				printf 'outcome lint: %s %s invalid risk: %s\n' "$id" "$value" "$item"
				errors=$((errors + 1))
			fi
		done
		for value in hgl_predicted hgl_actual human_decisions_predicted human_decisions_actual; do
			item="$(frontmatter_value "$file" "$value")"
			if ! valid_optional_nonnegative_int "$item"; then
				printf 'outcome lint: %s %s must be a non-negative integer\n' "$id" "$value"
				errors=$((errors + 1))
			fi
		done
		for value in metric_before metric_after metric_delta; do
			item="$(frontmatter_value "$file" "$value")"
			if ! valid_optional_decimal "$item"; then
				printf 'outcome lint: %s %s must be a decimal number when present\n' "$id" "$value"
				errors=$((errors + 1))
			fi
		done
		item="$(frontmatter_value "$file" review_outcome)"
		case "$item" in "" | passed | failed | overridden | uncertain) ;; *)
			printf 'outcome lint: %s review_outcome invalid: %s\n' "$id" "$item"
			errors=$((errors + 1))
			;;
		esac
		for value in rollback_used policy_candidate; do
			item="$(frontmatter_value "$file" "$value")"
			if ! valid_optional_bool "$item"; then
				printf 'outcome lint: %s %s must be true or false when present\n' "$id" "$value"
				errors=$((errors + 1))
			fi
		done
		while IFS= read -r yaml_issue; do
			[[ -n "$yaml_issue" ]] || continue
			printf 'outcome lint: %s yaml safety: %s\n' "$id" "$yaml_issue"
			errors=$((errors + 1))
		done < <(frontmatter_yaml_issues "$file")
	done < <(all_outcome_files)
	((errors == 0)) || return 1
	printf 'outcome lint: ok\n'
}

cmd_outcome_record() {
	local id="${1:-}"
	shift || true
	[[ -n "$id" ]] || die "outcome record requires OUT-ID"
	local by="" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--by)
			by="$2"
			shift 2
			;;
		*) die "unknown outcome record option: $arg" ;;
		esac
	done
	[[ -n "$by" ]] || die "outcome record requires --by NAME"
	local file target
	file="$(find_outcome_file "$id" open)" || die "open outcome not found: $id"
	mkdir -p "$ROOT/$OUTCOMES_RECORDED_DIR"
	target="$ROOT/$OUTCOMES_RECORDED_DIR/$(basename "$file")"
	update_frontmatter_scalars "$file" \
		"lifecycle"$'\035'"recorded"$'\034' \
		"recorded_by"$'\035'"$by"$'\034' \
		"recorded_at"$'\035'"$(now_utc)"$'\034' \
		"updated"$'\035'"$(today_utc)"$'\034'
	mv "$file" "$target"
	printf 'outcome record: %s -> %s (by %s)\n' "$id" "${target#"$ROOT"/}" "$by"
}

cmd_outcome() {
	local sub="${1:-list}"
	shift || true
	case "$sub" in
	create) cmd_outcome_create "$@" ;;
	list | "") cmd_outcome_list "$@" ;;
	show) cmd_outcome_show "$@" ;;
	lint) cmd_outcome_lint "$@" ;;
	record) cmd_outcome_record "$@" ;;
	help | -h | --help)
		cat <<'USAGE'
usage: palari outcome create OUT-ID --workflow WF-ID --status observed|pending|invalidated [--ticket ID] [--decision DEC-ID] [--evidence PATH]
       palari outcome list [--workflow WF-ID]
       palari outcome show OUT-ID
       palari outcome lint
       palari outcome record OUT-ID --by NAME

Outcomes record observed results. They do not accept work or prove business
impact unless evidence is linked.
USAGE
		;;
	*) die "unknown outcome command: $sub" ;;
	esac
}
