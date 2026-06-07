cmd_ticket_create() {
	require_base_folders
	local id="${1:-}"
	local title="${2:-}"
	shift 2 || true
	[[ -n "$id" && -n "$title" ]] || die "ticket create requires ID and title"
	valid_ticket_id "$id" || die "invalid ticket id: $id"

	local stream="process" risk="R1" priority="P2" with_contract="false"
	local requires_review="false" requires_human="false"
	local target_branch="$DEFAULT_BRANCH"
	local by_role="" delegate_to_role=""
	local -a allowed=()
	local -a forbidden=()
	local -a verification=()
	local -a required_reports=()
	local arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--stream)
			stream="$2"
			shift 2
			;;
		--risk)
			risk="$2"
			shift 2
			;;
		--priority)
			priority="$2"
			shift 2
			;;
		--allowed)
			allowed+=("$2")
			shift 2
			;;
		--forbidden)
			forbidden+=("$2")
			shift 2
			;;
		--verify)
			verification+=("$2")
			shift 2
			;;
		--review)
			requires_review="true"
			shift
			;;
		--human)
			requires_human="true"
			shift
			;;
		--contract)
			with_contract="true"
			shift
			;;
		--required-report)
			required_reports+=("$2")
			shift 2
			;;
		--target-branch)
			target_branch="$2"
			shift 2
			;;
		--by-role)
			by_role="$2"
			shift 2
			;;
		--delegate-to-role)
			delegate_to_role="$2"
			shift 2
			;;
		*) die "unknown ticket create option: $arg" ;;
		esac
	done

	((${#allowed[@]} > 0)) || die "ticket create needs at least one --allowed path"
	((${#verification[@]} > 0)) || die "ticket create needs at least one --verify item"
	if ((${#forbidden[@]} == 0)); then
		while IFS= read -r arg; do
			[[ -n "$arg" ]] && forbidden+=("$arg")
		done < <(configured_default_forbidden_paths)
	fi
	in_words "$risk" "$VALID_RISKS" || die "invalid risk: $risk"
	in_words "$priority" "$VALID_PRIORITIES" || die "invalid priority: $priority"
	if [[ -n "$delegate_to_role" && -z "$by_role" ]]; then
		die "--delegate-to-role requires --by-role so authority can be checked"
	fi
	case "$risk" in
	R2)
		with_contract="true"
		requires_review="true"
		;;
	R3 | R4)
		with_contract="true"
		requires_review="true"
		requires_human="true"
		;;
	esac

	local slug file created branch worktree
	slug="$(slugify "$title")"
	file="$ROOT/$OPEN_DIR/$id-$slug.md"
	[[ ! -e "$file" ]] || die "ticket already exists: ${file#"$ROOT"/}"
	created="$(today_utc)"
	branch="$(ticket_default_branch "$id")"
	worktree="$(ticket_default_worktree "$id")"

	if [[ -n "$by_role" ]]; then
		local parent_role_file candidate authority_result escalation_file
		valid_role_id "$by_role" || die "invalid by-role id: $by_role"
		if [[ -n "$delegate_to_role" ]]; then
			valid_role_id "$delegate_to_role" || die "invalid delegate-to-role id: $delegate_to_role"
		fi
		parent_role_file="$(find_active_role_file "$by_role")" || die "active role not found: $by_role"
		candidate="$(mktemp "${TMPDIR:-/tmp}/palari-ticket-candidate.XXXXXX")"
		{
			printf -- '---\n'
			printf 'id: %s\n' "$id"
			printf 'title: %s\n' "$title"
			printf 'status: open\n'
			printf 'risk: %s\n' "$risk"
			write_yaml_list allowed_paths "${allowed[@]}"
			write_yaml_list forbidden_paths "${forbidden[@]}"
			printf 'created_by_role: %s\n' "$by_role"
			printf 'delegated_to_role: %s\n' "$delegate_to_role"
			printf -- '---\n'
		} >"$candidate"
		authority_result="$(role_authorize_grant "$parent_role_file" ticket "$candidate")"
		rm -f "$candidate"
		case "$authority_result" in
		accept) ;;
		escalate:*)
			mkdir -p "$ROOT/$PLANNING_REPORTS_DIR"
			escalation_file="$ROOT/$PLANNING_REPORTS_DIR/$id-role-escalation.md"
			{
				printf '# %s role authority escalation\n\n' "$id"
				printf 'Ticket: %s - %s\n\n' "$id" "$title"
				printf 'Created by role: %s\n' "$by_role"
				printf 'Delegated to role: %s\n' "${delegate_to_role:-none}"
				printf 'Escalation reason: %s\n\n' "${authority_result#escalate:}"
				printf 'Requested allowed paths:\n'
				for arg in "${allowed[@]}"; do printf -- '- %s\n' "$arg"; done
				printf '\nRequested forbidden paths:\n'
				for arg in "${forbidden[@]}"; do printf -- '- %s\n' "$arg"; done
			} >"$escalation_file"
			printf 'ticket create escalated: %s\n' "${authority_result#escalate:}" >&2
			printf 'planning report: %s\n' "${escalation_file#"$ROOT"/}" >&2
			return 1
			;;
		reject:*)
			die "ticket create rejected by role authority: ${authority_result#reject:}"
			;;
		*)
			die "ticket create received invalid role authority result: $authority_result"
			;;
		esac
	fi

	{
		printf -- '---\n'
		printf 'id: %s\n' "$id"
		printf 'title: %s\n' "$title"
		printf 'status: open\n'
		printf 'risk: %s\n' "$risk"
		printf 'priority: %s\n' "$priority"
		printf 'stream: %s\n' "$stream"
		printf 'claimed_by:\n'
		printf 'claimed_at:\n'
		printf 'claim_ref:\n'
		printf 'claim_heartbeat_at:\n'
		printf 'claim_expires_at:\n'
		write_yaml_list allowed_paths "${allowed[@]}"
		write_yaml_list forbidden_paths "${forbidden[@]}"
		printf 'requires_human_confirmation: %s\n' "$requires_human"
		printf 'requires_review: %s\n' "$requires_review"
		if ((${#required_reports[@]} > 0)); then
			write_yaml_list required_reports "${required_reports[@]}"
		fi
		write_yaml_list verification "${verification[@]}"
		printf 'target_branch: %s\n' "$target_branch"
		printf 'branch: %s\n' "$branch"
		printf 'worktree: %s\n' "$worktree"
		if [[ -n "$by_role" ]]; then
			printf 'created_by_role: %s\n' "$by_role"
			printf 'delegated_to_role: %s\n' "$delegate_to_role"
		fi
		printf 'accepted_by:\n'
		printf 'accepted_at:\n'
		printf 'created: %s\n' "$created"
		printf 'updated: %s\n' "$created"
		printf -- '---\n\n'
		printf '# %s %s\n\n' "$id" "$title"
		printf '## Goal\n\nState the result this ticket should produce.\n\n'
		printf '## Scope\n\nList what may change.\n\n'
		printf '## Acceptance\n\n- The scoped result exists.\n- Path and risk rules are respected.\n\n'
		printf '## Verification\n\n'
		for arg in "${verification[@]}"; do printf -- '- %s\n' "$arg"; done
		if [[ "$with_contract" == "true" ]]; then
			printf '\n## Ticket Completion Contract\n\n'
			printf '### Non-Goals\n\n- Nearby work this ticket must not absorb.\n\n'
			printf '### Definition Of Done\n\n- Concrete done condition.\n\n'
			printf '### Evidence Required\n\n- Report, command, review, screenshot, or manual check to inspect.\n\n'
			printf '### Expansion Rules\n\n- Stop if scope, risk, or authority changes.\n\n'
			printf '### Final Review Gate\n\n- Reviewer checks each done item and recommends accept, reopen, or needs-human.\n'
		fi
	} >"$file"

	printf 'ticket create: %s\n' "${file#"$ROOT"/}"
}

cmd_ticket_claim() {
	require_base_folders
	local ticket="${1:-}"
	shift || true
	local by="${PROCESS_AGENT:-${USER:-agent}}"
	local ttl="$CLAIM_LEASE_SECONDS" allow_overlap="false" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--ttl)
			ttl="$2"
			shift 2
			;;
		--allow-overlap)
			allow_overlap="true"
			shift
			;;
		--by)
			by="$2"
			shift 2
			;;
		--*) die "unknown ticket claim option: $arg" ;;
		*)
			by="$arg"
			shift
			;;
		esac
	done
	[[ -n "$ticket" ]] || die "ticket claim requires ID"
	[[ "$ttl" =~ ^[0-9]+$ ]] || die "claim ttl must be seconds"
	local lock_file file status ticket_id now expires claim_ref claim_head
	mkdir -p "$ROOT/$STATE_DIR/locks"
	lock_file="$ROOT/$STATE_DIR/locks/ticket-$ticket.lock"
	if command -v flock >/dev/null 2>&1; then
		exec 9>"$lock_file"
		flock -n 9 || die "ticket claim is locked by another process: $ticket"
	fi
	file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
	status="$(frontmatter_value "$file" status)"
	ticket_id="$(frontmatter_value "$file" id)"
	[[ -n "$ticket_id" ]] || ticket_id="$ticket"
	[[ "${file#"$ROOT"/}" == "$OPEN_DIR/"* ]] || die "cannot claim closed ticket: $ticket"
	if [[ "$status" == "claimed" ]]; then
		ticket_claim_expired "$file" || die "ticket $ticket is already claimed and lease is still active"
	else
		[[ "$status" == "open" || "$status" == "reopened" ]] || die "ticket $ticket is not open/reopened; current status: ${status:-missing}"
	fi
	if [[ "$allow_overlap" != "true" ]] && ! scope_overlap_errors "$file"; then
		if [[ "$SCOPE_OVERLAP_POLICY" == "block" ]]; then
			die "ticket $ticket has overlapping allowed_paths; pass --allow-overlap to acknowledge"
		fi
		printf 'ticket claim: warning: overlapping allowed_paths detected for %s\n' "$ticket_id" >&2
	fi
	claim_ref="$(claim_ref_for_ticket "$ticket_id")"
	if [[ "$status" == "claimed" ]] && ticket_claim_expired "$file"; then
		git -C "$ROOT" update-ref -d "$claim_ref" >/dev/null 2>&1 || true
	fi
	claim_head="$(create_git_claim_ref "$ticket_id" "$claim_ref")"
	now="$(now_utc)"
	expires="$(iso_from_epoch "$(($(epoch_utc) + ttl))")"
	update_frontmatter_scalars "$file" \
		"status"$'\035'"claimed"$'\034' \
		"claimed_by"$'\035'"$by"$'\034' \
		"claimed_at"$'\035'"$now"$'\034' \
		"claim_ref"$'\035'"$claim_ref"$'\034' \
		"claim_heartbeat_at"$'\035'"$now"$'\034' \
		"claim_expires_at"$'\035'"$expires"$'\034' \
		"updated"$'\035'"$(today_utc)"$'\034'
	printf 'ticket claim: %s as %s\n' "$ticket_id" "$by"
	printf 'claim lease: %ss, expires %s\n' "$ttl" "$expires"
	if [[ -n "$claim_head" ]]; then
		printf 'claim ref: %s\n' "$claim_ref"
	fi
}

