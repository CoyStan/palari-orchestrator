ROLE_REQUIRED_FIELDS=(
	id title status parent_role tier allowed_paths forbidden_paths max_risk
	may_create_roles may_create_tickets may_execute_tickets may_review_tickets may_accept_tickets
	can_delegate_to must_escalate_when memory_tags issued_by accepted_by accepted_at created revoked_by revoked_at
)

valid_role_id() {
	local id="$1"
	[[ "$id" =~ ^ROLE-[A-Z0-9][A-Z0-9-]*$ ]]
}

ensure_role_dirs() {
	mkdir -p "$ROOT/$ROLES_ACTIVE_DIR" "$ROOT/$ROLES_PROPOSED_DIR" "$ROOT/$ROLES_REVOKED_DIR"
}

role_files_for_dir() {
	local dir="$1"
	[[ -d "$ROOT/$dir" ]] || return 0
	find "$ROOT/$dir" -maxdepth 1 -type f \( -name '*.md' -o -name '*.markdown' \) ! -name 'README.md' | sort
}

role_files() {
	role_files_for_dir "$ROLES_ACTIVE_DIR"
	role_files_for_dir "$ROLES_PROPOSED_DIR"
	role_files_for_dir "$ROLES_REVOKED_DIR"
}

active_role_files() {
	role_files_for_dir "$ROLES_ACTIVE_DIR"
}

role_dir_status() {
	local file="$1"
	case "${file#"$ROOT"/}" in
	"$ROLES_ACTIVE_DIR"/*) printf 'active\n' ;;
	"$ROLES_PROPOSED_DIR"/*) printf 'proposed\n' ;;
	"$ROLES_REVOKED_DIR"/*) printf 'revoked\n' ;;
	*) printf 'unknown\n' ;;
	esac
}

find_role_file() {
	local role="$1"
	local file id base
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		id="$(frontmatter_value "$file" id)"
		base="$(basename "$file")"
		if [[ "$id" == "$role" || "$base" == "$role" || "${base%.md}" == "$role" ]]; then
			printf '%s\n' "$file"
			return 0
		fi
	done < <(role_files)
	return 1
}

find_active_role_file() {
	local role="$1"
	local file id base
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		id="$(frontmatter_value "$file" id)"
		base="$(basename "$file")"
		if [[ "$id" == "$role" || "$base" == "$role" || "${base%.md}" == "$role" ]]; then
			printf '%s\n' "$file"
			return 0
		fi
	done < <(active_role_files)
	return 1
}

role_risk_rank() {
	case "$1" in
	R0) printf '0\n' ;;
	R1) printf '1\n' ;;
	R2) printf '2\n' ;;
	R3) printf '3\n' ;;
	R4) printf '4\n' ;;
	*) return 1 ;;
	esac
}

role_risk_lte() {
	local child="$1"
	local parent="$2"
	local child_rank parent_rank
	child_rank="$(role_risk_rank "$child")" || return 1
	parent_rank="$(role_risk_rank "$parent")" || return 1
	((child_rank <= parent_rank))
}

list_contains_value() {
	local wanted="$1"
	shift
	local item
	for item in "$@"; do
		[[ "$item" == "$wanted" ]] && return 0
	done
	return 1
}

pattern_is_prefix_glob() {
	[[ "$1" == */** ]]
}

role_pattern_prefix() {
	local pattern="${1%/**}"
	printf '%s\n' "${pattern#./}"
}

pattern_is_complex() {
	local pattern="${1#./}"
	[[ "$pattern" == "**" || "$pattern" == "**/*" ]] && return 1
	if pattern_is_prefix_glob "$pattern"; then
		pattern="${pattern%/**}"
	fi
	[[ "$pattern" == *"*"* || "$pattern" == *"?"* || "$pattern" == *"["* || "$pattern" == *"]"* ]]
}

