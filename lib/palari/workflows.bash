# shellcheck shell=bash
# shellcheck disable=SC2153 # ROOT and workflow globals are sourced from core.bash.
#
# Workflows are company/process planning artifacts above tickets. They do not
# execute work or grant authority; they make the work plan and human governance
# surface inspectable before tickets are created beneath it.

valid_workflow_id() {
	local id="$1"
	[[ "$id" =~ ^WF-[0-9]{4}$ ]]
}

workflow_dir_for_state() {
	case "$1" in
	proposed) printf '%s\n' "$WORKFLOWS_PROPOSED_DIR" ;;
	active) printf '%s\n' "$WORKFLOWS_ACTIVE_DIR" ;;
	closed) printf '%s\n' "$WORKFLOWS_CLOSED_DIR" ;;
	*) return 1 ;;
	esac
}

workflow_files_in_state() {
	local state="$1" dir
	dir="$(workflow_dir_for_state "$state")" || return 1
	[[ -d "$ROOT/$dir" ]] || return 0
	find "$ROOT/$dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | sort
}

all_workflow_files() {
	local state
	for state in proposed active closed; do
		workflow_files_in_state "$state"
	done
}

find_workflow_file() {
	local id="$1"
	local state="${2:-any}"
	local states file s
	if [[ "$state" == "any" ]]; then
		states="proposed active closed"
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
		done < <(workflow_files_in_state "$s")
	done
	return 1
}

workflow_validate_work_unit() {
	local workflow_id="$1" item="$2" errors_var="$3"
	local unit_id kind risk title extra
	IFS='|' read -r unit_id kind risk title extra <<<"$item"
	if [[ -z "$unit_id" || -z "$kind" || -z "$risk" || -z "$title" || -n "$extra" ]]; then
		printf 'workflow lint: %s work_units entry must be id|kind|risk|title: %s\n' "$workflow_id" "$item"
		printf -v "$errors_var" '%s' "$((${!errors_var} + 1))"
		return
	fi
	if [[ ! "$unit_id" =~ ^WU-[0-9]{4}$ ]]; then
		printf 'workflow lint: %s invalid work unit id: %s\n' "$workflow_id" "$unit_id"
		printf -v "$errors_var" '%s' "$((${!errors_var} + 1))"
	fi
	if ! in_words "$risk" "$VALID_RISKS"; then
		printf 'workflow lint: %s work unit %s invalid risk: %s\n' "$workflow_id" "$unit_id" "$risk"
		printf -v "$errors_var" '%s' "$((${!errors_var} + 1))"
	fi
}

workflow_validate_decision() {
	local workflow_id="$1" item="$2" errors_var="$3"
	local risk kind skills title rest
	IFS='|' read -r risk kind skills title rest <<<"$item"
	if [[ -z "$risk" || -z "$kind" || -z "$skills" || -z "$title" ]]; then
		printf 'workflow lint: %s expected_decisions entry must be risk|kind|skills|title: %s\n' "$workflow_id" "$item"
		printf -v "$errors_var" '%s' "$((${!errors_var} + 1))"
		return
	fi
	if ! in_words "$risk" "$VALID_RISKS"; then
		printf 'workflow lint: %s expected decision invalid risk: %s\n' "$workflow_id" "$risk"
		printf -v "$errors_var" '%s' "$((${!errors_var} + 1))"
	fi
	if [[ "$risk" =~ ^R[345]$ && ! "$skills" =~ [A-Za-z0-9_./-]+:L[1-5] ]]; then
		printf 'workflow lint: %s %s expected decision lacks skill:Lx coverage: %s\n' "$workflow_id" "$risk" "$item"
		printf -v "$errors_var" '%s' "$((${!errors_var} + 1))"
	fi
	: "$rest"
}