cmd_ticket_heartbeat() {
	require_base_folders
	local ticket="${1:-}"
	local ttl="${2:-$CLAIM_LEASE_SECONDS}"
	[[ -n "$ticket" ]] || die "ticket heartbeat requires ID"
	[[ "$ttl" =~ ^[0-9]+$ ]] || die "heartbeat ttl must be seconds"
	local file status now expires
	file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
	status="$(frontmatter_value "$file" status)"
	[[ "$status" == "claimed" || "$status" == "in-review" ]] || die "heartbeat requires claimed or in-review status; current: ${status:-missing}"
	[[ -n "$(frontmatter_value "$file" claim_ref)" || -n "$(frontmatter_value "$file" claim_expires_at)" ]] ||
		die "ticket $ticket has no active claim lease; claim it first"
	now="$(now_utc)"
	expires="$(iso_from_epoch "$(($(epoch_utc) + ttl))")"
	update_frontmatter_scalars "$file" \
		"claim_heartbeat_at"$'\035'"$now"$'\034' \
		"claim_expires_at"$'\035'"$expires"$'\034' \
		"updated"$'\035'"$(today_utc)"$'\034'
	printf 'ticket heartbeat: %s renewed until %s\n' "$(frontmatter_value "$file" id)" "$expires"
}