path_pattern_contains() {
	local parent="${1#./}"
	local child="${2#./}"
	local parent_prefix child_prefix
	[[ "$parent" == "**" || "$parent" == "**/*" ]] && return 0
	if pattern_is_complex "$parent" || pattern_is_complex "$child"; then
		return 2
	fi
	if [[ "$parent" == "$child" ]]; then
		return 0
	fi
	if pattern_is_prefix_glob "$parent"; then
		parent_prefix="$(role_pattern_prefix "$parent")"
		if pattern_is_prefix_glob "$child"; then
			child_prefix="$(role_pattern_prefix "$child")"
			[[ "$child_prefix" == "$parent_prefix" || "$child_prefix" == "$parent_prefix/"* ]] && return 0
			return 1
		fi
		[[ "$child" == "$parent_prefix/"* ]] && return 0
		return 1
	fi
	return 1
}

path_contained_in_any() {
	local child="$1"
	shift
	local parent unknown="false" code
	for parent in "$@"; do
		[[ -n "$parent" ]] || continue
		if path_pattern_contains "$parent" "$child"; then
			return 0
		else
			code=$?
			[[ "$code" == "2" ]] && unknown="true"
		fi
	done
	[[ "$unknown" == "true" ]] && return 2
	return 1
}

child_pattern_forbidden_by_parent() {
	local child="$1"
	local forbidden="$2"
	if path_pattern_contains "$forbidden" "$child"; then
		return 0
	fi
	return 1
}

path_patterns_intersect() {
	local left="$1"
	local right="$2"
	local left_code right_code
	if path_pattern_contains "$left" "$right"; then
		return 0
	else
		left_code=$?
	fi
	if path_pattern_contains "$right" "$left"; then
		return 0
	else
		right_code=$?
	fi
	[[ "$left_code" == "2" || "$right_code" == "2" ]] && return 2
	return 1
}

role_reserved_authority_paths() {
	printf '%s\n' \
		"$ROLES_ACTIVE_DIR/**" \
		"$ROLES_REVOKED_DIR/**" \
		"lib/palari/**" \
		"bin/palari" \
		"palari.config.yaml" \
		".github/workflows/**" \
		".github/palari-required-checks.ruleset.json"
}

role_capability_allows_ticket() {
	[[ "$(frontmatter_value "$1" may_create_tickets)" == "true" ]]
}

role_capability_allows_role() {
	case "$(frontmatter_value "$1" may_create_roles)" in
	true | proposed-only) return 0 ;;
	*) return 1 ;;
	esac
}

