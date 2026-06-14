# shellcheck shell=bash
# shellcheck disable=SC2153 # ROOT and policy globals are sourced from core.bash.
#
# Policies are simulation-only acceptance rules. They explain what would pass;
# they never accept tickets, move lifecycle state, merge, push, or deploy.

valid_policy_id() {
	local id="$1"
	[[ "$id" =~ ^POL-[A-Z0-9][A-Z0-9-]*$ ]]
}

policy_dir_for_state() {
	case "$1" in
	proposed) printf '%s\n' "$POLICIES_PROPOSED_DIR" ;;
	active) printf '%s\n' "$POLICIES_ACTIVE_DIR" ;;
	revoked) printf '%s\n' "$POLICIES_REVOKED_DIR" ;;
	*) return 1 ;;
	esac
}

policy_files_in_state() {
	local state="$1" dir
	dir="$(policy_dir_for_state "$state")" || return 1
	[[ -d "$ROOT/$dir" ]] || return 0
	find "$ROOT/$dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | sort
}

all_policy_files() {
	local state
	for state in proposed active revoked; do
		policy_files_in_state "$state"
	done
}

find_policy_file() {
	local id="$1" state="${2:-any}"
	local states file s
	if [[ "$state" == "any" ]]; then
		states="proposed active revoked"
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
		done < <(policy_files_in_state "$s")
	done
	return 1
}

policy_condition_known() {
	local condition="$1"
	[[ "$condition" == "no_open_decisions" ]] && return 0
	[[ "$condition" == "scope_check_passed" ]] && return 0
	[[ "$condition" =~ ^risk\<\=R[0-5]$ ]] && return 0
	[[ "$condition" =~ ^evidence_score\>\=[0-9]+$ ]] && return 0
	return 1
}