set_ticket_status() {
	local ticket="$1"
	local new_status="$2"
	local file status claim_ref
	file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
	status="$(frontmatter_value "$file" status)"
	claim_ref="$(frontmatter_value "$file" claim_ref)"
	[[ "${file#"$ROOT"/}" == "$OPEN_DIR/"* ]] || die "cannot update closed ticket: $ticket"
	case "$new_status" in
	in-review)
		[[ "$status" == "claimed" || "$status" == "reopened" ]] || die "in-review requires claimed or reopened status; current: ${status:-missing}"
		;;
	blocked | needs-human)
		[[ "$status" == "claimed" || "$status" == "reopened" || "$status" == "open" ]] || die "$new_status requires open, claimed, or reopened status; current: ${status:-missing}"
		;;
	reopened)
		[[ "$status" == "in-review" ]] || die "reopened requires in-review status; current: ${status:-missing}"
		;;
	*)
		die "unsupported status transition helper: $new_status"
		;;
	esac
	if [[ "$new_status" == "in-review" ]]; then
		update_frontmatter_scalars "$file" \
			"status"$'\035'"$new_status"$'\034' \
			"updated"$'\035'"$(today_utc)"$'\034'
	else
		update_frontmatter_scalars "$file" \
			"status"$'\035'"$new_status"$'\034' \
			"claimed_by"$'\035'""$'\034' \
			"claimed_at"$'\035'""$'\034' \
			"claim_ref"$'\035'""$'\034' \
			"claim_heartbeat_at"$'\035'""$'\034' \
			"claim_expires_at"$'\035'""$'\034' \
			"updated"$'\035'"$(today_utc)"$'\034'
		if [[ -n "$claim_ref" ]]; then
			git -C "$ROOT" update-ref -d "$claim_ref" >/dev/null 2>&1 || true
		fi
	fi
	printf 'ticket status: %s -> %s\n' "$(frontmatter_value "$file" id)" "$new_status"
}