# Authority is monotonically narrowing. This function never grants authority
# the parent role does not already hold. Unknown containment escalates or rejects.
role_authorize_grant() {
	local parent_file="$1"
	local child_kind="$2"
	local child_file="$3"
	local parent_id child_id parent_status parent_risk child_risk parent_rank child_rank parent_tier child_tier delegate
	local -a parent_allowed=() parent_forbidden=() child_allowed=() child_forbidden=() parent_delegates=() child_delegates=()
	local item forbidden reserved code

	[[ -f "$parent_file" ]] || {
		printf 'reject:parent role file not found\n'
		return 0
	}
	[[ -f "$child_file" ]] || {
		printf 'reject:child file not found\n'
		return 0
	}
	parent_id="$(frontmatter_value "$parent_file" id)"
	child_id="$(frontmatter_value "$child_file" id)"
	parent_status="$(frontmatter_value "$parent_file" status)"
	if [[ -z "$parent_id" ]] || ! valid_role_id "$parent_id"; then
		printf 'reject:parent role has invalid id\n'
		return 0
	fi
	[[ "$parent_status" == "active" ]] || {
		printf 'reject:parent role is not active\n'
		return 0
	}
	case "$child_kind" in
	ticket)
		if ! role_capability_allows_ticket "$parent_file"; then
			printf 'reject:parent role may not create tickets\n'
			return 0
		fi
		;;
	role)
		if ! role_capability_allows_role "$parent_file"; then
			printf 'reject:parent role may not create roles\n'
			return 0
		fi
		;;
	*)
		printf 'reject:invalid child kind\n'
		return 0
		;;
	esac

	mapfile -t parent_allowed < <(frontmatter_list_items "$parent_file" allowed_paths)
	mapfile -t parent_forbidden < <(frontmatter_list_items "$parent_file" forbidden_paths)
	mapfile -t parent_delegates < <(frontmatter_list_items "$parent_file" can_delegate_to)
	mapfile -t child_allowed < <(frontmatter_list_items "$child_file" allowed_paths)
	mapfile -t child_forbidden < <(frontmatter_list_items "$child_file" forbidden_paths)
	((${#parent_allowed[@]} > 0)) || {
		printf 'reject:parent role has no allowed_paths\n'
		return 0
	}
	((${#child_allowed[@]} > 0)) || {
		printf 'escalate:child has no allowed_paths\n'
		return 0
	}
	((${#parent_forbidden[@]} > 0)) || {
		printf 'reject:parent role has no forbidden_paths\n'
		return 0
	}
	((${#child_forbidden[@]} > 0)) || {
		printf 'reject:child has no forbidden_paths\n'
		return 0
	}

	for item in "${child_allowed[@]}"; do
		if path_contained_in_any "$item" "${parent_allowed[@]}"; then
			code=0
		else
			code=$?
		fi
		case "$code" in
		0) ;;
		1)
			printf 'reject:path outside parent authority: %s\n' "$item"
			return 0
			;;
		*)
			printf 'escalate:path containment cannot be proven: %s\n' "$item"
			return 0
			;;
		esac
		if [[ "$child_kind" == "ticket" && "$parent_id" != "ROLE-ROOT" ]]; then
			while IFS= read -r reserved; do
				[[ -n "$reserved" ]] || continue
				if path_patterns_intersect "$item" "$reserved"; then
					printf 'reject:ordinary role cannot create ticket touching authority path: %s\n' "$item"
					return 0
				else
					code=$?
					if [[ "$code" == "2" ]]; then
						printf 'escalate:authority path intersection cannot be proven: %s\n' "$item"
						return 0
					fi
				fi
			done < <(role_reserved_authority_paths)
		fi
		for forbidden in "${parent_forbidden[@]}"; do
			if path_pattern_contains "$forbidden" "$item"; then
				printf 'reject:child allowed path intersects parent forbidden path: %s\n' "$item"
				return 0
			elif path_pattern_contains "$item" "$forbidden"; then
				if ! pattern_is_complex "$forbidden"; then
					printf 'reject:child allowed path intersects parent forbidden path: %s\n' "$item"
					return 0
				fi
			else
				code=$?
				if [[ "$code" == "2" ]]; then
					if ! pattern_is_complex "$forbidden"; then
						printf 'escalate:forbidden path intersection cannot be proven: %s\n' "$item"
						return 0
					fi
				fi
			fi
		done
	done
	for item in "${parent_forbidden[@]}"; do
		if ! list_contains_value "$item" "${child_forbidden[@]}"; then
			printf 'reject:child weakens forbidden path: %s\n' "$item"
			return 0
		fi
	done

	parent_risk="$(frontmatter_value "$parent_file" max_risk)"
	child_risk="$(frontmatter_value "$child_file" max_risk)"
	if [[ "$child_kind" == "ticket" ]]; then
		child_risk="$(frontmatter_value "$child_file" risk)"
	fi
	if ! parent_rank="$(role_risk_rank "$parent_risk")"; then
		printf 'reject:parent role has invalid max_risk\n'
		return 0
	fi
	if ! child_rank="$(role_risk_rank "$child_risk")"; then
		printf 'reject:child has invalid risk\n'
		return 0
	fi
	if ((child_rank > parent_rank)); then
		printf 'escalate:child risk exceeds parent max_risk\n'
		return 0
	fi

	if [[ "$child_kind" == "role" ]]; then
		parent_tier="$(frontmatter_value "$parent_file" tier)"
		child_tier="$(frontmatter_value "$child_file" tier)"
		if [[ ! "$parent_tier" =~ ^[0-9]+$ || ! "$child_tier" =~ ^[0-9]+$ ]]; then
			printf 'reject:role tier must be numeric\n'
			return 0
		fi
		if ((child_tier != parent_tier + 1)); then
			printf 'reject:child role tier must equal parent tier + 1\n'
			return 0
		fi
		mapfile -t child_delegates < <(frontmatter_list_items "$child_file" can_delegate_to)
		for item in "${child_delegates[@]}"; do
			if ! list_contains_value "$item" "${parent_delegates[@]}"; then
				printf 'reject:child delegates outside parent authority: %s\n' "$item"
				return 0
			fi
		done
	else
		delegate="$(frontmatter_value "$child_file" delegated_to_role)"
		[[ -n "$delegate" ]] || delegate="$(frontmatter_value "$child_file" delegate_to_role)"
		if [[ -n "$delegate" ]] && ! list_contains_value "$delegate" "${parent_delegates[@]}"; then
			printf 'reject:ticket delegates outside parent authority: %s\n' "$delegate"
			return 0
		fi
	fi

	: "$parent_id" "$child_id"
	printf 'accept\n'
}

cmd_role_list() {
	local file count=0 id status title parent tier risk
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		id="$(frontmatter_value "$file" id)"
		status="$(frontmatter_value "$file" status)"
		title="$(frontmatter_value "$file" title)"
		parent="$(frontmatter_value "$file" parent_role)"
		tier="$(frontmatter_value "$file" tier)"
		risk="$(frontmatter_value "$file" max_risk)"
		printf '%s\t%s\ttier:%s\tmax:%s\tparent:%s\t%s\n' "${id:-missing}" "${status:-missing}" "${tier:-?}" "${risk:-?}" "${parent:-"-"}" "${title:-}"
		count=$((count + 1))
	done < <(role_files)
	((count > 0)) || printf 'role list: none\n'
}

cmd_role_show() {
	local role="${1:-}"
	[[ -n "$role" ]] || die "role show requires ROLE-ID"
	local file
	file="$(find_role_file "$role")" || die "role not found: $role"
	cat "$file"
}

lint_one_role() {
	local file="$1"
	local errors=0 field id status dir_status value parent_role parent_file result
	if ! has_frontmatter "$file"; then
		printf 'role lint: %s: missing YAML frontmatter\n' "${file#"$ROOT"/}" >&2
		return 1
	fi
	for field in "${ROLE_REQUIRED_FIELDS[@]}"; do
		if ! frontmatter_has_key "$file" "$field"; then
			printf 'role lint: %s: missing required field: %s\n' "${file#"$ROOT"/}" "$field" >&2
			errors=$((errors + 1))
		fi
	done
	id="$(frontmatter_value "$file" id)"
	status="$(frontmatter_value "$file" status)"
	dir_status="$(role_dir_status "$file")"
	if [[ -n "$id" ]] && ! valid_role_id "$id"; then
		printf 'role lint: %s: invalid id: %s\n' "${file#"$ROOT"/}" "$id" >&2
		errors=$((errors + 1))
	fi
	case "$status" in
	active | proposed | revoked) ;;
	*)
		printf 'role lint: %s: invalid status: %s\n' "${file#"$ROOT"/}" "${status:-missing}" >&2
		errors=$((errors + 1))
		;;
	esac
	if [[ "$dir_status" != "unknown" && -n "$status" && "$dir_status" != "$status" ]]; then
		printf 'role lint: %s: status %s does not match %s directory\n' "${file#"$ROOT"/}" "$status" "$dir_status" >&2
		errors=$((errors + 1))
	fi
	value="$(frontmatter_value "$file" tier)"
	if [[ -n "$value" && ! "$value" =~ ^[0-9]+$ ]]; then
		printf 'role lint: %s: tier must be numeric\n' "${file#"$ROOT"/}" >&2
		errors=$((errors + 1))
	fi
	value="$(frontmatter_value "$file" max_risk)"
	if [[ -n "$value" ]] && ! in_words "$value" "$VALID_RISKS"; then
		printf 'role lint: %s: invalid max_risk: %s\n' "${file#"$ROOT"/}" "$value" >&2
		errors=$((errors + 1))
	fi
	for field in may_create_tickets may_execute_tickets may_review_tickets may_accept_tickets; do
		value="$(frontmatter_value "$file" "$field")"
		[[ -z "$value" || "$value" == "true" || "$value" == "false" ]] || {
			printf 'role lint: %s: %s must be true or false\n' "${file#"$ROOT"/}" "$field" >&2
			errors=$((errors + 1))
		}
	done
	value="$(frontmatter_value "$file" may_create_roles)"
	case "$value" in
	true | false | proposed-only | "") ;;
	*)
		printf 'role lint: %s: may_create_roles must be true, false, or proposed-only\n' "${file#"$ROOT"/}" >&2
		errors=$((errors + 1))
		;;
	esac
	if [[ "$status" == "active" && "$(frontmatter_list_count "$file" allowed_paths)" == "0" ]]; then
		printf 'role lint: %s: active role allowed_paths must contain at least one item\n' "${file#"$ROOT"/}" >&2
		errors=$((errors + 1))
	fi
	if [[ "$status" == "active" && "$(frontmatter_list_count "$file" forbidden_paths)" == "0" ]]; then
		printf 'role lint: %s: active role forbidden_paths must contain at least one item\n' "${file#"$ROOT"/}" >&2
		errors=$((errors + 1))
	fi
	if [[ "$status" == "active" ]]; then
		for field in issued_by accepted_by accepted_at; do
			value="$(frontmatter_value "$file" "$field")"
			if [[ -z "$value" ]]; then
				printf 'role lint: %s: active role missing %s\n' "${file#"$ROOT"/}" "$field" >&2
				errors=$((errors + 1))
			fi
		done
	fi
	if [[ "$status" == "active" && "$id" != "ROLE-ROOT" ]]; then
		parent_role="$(frontmatter_value "$file" parent_role)"
		if [[ -z "$parent_role" ]]; then
			printf 'role lint: %s: active non-root role requires parent_role\n' "${file#"$ROOT"/}" >&2
			errors=$((errors + 1))
		else
			parent_file="$(find_active_role_file "$parent_role")" || {
				printf 'role lint: %s: parent role is not active: %s\n' "${file#"$ROOT"/}" "$parent_role" >&2
				errors=$((errors + 1))
				parent_file=""
			}
			if [[ -n "$parent_file" ]]; then
				result="$(role_authorize_grant "$parent_file" role "$file")"
				if [[ "$result" != "accept" ]]; then
					printf 'role lint: %s: authority check failed: %s\n' "${file#"$ROOT"/}" "$result" >&2
					errors=$((errors + 1))
				fi
			fi
		fi
	fi
	if [[ "$id" == "ROLE-ROOT" && -n "$(frontmatter_value "$file" parent_role)" ]]; then
		printf 'role lint: %s: ROLE-ROOT must not have parent_role\n' "${file#"$ROOT"/}" >&2
		errors=$((errors + 1))
	fi
	return "$errors"
}