cmd_policy_create() {
	local id="${1:-}" title="${2:-}"
	shift 2 || true
	[[ -n "$id" && -n "$title" ]] || die "policy create requires POL-ID and title"
	valid_policy_id "$id" || die "invalid policy id: $id; use POL-NAME or POL-0001"
	! find_policy_file "$id" >/dev/null 2>&1 || die "policy id already in use: $id"

	local risk_max="" mode="" arg
	local -a conditions=()
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--risk-max)
			risk_max="$2"
			shift 2
			;;
		--mode)
			mode="$2"
			shift 2
			;;
		--condition)
			conditions+=("$2")
			shift 2
			;;
		--proposed)
			shift
			;;
		*) die "unknown policy create option: $arg" ;;
		esac
	done
	[[ -n "$risk_max" ]] || die "policy create requires --risk-max RISK"
	[[ -n "$mode" ]] || die "policy create requires --mode simulation"
	in_words "$risk_max" "$VALID_RISKS" || die "invalid risk max: $risk_max"
	[[ "$risk_max" != "R5" ]] || die "policy risk-max R5 is forbidden; R5 is never policy-eligible"
	[[ "$mode" == "simulation" ]] || die "policy mode must be simulation"
	if ((${#conditions[@]} == 0)); then
		conditions=("risk<=$risk_max" "evidence_score>=95" "scope_check_passed" "no_open_decisions")
	fi

	local condition
	for condition in "${conditions[@]}"; do
		[[ -n "$condition" ]] || die "policy condition cannot be empty"
	done

	local dir slug file created
	dir="$POLICIES_PROPOSED_DIR"
	mkdir -p "$ROOT/$dir"
	slug="$(slugify "$title")"
	file="$ROOT/$dir/$id-$slug.md"
	created="$(today_utc)"
	{
		printf -- '---\n'
		printf 'id: %s\n' "$id"
		printf 'title: %s\n' "$title"
		printf 'status: proposed\n'
		printf 'mode: simulation\n'
		printf 'risk_max: %s\n' "$risk_max"
		write_yaml_list conditions "${conditions[@]}"
		printf 'created_by:\n'
		printf 'created: %s\n' "$created"
		printf 'updated: %s\n' "$created"
		printf -- '---\n\n'
		printf '# %s %s\n\n' "$id" "$title"
		printf '## Purpose\n\nDescribe the repeated low-risk decision this policy simulates.\n\n'
		printf '## Boundary\n\nDescribe what this policy must never accept.\n\n'
		printf '## Conditions\n\nList the evidence and ticket-state conditions required.\n\n'
		printf '## Simulation Notes\n\nRecord what the simulator showed before any future activation work.\n'
	} >"$file"
	printf 'policy create: %s\n' "${file#"$ROOT"/}"
	printf 'note: policy mode is simulation-only; no command can accept by policy yet.\n'
}

cmd_policy_list() {
	local state file id title mode risk
	for state in proposed active revoked; do
		while IFS= read -r file; do
			[[ -n "$file" ]] || continue
			id="$(frontmatter_value "$file" id)"
			title="$(frontmatter_value "$file" title)"
			mode="$(frontmatter_value "$file" mode)"
			risk="$(frontmatter_value "$file" risk_max)"
			printf '%-8s %s  %s  mode:%s max:%s\n' "$state" "$id" "$title" "${mode:-missing}" "${risk:-missing}"
		done < <(policy_files_in_state "$state")
	done
}

cmd_policy_show() {
	local id="${1:-}"
	[[ -n "$id" ]] || die "policy show requires POL-ID"
	local file
	file="$(find_policy_file "$id")" || die "policy not found: $id"
	printf 'Policy: %s - %s\n' "$id" "$(frontmatter_value "$file" title)"
	printf 'status: %s\n' "$(frontmatter_value "$file" status)"
	printf 'mode: %s\n' "$(frontmatter_value "$file" mode)"
	printf 'risk_max: %s\n' "$(frontmatter_value "$file" risk_max)"
	printf 'file: %s\n' "${file#"$ROOT"/}"
	print_frontmatter_list_block "conditions" "$file" conditions
	printf 'note: simulation only; no policy command can accept tickets.\n'
}

cmd_policy_lint() {
	local only="${1:-}" errors=0 file state id status mode risk condition yaml_issue
	local -a files=()
	if [[ -n "$only" ]]; then
		file="$(find_policy_file "$only")" || die "policy not found: $only"
		files+=("$file")
	else
		while IFS= read -r file; do [[ -n "$file" ]] && files+=("$file"); done < <(all_policy_files)
	fi
	for file in "${files[@]}"; do
		id="$(frontmatter_value "$file" id)"
		status="$(frontmatter_value "$file" status)"
		mode="$(frontmatter_value "$file" mode)"
		risk="$(frontmatter_value "$file" risk_max)"
		if ! valid_policy_id "$id"; then
			printf 'policy lint: invalid id in %s\n' "${file#"$ROOT"/}"
			errors=$((errors + 1))
		fi
		case "$status" in proposed | active | revoked) ;; *)
			printf 'policy lint: %s invalid status: %s\n' "${id:-missing}" "$status"
			errors=$((errors + 1))
			;;
		esac
		for state in proposed active revoked; do
			case "${file#"$ROOT"/}" in
			"$(policy_dir_for_state "$state")"/*)
				if [[ "$status" != "$state" ]]; then
					printf 'policy lint: %s status %s does not match directory %s\n' "$id" "$status" "$state"
					errors=$((errors + 1))
				fi
				;;
			esac
		done
		if [[ "$mode" != "simulation" ]]; then
			printf 'policy lint: %s mode must be simulation\n' "$id"
			errors=$((errors + 1))
		fi
		if [[ -z "$risk" ]] || ! in_words "$risk" "$VALID_RISKS"; then
			printf 'policy lint: %s invalid risk_max: %s\n' "$id" "${risk:-missing}"
			errors=$((errors + 1))
		elif [[ "$risk" == "R5" ]]; then
			printf 'policy lint: %s risk_max R5 is forbidden; R5 is never policy-eligible\n' "$id"
			errors=$((errors + 1))
		fi
		if [[ "$(frontmatter_list_count "$file" conditions)" == "0" ]]; then
			printf 'policy lint: %s needs at least one condition\n' "$id"
			errors=$((errors + 1))
		fi
		while IFS= read -r condition; do
			[[ -n "$condition" ]] || continue
			if ! policy_condition_known "$condition"; then
				:
			fi
		done < <(frontmatter_list_items "$file" conditions)
		while IFS= read -r yaml_issue; do
			[[ -n "$yaml_issue" ]] || continue
			printf 'policy lint: %s yaml safety: %s\n' "$id" "$yaml_issue"
			errors=$((errors + 1))
		done < <(frontmatter_yaml_issues "$file")
	done
	((errors == 0)) || return 1
	if [[ -n "$only" ]]; then
		printf 'policy lint: ok for %s\n' "$only"
	else
		printf 'policy lint: ok\n'
	fi
}

cmd_policy_simulate() {
	local ticket="${1:-}"
	shift || true
	[[ -n "$ticket" ]] || die "policy simulate requires TICKET-ID"
	local json="false" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--json)
			json="true"
			shift
			;;
		*) die "unknown policy simulate option: $arg" ;;
		esac
	done

	local args=(
		--root "$ROOT"
		--ticket "$ticket"
		--tickets-open-dir "$OPEN_DIR"
		--tickets-closed-dir "$CLOSED_DIR"
		--policies-proposed-dir "$POLICIES_PROPOSED_DIR"
		--policies-active-dir "$POLICIES_ACTIVE_DIR"
		--policies-revoked-dir "$POLICIES_REVOKED_DIR"
		--evidence-dir "$EVIDENCE_DIR"
		--reports-dir "$REPORTS_DIR"
		--human-reports-dir "$HUMAN_REPORTS_DIR"
		--decisions-open-dir "$DECISIONS_OPEN_DIR"
	)
	if [[ "$json" == "true" ]]; then
		args+=(--json)
	fi
	python3 -B "$ROOT/adapters/planning/policy_simulation.py" "${args[@]}"
}

cmd_policy() {
	local sub="${1:-list}"
	shift || true
	case "$sub" in
	create) cmd_policy_create "$@" ;;
	list | "") cmd_policy_list "$@" ;;
	show) cmd_policy_show "$@" ;;
	lint) cmd_policy_lint "$@" ;;
	simulate) cmd_policy_simulate "$@" ;;
	help | -h | --help)
		cat <<'USAGE'
usage: palari policy create POL-ID TITLE --risk-max RISK --mode simulation [--condition CONDITION]
       palari policy list
       palari policy show POL-ID
       palari policy lint [POL-ID]
       palari policy simulate TICKET-ID [--json]

Policy commands are simulation-only. They never accept tickets or move state.
USAGE
		;;
	*) die "unknown policy command: $sub" ;;
	esac
}