cmd_ticket() {
	local sub="${1:-}"
	shift || true
	case "$sub" in
	create | new) cmd_ticket_create "$@" ;;
	claim) cmd_ticket_claim "$@" ;;
	heartbeat) cmd_ticket_heartbeat "$@" ;;
	audit) cmd_lifecycle_audit "$@" ;;
	ready) set_ticket_status "${1:-}" in-review ;;
	block) set_ticket_status "${1:-}" blocked ;;
	needs-human) set_ticket_status "${1:-}" needs-human ;;
	reopen) set_ticket_status "${1:-}" reopened ;;
	*) die "unknown ticket command: $sub" ;;
	esac
}

cmd_worktree() {
	require_base_folders
	local ticket="${1:-}"
	[[ -n "$ticket" ]] || die "worktree requires ticket ID"
	local file ticket_id title branch worktree target_branch branch_state target_head actual_branch changed head
	file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
	ticket_id="$(frontmatter_value "$file" id)"
	title="$(frontmatter_value "$file" title)"
	[[ -n "$ticket_id" ]] || ticket_id="$ticket"
	branch="$(ticket_declared_branch "$file" "$ticket_id")"
	worktree="$(ticket_declared_worktree "$file" "$ticket_id")"
	target_branch="$(frontmatter_value "$file" target_branch)"
	[[ -n "$target_branch" ]] || target_branch="$DEFAULT_BRANCH"

	git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "worktree command requires a git repo"
	git -C "$ROOT" rev-parse --verify "$target_branch" >/dev/null 2>&1 || die "missing target branch: $target_branch"
	target_head="$(git -C "$ROOT" rev-parse --short "$target_branch")"
	require_clean_git_at "$ROOT" "canonical repo"

	if git -C "$ROOT" show-ref --verify --quiet "refs/heads/$branch"; then
		branch_state="exists"
		branch_contains_ref_at "$ROOT" "$branch" "$target_branch" ||
			die "ticket branch $branch does not contain $target_branch ($target_head)"
	else
		branch_state="created from $target_branch"
	fi

	if [[ -e "$worktree" ]] && ! git -C "$worktree" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		die "worktree path exists but is not a git worktree: $worktree"
	fi
	if [[ ! -e "$worktree" ]]; then
		mkdir -p "$(dirname "$worktree")"
		if [[ "$branch_state" == "exists" ]]; then
			git -C "$ROOT" worktree add "$worktree" "$branch" >/dev/null
		else
			git -C "$ROOT" worktree add -b "$branch" "$worktree" "$target_branch" >/dev/null
		fi
	fi

	require_ticket_worktree_ready "$ticket_id" "$branch" "$worktree" "worktree" "$target_branch"
	actual_branch="$(git -C "$worktree" branch --show-current)"
	changed="$(git_changed_count_at "$worktree")"
	head="$(git -C "$worktree" rev-parse --short HEAD)"

	printf 'worktree: ok\n'
	printf 'Ticket: %s - %s\n' "$ticket_id" "${title:-}"
	printf 'Target branch: %s (%s)\n' "$target_branch" "$target_head"
	printf 'Ticket branch: %s (%s)\n' "$branch" "$branch_state"
	printf 'Ticket worktree: %s\n' "$worktree"
	printf 'Worktree branch: %s\n' "$actual_branch"
	printf 'Worktree HEAD: %s\n' "$head"
	printf 'Worktree changed paths: %s\n' "$changed"
	printf 'Worker cd: cd %s\n' "$worktree"
}