role_lint_graph_checks() {
	local errors=0 file id status parent delegate current next seen
	local -A id_count=() id_status=() id_parent=()
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		id="$(frontmatter_value "$file" id)"
		status="$(frontmatter_value "$file" status)"
		parent="$(frontmatter_value "$file" parent_role)"
		[[ -n "$id" ]] || continue
		id_count["$id"]=$((${id_count["$id"]:-0} + 1))
		id_status["$id"]="$status"
		id_parent["$id"]="$parent"
	done < <(role_files)

	for id in "${!id_count[@]}"; do
		if ((${id_count["$id"]} > 1)); then
			printf 'role lint: duplicate role id: %s\n' "$id" >&2
			errors=$((errors + 1))
		fi
	done

	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		id="$(frontmatter_value "$file" id)"
		status="$(frontmatter_value "$file" status)"
		case "$status" in
		active | proposed) ;;
		*) continue ;;
		esac
		while IFS= read -r delegate; do
			[[ -n "$delegate" ]] || continue
			if [[ -z "${id_status["$delegate"]+set}" || "${id_status["$delegate"]}" != "active" ]]; then
				printf 'role lint: %s: unknown delegate: %s\n' "${file#"$ROOT"/}" "$delegate" >&2
				errors=$((errors + 1))
			fi
		done < <(frontmatter_list_items "$file" can_delegate_to)
		: "$id"
	done < <(role_files)

	for id in "${!id_parent[@]}"; do
		status="${id_status["$id"]}"
		case "$status" in
		active | proposed) ;;
		*) continue ;;
		esac
		seen="|$id|"
		current="${id_parent["$id"]}"
		while [[ -n "$current" ]]; do
			if [[ "$seen" == *"|$current|"* ]]; then
				printf 'role lint: delegation cycle includes %s and %s\n' "$id" "$current" >&2
				errors=$((errors + 1))
				break
			fi
			[[ -n "${id_status["$current"]+set}" ]] || break
			next="${id_parent["$current"]}"
			seen+="$current|"
			current="$next"
		done
	done
	return "$errors"
}