cmd_workflow_create() {
	local id="${1:-}" title="${2:-}"
	shift 2 || true
	[[ -n "$id" && -n "$title" ]] || die "workflow create requires WF-ID and title"
	valid_workflow_id "$id" || die "invalid workflow id: $id; use WF-0001"
	! find_workflow_file "$id" >/dev/null 2>&1 || die "workflow id already in use: $id"

	local goal="" owner="" risk_ceiling="R4" autonomy_target="conditional" success_metric="" target="" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--goal)
			goal="$2"
			shift 2
			;;
		--owner)
			owner="$2"
			shift 2
			;;
		--risk-ceiling)
			risk_ceiling="$2"
			shift 2
			;;
		--autonomy-target)
			autonomy_target="$2"
			shift 2
			;;
		--success-metric)
			success_metric="$2"
			shift 2
			;;
		--target)
			target="$2"
			shift 2
			;;
		--proposed)
			shift
			;;
		*) die "unknown workflow create option: $arg" ;;
		esac
	done
	[[ -n "$goal" ]] || die "workflow create requires --goal GOAL-ID"
	[[ -n "$owner" ]] || die "workflow create requires --owner NAME"
	valid_goal_id "$goal" || die "invalid goal id: $goal; use GOAL-0001"
	find_goal_file "$goal" >/dev/null || die "goal not found: $goal"
	in_words "$risk_ceiling" "$VALID_RISKS" || die "invalid risk ceiling: $risk_ceiling"

	local dir slug file created
	dir="$WORKFLOWS_PROPOSED_DIR"
	mkdir -p "$ROOT/$dir"
	slug="$(slugify "$title")"
	file="$ROOT/$dir/$id-$slug.md"
	created="$(today_utc)"
	{
		printf -- '---\n'
		printf 'id: %s\n' "$id"
		printf 'title: %s\n' "$title"
		printf 'status: proposed\n'
		printf 'goal: %s\n' "$goal"
		printf 'owner: %s\n' "$owner"
		printf 'risk_ceiling: %s\n' "$risk_ceiling"
		printf 'autonomy_target: %s\n' "$autonomy_target"
		printf 'success_metric: %s\n' "$success_metric"
		printf 'target: %s\n' "$target"
		printf 'guardrails:\n'
		printf 'work_units:\n'
		printf 'expected_decisions:\n'
		write_yaml_list allowed_modes research draft branch_pr staging
		write_yaml_list forbidden_modes production_write_without_human customer_send_without_human billing_change
		printf 'adopted_by:\n'
		printf 'adopted_at:\n'
		printf 'closed_as:\n'
		printf 'closed_by:\n'
		printf 'closed_at:\n'
		printf 'created: %s\n' "$created"
		printf 'updated: %s\n' "$created"
		printf -- '---\n\n'
		printf '# %s %s\n\n' "$id" "$title"
		printf '## Objective\n\nState the workflow objective in business terms.\n\n'
		printf '## Guardrails\n\nList constraints the workflow must respect.\n\n'
		printf '## AI Execution Plan\n\nDescribe the work AI may prepare.\n\n'
		printf '## Human Governance Plan\n\nDescribe the human decisions, skills, and gates required.\n\n'
		printf '## Burden Reduction Ideas\n\nList ways evidence, policy, or playbooks could reduce Human Governance Load.\n\n'
		printf '## Outcome Notes\n\nRecord what happened after the workflow runs.\n'
	} >"$file"
	printf 'workflow create: %s\n' "${file#"$ROOT"/}"
	printf 'adopt when a human is ready: ./bin/palari workflow adopt %s --by NAME\n' "$id"
}

cmd_workflow_list() {
	local state file id title goal owner
	for state in proposed active closed; do
		while IFS= read -r file; do
			[[ -n "$file" ]] || continue
			id="$(frontmatter_value "$file" id)"
			title="$(frontmatter_value "$file" title)"
			goal="$(frontmatter_value "$file" goal)"
			owner="$(frontmatter_value "$file" owner)"
			printf '%-8s %s  %s  goal:%s owner:%s\n' "$state" "$id" "$title" "${goal:-missing}" "${owner:-missing}"
		done < <(workflow_files_in_state "$state")
	done
}

cmd_workflow_show() {
	local id="${1:-}"
	[[ -n "$id" ]] || die "workflow show requires WF-ID"
	local file
	file="$(find_workflow_file "$id")" || die "workflow not found: $id"
	printf 'Workflow: %s - %s\n' "$id" "$(frontmatter_value "$file" title)"
	printf 'status: %s\n' "$(frontmatter_value "$file" status)"
	printf 'goal: %s\n' "$(frontmatter_value "$file" goal)"
	printf 'owner: %s\n' "$(frontmatter_value "$file" owner)"
	printf 'risk_ceiling: %s\n' "$(frontmatter_value "$file" risk_ceiling)"
	printf 'autonomy_target: %s\n' "$(frontmatter_value "$file" autonomy_target)"
	printf 'file: %s\n' "${file#"$ROOT"/}"
	print_frontmatter_list_block "work units" "$file" work_units
	print_frontmatter_list_block "expected decisions" "$file" expected_decisions
}