sandbox_default_path() {
	local ticket_id="$1"
	printf '%s/sandboxes/%s/repo\n' "$WORKTREE_BASE_ABS" "$ticket_id"
}

ensure_palari_gitignore() {
	local repo="$1"
	local ignore="$repo/.gitignore"
	if [[ -f "$ignore" ]]; then
		grep -Fxq ".palari/" "$ignore" || printf '\n.palari/\n' >>"$ignore"
	else
		printf '.palari/\n' >"$ignore"
	fi
}

cmd_sandbox_create() {
	require_base_folders
	local ticket="${1:-}"
	shift || true
	[[ -n "$ticket" ]] || die "sandbox create requires ticket ID"
	local force="false" path="" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--force)
			force="true"
			shift
			;;
		--path)
			path="$2"
			shift 2
			;;
		*) die "unknown sandbox create option: $arg" ;;
		esac
	done

	local file ticket_id rel target target_branch
	file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
	ticket_id="$(frontmatter_value "$file" id)"
	[[ -n "$ticket_id" ]] || ticket_id="$ticket"
	rel="${file#"$ROOT"/}"
	target_branch="$(frontmatter_value "$file" target_branch)"
	[[ -n "$target_branch" ]] || target_branch="$DEFAULT_BRANCH"
	[[ -n "$path" ]] || path="$(sandbox_default_path "$ticket_id")"
	target="$(abs_path "$path")"

	git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "sandbox create requires a git repo"
	require_clean_git_at "$ROOT" "canonical repo"
	git -C "$ROOT" cat-file -e "HEAD:$rel" 2>/dev/null ||
		die "sandbox create requires ticket file committed at HEAD: $rel"

	if [[ -e "$target" ]]; then
		[[ "$force" == "true" ]] || die "sandbox already exists: $target; pass --force to recreate"
		[[ -f "$target/.palari-sandbox" ]] || die "refusing to remove non-Palari sandbox path: $target"
		rm -rf "$target"
	fi
	mkdir -p "$target"
	git -C "$ROOT" archive --format=tar HEAD | tar -xf - -C "$target"
	ensure_palari_gitignore "$target"
	printf '%s\n' "$ticket_id" >"$target/.palari-sandbox"
	git -C "$target" init -b "$target_branch" >/dev/null
	git -C "$target" config user.email "palari-sandbox@example.invalid"
	git -C "$target" config user.name "Palari Sandbox"
	git -C "$target" add .
	git -C "$target" commit -m "sandbox baseline for $ticket_id" >/dev/null
	"$target/bin/palari" init >/dev/null

	printf 'sandbox create: ok\n'
	printf 'Ticket: %s\n' "$ticket_id"
	printf 'Sandbox repo: %s\n' "$target"
	printf 'Sandbox branch: %s\n' "$target_branch"
	printf 'Worker cd: cd %s\n' "$target"
}

cmd_sandbox() {
	local sub="${1:-}"
	shift || true
	case "$sub" in
	create) cmd_sandbox_create "$@" ;;
	*) die "unknown sandbox command: ${sub:-}; try \`palari sandbox create TICKET-ID\`" ;;
	esac
}