cmd_role_lint() {
	local errors=0 count=0 file
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		lint_one_role "$file" || errors=$((errors + 1))
		count=$((count + 1))
	done < <(role_files)
	role_lint_graph_checks || errors=$((errors + 1))
	((errors == 0)) || {
		printf 'role lint: failed with %s issue(s)\n' "$errors" >&2
		exit 1
	}
	if ((count == 0)); then
		printf 'role lint: ok (no roles)\n'
	else
		printf 'role lint: ok\n'
	fi
}

cmd_role_graph() {
	local file id parent status title count=0
	printf 'Palari role graph\n'
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		id="$(frontmatter_value "$file" id)"
		parent="$(frontmatter_value "$file" parent_role)"
		status="$(frontmatter_value "$file" status)"
		title="$(frontmatter_value "$file" title)"
		if [[ -n "$parent" ]]; then
			printf '%s -> %s [%s] %s\n' "$parent" "$id" "${status:-missing}" "${title:-}"
		else
			printf '%s [%s] %s\n' "$id" "${status:-missing}" "${title:-}"
		fi
		count=$((count + 1))
	done < <(role_files)
	((count > 0)) || printf 'role graph: none\n'
}

cmd_role_packet() {
	local role="${1:-}"
	[[ -n "$role" ]] || die "role packet requires ROLE-ID"
	local file id title status parent tier risk
	file="$(find_role_file "$role")" || die "role not found: $role"
	id="$(frontmatter_value "$file" id)"
	title="$(frontmatter_value "$file" title)"
	status="$(frontmatter_value "$file" status)"
	parent="$(frontmatter_value "$file" parent_role)"
	tier="$(frontmatter_value "$file" tier)"
	risk="$(frontmatter_value "$file" max_risk)"
	printf 'Palari role packet\n'
	printf 'Role: %s - %s\n' "$id" "${title:-}"
	printf 'Status: %s\n' "${status:-missing}"
	printf 'Parent role: %s\n' "${parent:-none}"
	printf 'Tier: %s\n' "${tier:-unknown}"
	printf 'Max risk: %s\n\n' "${risk:-unknown}"
	printf 'Authority boundary:\n'
	printf '  Agents execute roles; they do not create authority.\n'
	printf '  This role may only narrow authority from its parent and ticket scope.\n'
	printf '  Acceptance, merge, deploy, secrets, production, destructive commands, and unclear authority must escalate unless explicitly allowed.\n\n'
	printf 'Allowed paths:\n'
	while IFS= read -r item; do printf '  - %s\n' "$item"; done < <(frontmatter_list_items "$file" allowed_paths)
	printf '\nForbidden paths:\n'
	while IFS= read -r item; do printf '  - %s\n' "$item"; done < <(frontmatter_list_items "$file" forbidden_paths)
	printf '\nDelegation:\n'
	printf '  may_create_roles: %s\n' "$(frontmatter_value "$file" may_create_roles)"
	printf '  may_create_tickets: %s\n' "$(frontmatter_value "$file" may_create_tickets)"
	printf '  may_execute_tickets: %s\n' "$(frontmatter_value "$file" may_execute_tickets)"
	printf '  may_review_tickets: %s\n' "$(frontmatter_value "$file" may_review_tickets)"
	printf '  may_accept_tickets: %s\n' "$(frontmatter_value "$file" may_accept_tickets)"
	printf '  can_delegate_to:\n'
	while IFS= read -r item; do printf '    - %s\n' "$item"; done < <(frontmatter_list_items "$file" can_delegate_to)
	printf '\nEscalate when:\n'
	while IFS= read -r item; do printf '  - %s\n' "$item"; done < <(frontmatter_list_items "$file" must_escalate_when)
}

