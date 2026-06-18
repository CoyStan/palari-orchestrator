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
	local serves_goal=""
	local model_hint=""
	local -a allowed=()
	local -a forbidden=()
	local -a verification=()
	local -a required_reports=()
	local -a related_skills=()
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
		--goal)
			serves_goal="$2"
			shift 2
			;;
		--model-hint)
			model_hint="$2"
			shift 2
			;;
		--skill)
			related_skills+=("$2")
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
	if [[ -n "$serves_goal" ]]; then
		valid_goal_id "$serves_goal" || die "invalid goal id: $serves_goal; use GOAL-0001"
		find_goal_file "$serves_goal" active >/dev/null || die "active goal not found: $serves_goal (see goals/active)"
	elif [[ "$REQUIRE_SERVES_GOAL" == "strict" ]]; then
		die "require_serves_goal is strict: pass --goal GOAL-ID linking this ticket to an active goal"
	fi
	if [[ -n "$delegate_to_role" && -z "$by_role" ]]; then
		die "--delegate-to-role requires --by-role so authority can be checked"
	fi
	if ((${#related_skills[@]} > 0)); then
		local -a deduped_skills=()
		while IFS= read -r arg; do
			[[ -n "$arg" ]] && deduped_skills+=("$arg")
		done < <(printf '%s\n' "${related_skills[@]}" | awk '!seen[$0]++')
		related_skills=("${deduped_skills[@]}")
		for arg in "${related_skills[@]}"; do
			find_skill_file "$arg" >/dev/null || die "related skill not found: $arg (see palari skill list)"
		done
	fi
	case "$risk" in
	R2)
		with_contract="true"
		requires_review="true"
		;;
	R3 | R4 | R5)
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
	# The worktree path is machine-local state. It is computed from
	# worktree_base at runtime (see ticket_declared_worktree) instead of
	# being committed into ticket frontmatter, which leaked absolute home
	# paths and broke when worktree_base differed between machines.
	worktree=""

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
		printf 'serves_goal: %s\n' "$serves_goal"
		printf 'model_hint: %s\n' "$model_hint"
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
		if ((${#related_skills[@]} > 0)); then
			write_yaml_list related_skills "${related_skills[@]}"
		fi
		printf 'target_branch: %s\n' "$target_branch"
		printf 'branch: %s\n' "$branch"
		printf 'worktree: %s\n' "$worktree"
		if [[ -n "$by_role" ]]; then
			printf 'created_by_role: %s\n' "$by_role"
			printf 'delegated_to_role: %s\n' "$delegate_to_role"
		fi
		printf 'accepted_by:\n'
		printf 'acceptance_mode: human\n'
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

worktree_closeout_evidence_status() {
	local ticket_id="$1"
	local dir="$ROOT/$EVIDENCE_DIR/$ticket_id"
	local name missing=0 code
	for name in verification.log junit.xml palari.sarif manifest.json; do
		[[ -s "$dir/$name" ]] || missing=$((missing + 1))
	done
	if ((missing > 0)); then
		printf 'missing\n'
		return 0
	fi

	set +e
	ticket_evidence_manifest_current_valid "$ticket_id" >/dev/null 2>&1
	code=$?
	set -e
	if ((code == 0)); then
		printf 'ready\n'
	else
		printf 'invalid\n'
	fi
}

worktree_registered_path_for_branch() {
	local branch="$1"
	local wanted="refs/heads/$branch"
	git -C "$ROOT" worktree list --porcelain | awk -v wanted="$wanted" '
    /^worktree / {
      if (path != "" && branch == wanted) {
        print path
        exit
      }
      path = substr($0, 10)
      branch = ""
      next
    }
    /^branch / {
      branch = substr($0, 8)
      next
    }
    END {
      if (path != "" && branch == wanted) {
        print path
      }
    }
  ' | head -n 1
}

cmd_worktree_closeout() {
	require_base_folders
	local ticket="${1:-}"
	[[ -n "$ticket" ]] || die "worktree closeout requires ticket ID"
	local file ticket_id title status risk requires_review requires_human branch worktree target_branch actual_branch head changed_count
	local scope_output scope_code evidence_status technical reviewer human reports_status target_head
	local -a missing_reports=()
	file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
	ticket_id="$(frontmatter_value "$file" id)"
	title="$(frontmatter_value "$file" title)"
	status="$(frontmatter_value "$file" status)"
	risk="$(frontmatter_value "$file" risk)"
	requires_review="$(frontmatter_value "$file" requires_review)"
	requires_human="$(frontmatter_value "$file" requires_human_confirmation)"
	[[ -n "$ticket_id" ]] || ticket_id="$ticket"
	branch="$(ticket_declared_branch "$file" "$ticket_id")"
	worktree="$(worktree_registered_path_for_branch "$branch")"
	[[ -n "$worktree" ]] || worktree="$(ticket_declared_worktree "$file" "$ticket_id")"
	target_branch="$(frontmatter_value "$file" target_branch)"
	[[ -n "$target_branch" ]] || target_branch="$DEFAULT_BRANCH"

	git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "worktree closeout requires a git repo"
	actual_branch="$(git -C "$ROOT" branch --show-current 2>/dev/null || true)"
	if [[ "$actual_branch" != "$branch" ]]; then
		printf 'worktree closeout: %s\n' "$ticket_id"
		printf 'state: wrong-checkout\n'
		printf 'ticket branch: %s\n' "$branch"
		printf 'current branch: %s\n' "${actual_branch:-detached}"
		printf 'target branch: %s\n' "$target_branch"
		printf 'expected worktree: %s\n' "$worktree"
		printf 'current worktree: %s\n' "$ROOT"
		printf 'next: ./bin/palari worktree %s\n' "$ticket_id"
		# shellcheck disable=SC2016 # Printed command intentionally contains command substitution for the user.
		printf 'next: cd "$(./bin/palari worktree %s | sed -n '\''s/^Worker cd: cd //p'\'')"\n' "$ticket_id"
		return 1
	fi
	if [[ "$ROOT" != "$worktree" ]]; then
		printf 'worktree closeout: %s\n' "$ticket_id"
		printf 'state: wrong-checkout\n'
		printf 'ticket branch: %s\n' "$branch"
		printf 'current branch: %s\n' "${actual_branch:-detached}"
		printf 'target branch: %s\n' "$target_branch"
		printf 'expected worktree: %s\n' "$worktree"
		printf 'current worktree: %s\n' "$ROOT"
		printf 'next: cd %s\n' "$worktree"
		printf 'next: ./bin/palari worktree closeout %s\n' "$ticket_id"
		return 1
	fi
	git -C "$ROOT" rev-parse --verify "$target_branch" >/dev/null 2>&1 || die "worktree closeout: missing target branch: $target_branch"
	branch_contains_ref_at "$ROOT" "$branch" "$target_branch" || die "worktree closeout: ticket branch $branch does not contain $target_branch"

	head="$(git -C "$ROOT" rev-parse --short HEAD)"
	target_head="$(git -C "$ROOT" rev-parse --short "$target_branch")"
	changed_count="$(git_changed_count_at "$ROOT")"
	if [[ "$changed_count" != "0" ]]; then
		printf 'worktree closeout: %s\n' "$ticket_id"
		printf 'state: dirty\n'
		printf 'ticket: %s - %s\n' "$ticket_id" "${title:-}"
		printf 'ticket branch: %s\n' "$branch"
		printf 'target branch: %s (%s)\n' "$target_branch" "$target_head"
		printf 'worktree: %s\n' "$ROOT"
		printf 'head: %s\n' "$head"
		printf 'changed paths: %s\n' "$changed_count"
		git -C "$ROOT" status --short -- .
		printf 'next: commit, stash, or remove unrelated local changes, then rerun ./bin/palari worktree closeout %s\n' "$ticket_id"
		return 1
	fi

	changed_count="$(git -C "$ROOT" diff --name-only --relative "$target_branch"...HEAD -- . | sed '/^$/d' | wc -l | tr -d ' ')"
	scope_output="$(mktemp "${TMPDIR:-/tmp}/palari-closeout-scope.XXXXXX")"
	set +e
	(cmd_scope_check "$ticket_id" --base "$target_branch") >"$scope_output" 2>&1
	scope_code=$?
	set -e
	if ((scope_code != 0)); then
		printf 'worktree closeout: %s\n' "$ticket_id"
		printf 'state: scope-failed\n'
		printf 'ticket: %s - %s\n' "$ticket_id" "${title:-}"
		printf 'ticket branch: %s\n' "$branch"
		printf 'target branch: %s (%s)\n' "$target_branch" "$target_head"
		printf 'worktree: %s\n' "$ROOT"
		printf 'head: %s\n' "$head"
		printf 'changed paths: %s\n' "$changed_count"
		printf 'scope: failed\n'
		cat "$scope_output"
		rm -f "$scope_output"
		printf 'next: ./bin/palari scope-check %s --base %s\n' "$ticket_id" "$target_branch"
		return 1
	fi
	rm -f "$scope_output"

	evidence_status="$(worktree_closeout_evidence_status "$ticket_id")"
	if [[ "$evidence_status" != "ready" ]]; then
		printf 'worktree closeout: %s\n' "$ticket_id"
		printf 'state: %s-evidence\n' "$evidence_status"
		printf 'ticket: %s - %s\n' "$ticket_id" "${title:-}"
		printf 'ticket branch: %s\n' "$branch"
		printf 'target branch: %s (%s)\n' "$target_branch" "$target_head"
		printf 'worktree: %s\n' "$ROOT"
		printf 'head: %s\n' "$head"
		printf 'changed paths: %s\n' "$changed_count"
		printf 'scope: ok\n'
		printf 'evidence: %s\n' "$evidence_status"
		printf 'next: ./bin/palari ci %s --base %s\n' "$ticket_id" "$target_branch"
		return 1
	fi

	technical="$(find_report_file "$REPORTS_DIR" "$ticket_id" '(^# .*Technical Report$|^## Files Changed$|^## Verification$|^## Risks / Follow-Ups$)' || true)"
	reviewer="$(find_report_file "$REPORTS_DIR" "$ticket_id" '(^# .*Reviewer Note$|^## Review Result$|^## Required Changes$)' || true)"
	human="$(find_report_file "$HUMAN_REPORTS_DIR" "$ticket_id" || true)"
	if [[ "$risk" =~ ^R[2345]$ && -z "$technical" ]]; then
		missing_reports+=("$REPORTS_DIR/$ticket_id-technical-report.md")
	fi
	if [[ ("$requires_human" == "true" || "$risk" =~ ^R[345]$) && -z "$human" ]]; then
		missing_reports+=("$HUMAN_REPORTS_DIR/$ticket_id-human-report.md")
	fi
	if [[ "$status" == "in-review" || "$status" == "accepted" ]]; then
		if [[ ("$requires_review" == "true" || "$risk" =~ ^R[2345]$) && -z "$reviewer" ]]; then
			missing_reports+=("$REPORTS_DIR/$ticket_id-reviewer-note.md")
		fi
	fi
	if ((${#missing_reports[@]} > 0)); then
		reports_status="missing"
	else
		reports_status="ready"
	fi
	if [[ "$reports_status" != "ready" ]]; then
		printf 'worktree closeout: %s\n' "$ticket_id"
		printf 'state: missing-reports\n'
		printf 'ticket: %s - %s\n' "$ticket_id" "${title:-}"
		printf 'ticket branch: %s\n' "$branch"
		printf 'target branch: %s (%s)\n' "$target_branch" "$target_head"
		printf 'worktree: %s\n' "$ROOT"
		printf 'head: %s\n' "$head"
		printf 'changed paths: %s\n' "$changed_count"
		printf 'scope: ok\n'
		printf 'evidence: ready\n'
		printf 'reports: missing\n'
		printf 'missing reports:\n'
		printf -- '- %s\n' "${missing_reports[@]}"
		printf 'next: complete the missing reports, then run ./bin/palari report-lint %s\n' "$ticket_id"
		printf 'next: ./bin/palari worktree closeout %s\n' "$ticket_id"
		return 1
	fi

	printf 'worktree closeout: %s\n' "$ticket_id"
	if [[ "$status" == "in-review" ]]; then
		printf 'state: in-review\n'
	else
		printf 'state: ready-for-review\n'
	fi
	printf 'ticket: %s - %s\n' "$ticket_id" "${title:-}"
	printf 'ticket status: %s\n' "$status"
	printf 'ticket branch: %s\n' "$branch"
	printf 'target branch: %s (%s)\n' "$target_branch" "$target_head"
	printf 'worktree: %s\n' "$ROOT"
	printf 'head: %s\n' "$head"
	printf 'changed paths: %s\n' "$changed_count"
	printf 'scope: ok\n'
	printf 'evidence: ready\n'
	printf 'reports: ready\n'
	if [[ "$status" == "in-review" ]]; then
		printf 'next: ./bin/palari packet %s reviewer\n' "$ticket_id"
	else
		printf 'next: ./bin/palari ticket ready %s\n' "$ticket_id"
		printf 'next: ./bin/palari packet %s reviewer\n' "$ticket_id"
	fi
}

cmd_worktree() {
	require_base_folders
	if [[ "${1:-}" == "closeout" ]]; then
		shift
		cmd_worktree_closeout "$@"
		return
	fi
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

sandbox_base_dir() {
	printf '%s/sandboxes\n' "$WORKTREE_BASE_ABS"
}

sandbox_metadata_write() {
	local target="$1"
	local ticket_id="$2"
	local target_branch="$3"
	local source_commit="$4"
	mkdir -p "$target/.palari"
	{
		printf '{\n'
		printf '  "ticket": %s,\n' "$(json_string "$ticket_id")"
		printf '  "mode": "local",\n'
		printf '  "source_repo": %s,\n' "$(json_string "$ROOT")"
		printf '  "source_commit": %s,\n' "$(json_string "$source_commit")"
		printf '  "target_branch": %s,\n' "$(json_string "$target_branch")"
		printf '  "created_at": %s,\n' "$(json_string "$(now_utc)")"
		printf '  "created_by": "palari"\n'
		printf '}\n'
	} >"$target/.palari/sandbox.json"
}

sandbox_metadata_value() {
	local target="$1"
	local key="$2"
	[[ -f "$target/.palari/sandbox.json" ]] || return 0
	sed -n 's/^[[:space:]]*"'"$key"'":[[:space:]]*"\(.*\)"[,]\{0,1\}$/\1/p' \
		"$target/.palari/sandbox.json" | head -n 1
}

resolve_sandbox_target() {
	local ticket="$1"
	local path="$2"
	local file ticket_id
	if [[ -n "$path" ]]; then
		abs_path "$path"
		return 0
	fi
	file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
	ticket_id="$(frontmatter_value "$file" id)"
	[[ -n "$ticket_id" ]] || ticket_id="$ticket"
	sandbox_default_path "$ticket_id"
}

require_sandbox_marker() {
	local target="$1"
	[[ -d "$target" ]] || die "sandbox not found: $target"
	[[ -f "$target/.palari-sandbox" ]] || die "not a Palari sandbox (missing .palari-sandbox): $target"
}

cmd_sandbox_list() {
	local base dir repo ticket changed count=0
	base="$(sandbox_base_dir)"
	if [[ -d "$base" ]]; then
		for dir in "$base"/*/; do
			[[ -d "$dir" ]] || continue
			repo="${dir%/}/repo"
			[[ -f "$repo/.palari-sandbox" ]] || continue
			ticket="$(head -n 1 "$repo/.palari-sandbox")"
			changed="$(git_changed_count_at "$repo")"
			printf '%s\t%s\t%s changed path(s)\n' "$ticket" "$repo" "$changed"
			count=$((count + 1))
		done
	fi
	printf 'sandbox list: %s sandbox(es)\n' "$count"
}

cmd_sandbox_inspect() {
	local ticket="" path="" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--path)
			path="$2"
			shift 2
			;;
		--*) die "unknown sandbox inspect option: $arg" ;;
		*)
			ticket="$arg"
			shift
			;;
		esac
	done
	[[ -n "$ticket" || -n "$path" ]] || die "sandbox inspect requires ticket ID or --path"
	local target marker_ticket changed value
	target="$(resolve_sandbox_target "$ticket" "$path")"
	require_sandbox_marker "$target"
	marker_ticket="$(head -n 1 "$target/.palari-sandbox")"
	changed="$(git_changed_count_at "$target")"
	printf 'sandbox inspect: %s\n' "$marker_ticket"
	printf 'Sandbox repo: %s\n' "$target"
	for value in mode source_repo source_commit target_branch created_at; do
		printf '%s: %s\n' "$value" "$(sandbox_metadata_value "$target" "$value")" |
			sed 's/: $/: unknown (created before sandbox.json)/'
	done
	printf 'Changed paths: %s\n' "$changed"
	if ((changed > 0)); then
		git -C "$target" status --short | sed 's/^/  /'
	fi
}

cmd_sandbox_destroy() {
	local ticket="" path="" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--path)
			path="$2"
			shift 2
			;;
		--*) die "unknown sandbox destroy option: $arg" ;;
		*)
			ticket="$arg"
			shift
			;;
		esac
	done
	[[ -n "$ticket" || -n "$path" ]] || die "sandbox destroy requires ticket ID or --path"
	local target parent
	target="$(resolve_sandbox_target "$ticket" "$path")"
	[[ -e "$target" ]] || die "sandbox not found: $target"
	[[ -f "$target/.palari-sandbox" ]] || die "refusing to remove non-Palari sandbox path: $target"
	rm -rf "$target"
	parent="$(dirname "$target")"
	rmdir "$parent" 2>/dev/null || true
	printf 'sandbox destroy: removed %s\n' "$target"
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
	git -C "$target" add .
	if ! git -C "$target" diff --cached --quiet; then
		git -C "$target" commit -m "initialize palari sandbox" >/dev/null
	fi
	sandbox_metadata_write "$target" "$ticket_id" "$target_branch" \
		"$(git -C "$ROOT" rev-parse HEAD)"

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
	list) cmd_sandbox_list "$@" ;;
	inspect) cmd_sandbox_inspect "$@" ;;
	destroy) cmd_sandbox_destroy "$@" ;;
	*) die "unknown sandbox command: ${sub:-}; try \`palari sandbox create|list|inspect|destroy\`" ;;
	esac
}
