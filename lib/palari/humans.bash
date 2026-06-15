# shellcheck shell=bash
# shellcheck disable=SC2153 # ROOT and human governance globals are sourced from core.bash.
#
# Human governance profiles model coverage for decisions. They do not create
# agent authority, employee surveillance, or execution permissions.

valid_human_id() {
	local id="$1"
	[[ "$id" =~ ^HUMAN-[A-Z0-9][A-Z0-9-]*$ ]]
}

human_dir_for_state() {
	case "$1" in
	proposed) printf '%s\n' "$HUMANS_PROPOSED_DIR" ;;
	active) printf '%s\n' "$HUMANS_ACTIVE_DIR" ;;
	revoked) printf '%s\n' "$HUMANS_REVOKED_DIR" ;;
	*) return 1 ;;
	esac
}

human_files_in_state() {
	local state="$1" dir
	dir="$(human_dir_for_state "$state")" || return 1
	[[ -d "$ROOT/$dir" ]] || return 0
	find "$ROOT/$dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | sort
}

all_human_files() {
	local state
	for state in proposed active revoked; do
		human_files_in_state "$state"
	done
}

find_human_file() {
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
		done < <(human_files_in_state "$s")
	done
	return 1
}

valid_skill_level_item() {
	local item="$1"
	[[ "$item" =~ ^[A-Za-z0-9_./-]+:L[1-5]$ ]]
}

valid_nonnegative_int() {
	local value="$1"
	[[ "$value" =~ ^[0-9]+$ ]]
}