write_role_file() {
	local file="$1"
	local id="$2"
	local title="$3"
	local status="$4"
	local parent_role="$5"
	local tier="$6"
	local max_risk="$7"
	local issued_by="$8"
	local accepted_by="$9"
	local accepted_at="${10}"
	shift 10
	local -a forbidden=("$@")
	{
		printf -- '---\n'
		printf 'id: %s\n' "$id"
		printf 'title: %s\n' "$title"
		printf 'status: %s\n' "$status"
		printf 'parent_role: %s\n' "$parent_role"
		printf 'tier: %s\n' "$tier"
		printf 'allowed_paths:\n'
		write_yaml_list forbidden_paths "${forbidden[@]}"
		printf 'max_risk: %s\n' "$max_risk"
		printf 'may_create_roles: false\n'
		printf 'may_create_tickets: false\n'
		printf 'may_execute_tickets: false\n'
		printf 'may_review_tickets: false\n'
		printf 'may_accept_tickets: false\n'
		printf 'can_delegate_to:\n'
		printf 'must_escalate_when:\n'
		printf '  - risk >= R3\n'
		printf '  - path outside allowed_paths\n'
		printf '  - secrets, production, deploy, database mutation, destructive command\n'
		printf '  - authority unclear\n'
		printf 'memory_tags:\n'
		printf 'issued_by: %s\n' "$issued_by"
		printf 'accepted_by: %s\n' "$accepted_by"
		printf 'accepted_at: %s\n' "$accepted_at"
		printf 'created: %s\n' "$(today_utc)"
		printf 'revoked_by:\n'
		printf 'revoked_at:\n'
		printf -- '---\n\n'
		printf '# %s\n\n' "$title"
		printf '## Responsibility\n\nTODO: Define what this role owns.\n\n'
		printf '## Non-Authority\n\nDoes not expand its own authority. Does not bypass tickets, evidence, review, or accept.\n'
	} >"$file"
}