cmd_workflow_lint() {
	local only="${1:-}" errors=0 state file id status goal risk item yaml_issue
	local -a files=()
	if [[ -n "$only" ]]; then
		file="$(find_workflow_file "$only")" || die "workflow not found: $only"
		files+=("$file")
	else
		while IFS= read -r file; do [[ -n "$file" ]] && files+=("$file"); done < <(all_workflow_files)
	fi
	for file in "${files[@]}"; do
		id="$(frontmatter_value "$file" id)"
		status="$(frontmatter_value "$file" status)"
		goal="$(frontmatter_value "$file" goal)"
		risk="$(frontmatter_value "$file" risk_ceiling)"
		if ! valid_workflow_id "$id"; then
			printf 'workflow lint: invalid id in %s\n' "${file#"$ROOT"/}"
			errors=$((errors + 1))
		fi
		case "$status" in proposed | active | closed) ;; *)
			printf 'workflow lint: %s invalid status: %s\n' "${id:-missing}" "$status"
			errors=$((errors + 1))
			;;
		esac
		for state in proposed active closed; do
			case "${file#"$ROOT"/}" in
			"$(workflow_dir_for_state "$state")"/*)
				if [[ "$status" != "$state" ]]; then
					printf 'workflow lint: %s status %s does not match directory %s\n' "$id" "$status" "$state"
					errors=$((errors + 1))
				fi
				;;
			esac
		done
		if [[ -z "$goal" ]]; then
			printf 'workflow lint: %s missing goal\n' "$id"
			errors=$((errors + 1))
		elif ! find_goal_file "$goal" >/dev/null 2>&1; then
			printf 'workflow lint: %s references unknown goal: %s\n' "$id" "$goal"
			errors=$((errors + 1))
		fi
		if [[ -z "$risk" ]] || ! in_words "$risk" "$VALID_RISKS"; then
			printf 'workflow lint: %s invalid risk_ceiling: %s\n' "$id" "${risk:-missing}"
			errors=$((errors + 1))
		fi
		while IFS= read -r item; do
			[[ -n "$item" ]] || continue
			workflow_validate_work_unit "$id" "$item" errors
		done < <(frontmatter_list_items "$file" work_units)
		while IFS= read -r item; do
			[[ -n "$item" ]] || continue
			workflow_validate_decision "$id" "$item" errors
		done < <(frontmatter_list_items "$file" expected_decisions)
		while IFS= read -r yaml_issue; do
			[[ -n "$yaml_issue" ]] || continue
			printf 'workflow lint: %s yaml safety: %s\n' "$id" "$yaml_issue"
			errors=$((errors + 1))
		done < <(frontmatter_yaml_issues "$file")
	done
	((errors == 0)) || return 1
	if [[ -n "$only" ]]; then
		printf 'workflow lint: ok for %s\n' "$only"
	else
		printf 'workflow lint: ok\n'
	fi
}

cmd_workflow_adopt() {
	local id="${1:-}"
	shift || true
	[[ -n "$id" ]] || die "workflow adopt requires WF-ID"
	local by="" arg
	while (($# > 0)); do
		case "$1" in
		--by)
			by="$2"
			shift 2
			;;
		*) die "unknown workflow adopt option: $1" ;;
		esac
	done
	[[ -n "$by" ]] || die "workflow adopt requires --by NAME"
	local file target
	file="$(find_workflow_file "$id" proposed)" || die "proposed workflow not found: $id"
	mkdir -p "$ROOT/$WORKFLOWS_ACTIVE_DIR"
	target="$ROOT/$WORKFLOWS_ACTIVE_DIR/$(basename "$file")"
	update_frontmatter_scalars "$file" \
		"status"$'\035'"active"$'\034' \
		"adopted_by"$'\035'"$by"$'\034' \
		"adopted_at"$'\035'"$(now_utc)"$'\034' \
		"updated"$'\035'"$(today_utc)"$'\034'
	mv "$file" "$target"
	printf 'workflow adopt: %s -> %s (by %s)\n' "$id" "${target#"$ROOT"/}" "$by"
}

cmd_workflow_close() {
	local id="${1:-}"
	shift || true
	[[ -n "$id" ]] || die "workflow close requires WF-ID"
	local by="" outcome="" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--by)
			by="$2"
			shift 2
			;;
		--status)
			outcome="$2"
			shift 2
			;;
		*) die "unknown workflow close option: $arg" ;;
		esac
	done
	[[ -n "$by" ]] || die "workflow close requires --by NAME"
	case "$outcome" in achieved | dropped) ;; *) die "workflow close requires --status achieved|dropped" ;; esac
	local file target
	file="$(find_workflow_file "$id" active)" || die "active workflow not found: $id"
	mkdir -p "$ROOT/$WORKFLOWS_CLOSED_DIR"
	target="$ROOT/$WORKFLOWS_CLOSED_DIR/$(basename "$file")"
	update_frontmatter_scalars "$file" \
		"status"$'\035'"closed"$'\034' \
		"closed_as"$'\035'"$outcome"$'\034' \
		"closed_by"$'\035'"$by"$'\034' \
		"closed_at"$'\035'"$(now_utc)"$'\034' \
		"updated"$'\035'"$(today_utc)"$'\034'
	mv "$file" "$target"
	printf 'workflow close: %s -> %s (%s by %s)\n' "$id" "${target#"$ROOT"/}" "$outcome" "$by"
}

cmd_workflow() {
	local sub="${1:-list}"
	shift || true
	case "$sub" in
	create) cmd_workflow_create "$@" ;;
	list | "") cmd_workflow_list "$@" ;;
	show) cmd_workflow_show "$@" ;;
	lint) cmd_workflow_lint "$@" ;;
	adopt) cmd_workflow_adopt "$@" ;;
	close) cmd_workflow_close "$@" ;;
	help | -h | --help)
		cat <<'USAGE'
usage: palari workflow create WF-ID TITLE --goal GOAL-ID --owner NAME [--proposed]
       palari workflow list
       palari workflow show WF-ID
       palari workflow lint [WF-ID]
       palari workflow adopt WF-ID --by NAME
       palari workflow close WF-ID --by NAME --status achieved|dropped
USAGE
		;;
	*) die "unknown workflow command: $sub" ;;
	esac
}