cmd_human_create() {
	local id="${1:-}" name="${2:-}"
	shift 2 || true
	[[ -n "$id" && -n "$name" ]] || die "human create requires HUMAN-ID and name"
	valid_human_id "$id" || die "invalid human id: $id; use HUMAN-ALICE or HUMAN-0001"
	! find_human_file "$id" >/dev/null 2>&1 || die "human id already in use: $id"

	local capacity_hgl="" authority_max_risk="R4" may_policy="false" arg
	local -a roles=() skills=() constraints=()
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--skill)
			skills+=("$2")
			shift 2
			;;
		--role)
			roles+=("$2")
			shift 2
			;;
		--capacity-hgl)
			capacity_hgl="$2"
			shift 2
			;;
		--authority-max-risk)
			authority_max_risk="$2"
			shift 2
			;;
		--may-approve-policy-changes)
			may_policy="true"
			shift
			;;
		--constraint)
			constraints+=("$2")
			shift 2
			;;
		--proposed)
			shift
			;;
		*) die "unknown human create option: $arg" ;;
		esac
	done
	((${#skills[@]} > 0)) || die "human create needs at least one --skill skill:Lx"
	((${#roles[@]} > 0)) || die "human create needs at least one --role ROLE"
	[[ -n "$capacity_hgl" ]] || die "human create requires --capacity-hgl N"
	valid_nonnegative_int "$capacity_hgl" || die "capacity-hgl must be a non-negative integer"
	in_words "$authority_max_risk" "$VALID_RISKS" || die "invalid authority max risk: $authority_max_risk"
	local item
	for item in "${skills[@]}"; do
		valid_skill_level_item "$item" || die "invalid skill level: $item; use skill:L1..L5"
	done

	local dir slug file created
	dir="$HUMANS_PROPOSED_DIR"
	mkdir -p "$ROOT/$dir"
	slug="$(slugify "$name")"
	file="$ROOT/$dir/$id-$slug.md"
	created="$(today_utc)"
	{
		printf -- '---\n'
		printf 'id: %s\n' "$id"
		printf 'name: %s\n' "$name"
		printf 'status: proposed\n'
		write_yaml_list roles "${roles[@]}"
		write_yaml_list skills "${skills[@]}"
		printf 'authority_max_risk: %s\n' "$authority_max_risk"
		printf 'may_approve_policy_changes: %s\n' "$may_policy"
		printf 'may_approve_production_rollout: false\n'
		printf 'may_approve_customer_send: false\n'
		printf 'weekly_hgl_budget: %s\n' "$capacity_hgl"
		printf 'current_weekly_hgl: 0\n'
		printf 'max_concurrent_r3: 6\n'
		printf 'current_open_r3: 0\n'
		printf 'max_concurrent_r4: 2\n'
		printf 'current_open_r4: 0\n'
		printf 'max_concurrent_r5: 1\n'
		printf 'current_open_r5: 0\n'
		printf 'capacity_weekly_hgl: %s\n' "$capacity_hgl"
		printf 'capacity_open_r3: 0\n'
		printf 'capacity_open_r4: 0\n'
		printf 'capacity_open_r5: 0\n'
		if ((${#constraints[@]} > 0)); then
			write_yaml_list constraints "${constraints[@]}"
		else
			printf 'constraints:\n'
		fi
		printf 'adopted_by:\n'
		printf 'adopted_at:\n'
		printf 'revoked_by:\n'
		printf 'revoked_at:\n'
		printf 'created: %s\n' "$created"
		printf 'updated: %s\n' "$created"
		printf -- '---\n\n'
		printf '# %s %s\n\n' "$id" "$name"
		printf '## Governance Roles\n\nDescribe the governance situations this human can cover.\n\n'
		printf '## Skills\n\nList skills and the evidence for each level.\n\n'
		printf '## Authority\n\nDescribe what this profile may approve and what it must escalate.\n\n'
		printf '## Capacity\n\nRecord approximate weekly Human Governance Load capacity.\n\n'
		printf '## Constraints\n\nRecord constraints such as no self-review.\n'
	} >"$file"
	printf 'human create: %s\n' "${file#"$ROOT"/}"
	printf 'adopt when a human approves the profile: ./bin/palari human adopt %s --by NAME\n' "$id"
}

cmd_human_list() {
	local state file id name risk
	for state in proposed active revoked; do
		while IFS= read -r file; do
			[[ -n "$file" ]] || continue
			id="$(frontmatter_value "$file" id)"
			name="$(frontmatter_value "$file" name)"
			risk="$(frontmatter_value "$file" authority_max_risk)"
			printf '%-8s %s  %s  max:%s\n' "$state" "$id" "$name" "${risk:-missing}"
		done < <(human_files_in_state "$state")
	done
}

cmd_human_show() {
	local id="${1:-}"
	[[ -n "$id" ]] || die "human show requires HUMAN-ID"
	local file weekly current
	file="$(find_human_file "$id")" || die "human not found: $id"
	weekly="$(frontmatter_value "$file" weekly_hgl_budget)"
	[[ -n "$weekly" ]] || weekly="$(frontmatter_value "$file" capacity_weekly_hgl)"
	current="$(frontmatter_value "$file" current_weekly_hgl)"
	[[ -n "$current" ]] || current="0"
	printf 'Human: %s - %s\n' "$id" "$(frontmatter_value "$file" name)"
	printf 'status: %s\n' "$(frontmatter_value "$file" status)"
	printf 'authority_max_risk: %s\n' "$(frontmatter_value "$file" authority_max_risk)"
	printf 'weekly_hgl_budget: %s\n' "$weekly"
	printf 'current_weekly_hgl: %s\n' "$current"
	printf 'file: %s\n' "${file#"$ROOT"/}"
	print_frontmatter_list_block "roles" "$file" roles
	print_frontmatter_list_block "skills" "$file" skills
}

cmd_human_lint() {
	local only="${1:-}" errors=0 file state id status risk item value current max budget
	local -a files=()
	if [[ -n "$only" ]]; then
		file="$(find_human_file "$only")" || die "human not found: $only"
		files+=("$file")
	else
		while IFS= read -r file; do [[ -n "$file" ]] && files+=("$file"); done < <(all_human_files)
	fi
	for file in "${files[@]}"; do
		id="$(frontmatter_value "$file" id)"
		status="$(frontmatter_value "$file" status)"
		risk="$(frontmatter_value "$file" authority_max_risk)"
		if ! valid_human_id "$id"; then
			printf 'human lint: invalid id in %s\n' "${file#"$ROOT"/}"
			errors=$((errors + 1))
		fi
		case "$status" in proposed | active | revoked) ;; *)
			printf 'human lint: %s invalid status: %s\n' "$id" "$status"
			errors=$((errors + 1))
			;;
		esac
		for state in proposed active revoked; do
			case "${file#"$ROOT"/}" in
			"$(human_dir_for_state "$state")"/*)
				if [[ "$status" != "$state" ]]; then
					printf 'human lint: %s status %s does not match directory %s\n' "$id" "$status" "$state"
					errors=$((errors + 1))
				fi
				;;
			esac
		done
		if [[ "$status" == "active" ]]; then
			if [[ "$(frontmatter_list_count "$file" roles)" == "0" ]]; then
				printf 'human lint: %s active profile needs at least one role\n' "$id"
				errors=$((errors + 1))
			fi
			if [[ "$(frontmatter_list_count "$file" skills)" == "0" ]]; then
				printf 'human lint: %s active profile needs at least one skill\n' "$id"
				errors=$((errors + 1))
			fi
		fi
		while IFS= read -r item; do
			[[ -n "$item" ]] || continue
			if ! valid_skill_level_item "$item"; then
				printf 'human lint: %s invalid skill level: %s\n' "$id" "$item"
				errors=$((errors + 1))
			fi
		done < <(frontmatter_list_items "$file" skills)
		if [[ -z "$risk" ]] || ! in_words "$risk" "$VALID_RISKS"; then
			printf 'human lint: %s invalid authority_max_risk: %s\n' "$id" "${risk:-missing}"
			errors=$((errors + 1))
		fi
		if [[ "$risk" == "R5" && "$(frontmatter_value "$file" may_approve_policy_changes)" != "true" ]]; then
			printf 'human lint: %s R5 authority requires may_approve_policy_changes: true\n' "$id"
			errors=$((errors + 1))
		fi
		for value in \
			weekly_hgl_budget current_weekly_hgl \
			max_concurrent_r3 current_open_r3 \
			max_concurrent_r4 current_open_r4 \
			max_concurrent_r5 current_open_r5 \
			capacity_weekly_hgl capacity_open_r3 capacity_open_r4 capacity_open_r5; do
			item="$(frontmatter_value "$file" "$value")"
			if [[ -n "$item" && ! "$item" =~ ^[0-9]+$ ]]; then
				printf 'human lint: %s %s must be a non-negative integer\n' "$id" "$value"
				errors=$((errors + 1))
			fi
		done
		budget="$(frontmatter_value "$file" weekly_hgl_budget)"
		[[ -n "$budget" ]] || budget="$(frontmatter_value "$file" capacity_weekly_hgl)"
		current="$(frontmatter_value "$file" current_weekly_hgl)"
		if [[ -n "$budget" && -n "$current" && "$budget" =~ ^[0-9]+$ && "$current" =~ ^[0-9]+$ && "$current" -gt "$budget" ]]; then
			printf 'human lint: %s current_weekly_hgl exceeds weekly_hgl_budget\n' "$id"
			errors=$((errors + 1))
		fi
		for value in r3 r4 r5; do
			current="$(frontmatter_value "$file" "current_open_$value")"
			max="$(frontmatter_value "$file" "max_concurrent_$value")"
			if [[ -n "$current" && -n "$max" && "$current" =~ ^[0-9]+$ && "$max" =~ ^[0-9]+$ && "$current" -gt "$max" ]]; then
				printf 'human lint: %s current_open_%s exceeds max_concurrent_%s\n' "$id" "$value" "$value"
				errors=$((errors + 1))
			fi
		done
		while IFS= read -r item; do
			[[ -n "$item" ]] || continue
			printf 'human lint: %s yaml safety: %s\n' "$id" "$item"
			errors=$((errors + 1))
		done < <(frontmatter_yaml_issues "$file")
	done
	((errors == 0)) || return 1
	if [[ -n "$only" ]]; then
		printf 'human lint: ok for %s\n' "$only"
	else
		printf 'human lint: ok\n'
	fi
}

cmd_human_adopt() {
	local id="${1:-}"
	shift || true
	[[ -n "$id" ]] || die "human adopt requires HUMAN-ID"
	local by="" arg
	while (($# > 0)); do
		case "$1" in
		--by)
			by="$2"
			shift 2
			;;
		*) die "unknown human adopt option: $1" ;;
		esac
	done
	[[ -n "$by" ]] || die "human adopt requires --by NAME"
	local file target
	file="$(find_human_file "$id" proposed)" || die "proposed human profile not found: $id"
	mkdir -p "$ROOT/$HUMANS_ACTIVE_DIR"
	target="$ROOT/$HUMANS_ACTIVE_DIR/$(basename "$file")"
	update_frontmatter_scalars "$file" \
		"status"$'\035'"active"$'\034' \
		"adopted_by"$'\035'"$by"$'\034' \
		"adopted_at"$'\035'"$(now_utc)"$'\034' \
		"updated"$'\035'"$(today_utc)"$'\034'
	mv "$file" "$target"
	printf 'human adopt: %s -> %s (by %s)\n' "$id" "${target#"$ROOT"/}" "$by"
}

cmd_human_revoke() {
	local id="${1:-}"
	shift || true
	[[ -n "$id" ]] || die "human revoke requires HUMAN-ID"
	local by="" arg
	while (($# > 0)); do
		case "$1" in
		--by)
			by="$2"
			shift 2
			;;
		*) die "unknown human revoke option: $1" ;;
		esac
	done
	[[ -n "$by" ]] || die "human revoke requires --by NAME"
	local file target
	file="$(find_human_file "$id" active)" || die "active human profile not found: $id"
	mkdir -p "$ROOT/$HUMANS_REVOKED_DIR"
	target="$ROOT/$HUMANS_REVOKED_DIR/$(basename "$file")"
	update_frontmatter_scalars "$file" \
		"status"$'\035'"revoked"$'\034' \
		"revoked_by"$'\035'"$by"$'\034' \
		"revoked_at"$'\035'"$(now_utc)"$'\034' \
		"updated"$'\035'"$(today_utc)"$'\034'
	mv "$file" "$target"
	printf 'human revoke: %s -> %s (by %s)\n' "$id" "${target#"$ROOT"/}" "$by"
}

cmd_human() {
	local sub="${1:-list}"
	shift || true
	case "$sub" in
	create) cmd_human_create "$@" ;;
	list | "") cmd_human_list "$@" ;;
	show) cmd_human_show "$@" ;;
	lint) cmd_human_lint "$@" ;;
	coverage) cmd_human_coverage "$@" ;;
	adopt) cmd_human_adopt "$@" ;;
	revoke) cmd_human_revoke "$@" ;;
	help | -h | --help)
		cat <<'USAGE'
usage: palari human create HUMAN-ID NAME --skill skill:Lx --role ROLE --capacity-hgl N [--proposed]
       palari human list
       palari human show HUMAN-ID
       palari human lint [HUMAN-ID]
       palari human coverage WF-ID [--json]
       palari human adopt HUMAN-ID --by NAME
       palari human revoke HUMAN-ID --by NAME
USAGE
		;;
	*) die "unknown human command: $sub" ;;
	esac
}