cmd_role_propose() {
	ensure_role_dirs
	local role="${1:-}"
	local title="${2:-}"
	shift 2 || true
	[[ -n "$role" && -n "$title" ]] || die "role propose requires ROLE-ID and title"
	valid_role_id "$role" || die "invalid role id: $role"
	local by_role="" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--by-role)
			by_role="$2"
			shift 2
			;;
		*) die "unknown role propose option: $arg" ;;
		esac
	done
	[[ -n "$by_role" ]] || die "role propose requires --by-role ROLE-ID"
	local parent_file parent_tier parent_risk slug file
	local -a parent_forbidden=()
	parent_file="$(find_active_role_file "$by_role")" || die "active parent role not found: $by_role"
	role_capability_allows_role "$parent_file" || die "parent role may not propose roles: $by_role"
	parent_tier="$(frontmatter_value "$parent_file" tier)"
	[[ "$parent_tier" =~ ^[0-9]+$ ]] || die "parent role tier is invalid: $by_role"
	parent_risk="$(frontmatter_value "$parent_file" max_risk)"
	slug="$(slugify "$title")"
	file="$ROOT/$ROLES_PROPOSED_DIR/$role-$slug.md"
	[[ ! -e "$file" ]] || die "role proposal already exists: ${file#"$ROOT"/}"
	mapfile -t parent_forbidden < <(frontmatter_list_items "$parent_file" forbidden_paths)
	write_role_file "$file" "$role" "$title" proposed "$by_role" "$((parent_tier + 1))" "$parent_risk" "$by_role" "" "" "${parent_forbidden[@]}"
	printf 'role propose: %s\n' "${file#"$ROOT"/}"
	printf 'next: edit allowed_paths, max_risk, capabilities, and can_delegate_to; then run palari role adopt %s --by ACTOR\n' "$role"
}

cmd_role_adopt() {
	ensure_role_dirs
	local role="${1:-}"
	shift || true
	[[ -n "$role" ]] || die "role adopt requires ROLE-ID"
	local by="" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--by)
			by="$2"
			shift 2
			;;
		*) die "unknown role adopt option: $arg" ;;
		esac
	done
	[[ -n "$by" ]] || die "role adopt requires --by ACTOR"
	local file status parent parent_file result dest
	file="$(find_role_file "$role")" || die "role proposal not found: $role"
	status="$(frontmatter_value "$file" status)"
	[[ "$status" == "proposed" ]] || die "role adopt requires proposed status; current: ${status:-missing}"
	parent="$(frontmatter_value "$file" parent_role)"
	[[ -n "$parent" ]] || die "role proposal requires parent_role"
	parent_file="$(find_active_role_file "$parent")" || die "active parent role not found: $parent"
	result="$(role_authorize_grant "$parent_file" role "$file")"
	case "$result" in
	accept) ;;
	escalate:*) die "role adopt escalated: ${result#escalate:}" ;;
	reject:*) die "role adopt rejected: ${result#reject:}" ;;
	*) die "role adopt received invalid authority result: $result" ;;
	esac
	update_frontmatter_scalars "$file" \
		"status"$'\035'"active"$'\034' \
		"accepted_by"$'\035'"$by"$'\034' \
		"accepted_at"$'\035'"$(now_utc)"$'\034'
	dest="$ROOT/$ROLES_ACTIVE_DIR/$(basename "$file")"
	mv "$file" "$dest"
	printf 'role adopt: %s\n' "${dest#"$ROOT"/}"
}

cmd_role_revoke() {
	ensure_role_dirs
	local role="${1:-}"
	shift || true
	[[ -n "$role" ]] || die "role revoke requires ROLE-ID"
	local by="" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--by)
			by="$2"
			shift 2
			;;
		*) die "unknown role revoke option: $arg" ;;
		esac
	done
	[[ -n "$by" ]] || die "role revoke requires --by ACTOR"
	[[ "$role" != "ROLE-ROOT" ]] || die "ROLE-ROOT cannot be revoked by CLI"
	local file status dest
	file="$(find_active_role_file "$role")" || die "active role not found: $role"
	status="$(frontmatter_value "$file" status)"
	[[ "$status" == "active" ]] || die "role revoke requires active status; current: ${status:-missing}"
	update_frontmatter_scalars "$file" \
		"status"$'\035'"revoked"$'\034' \
		"revoked_by"$'\035'"$by"$'\034' \
		"revoked_at"$'\035'"$(now_utc)"$'\034'
	dest="$ROOT/$ROLES_REVOKED_DIR/$(basename "$file")"
	mv "$file" "$dest"
	printf 'role revoke: %s\n' "${dest#"$ROOT"/}"
}

cmd_role() {
	local sub="${1:-list}"
	shift || true
	case "$sub" in
	list | ls) cmd_role_list "$@" ;;
	show) cmd_role_show "$@" ;;
	lint) cmd_role_lint "$@" ;;
	graph) cmd_role_graph "$@" ;;
	packet) cmd_role_packet "$@" ;;
	propose) cmd_role_propose "$@" ;;
	adopt) cmd_role_adopt "$@" ;;
	revoke) cmd_role_revoke "$@" ;;
	*) die "unknown role command: $sub" ;;
	esac
}
