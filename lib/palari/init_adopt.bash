cmd_init() {
	local dir force="false" with_ci="false" with_hooks="false"
	while (($# > 0)); do
		case "$1" in
		--ci)
			with_ci="true"
			shift
			;;
		--hooks)
			with_hooks="true"
			shift
			;;
		--all)
			with_ci="true"
			with_hooks="true"
			shift
			;;
		--force)
			force="true"
			shift
			;;
		*) die "unknown init option: $1" ;;
		esac
	done
	for dir in "$PROPOSED_DIR" "$OPEN_DIR" "$CLOSED_DIR" "$REPORTS_DIR" "$HUMAN_REPORTS_DIR" "$PLANNING_REPORTS_DIR" "$EVIDENCE_DIR" "$HANDOFFS_DIR" "$ROLES_ACTIVE_DIR" "$ROLES_PROPOSED_DIR" "$ROLES_REVOKED_DIR"; do
		mkdir -p "$ROOT/$dir"
		: >"$ROOT/$dir/.gitkeep"
	done
	mkdir -p "$ROOT/$STATE_DIR/locks"
	printf 'init: ok\n'
	printf 'root: %s\n' "$ROOT"
	printf 'tickets: %s, %s, %s\n' "$PROPOSED_DIR" "$OPEN_DIR" "$CLOSED_DIR"
	printf 'evidence: %s\n' "$EVIDENCE_DIR"
	printf 'roles: %s, %s, %s\n' "$ROLES_ACTIVE_DIR" "$ROLES_PROPOSED_DIR" "$ROLES_REVOKED_DIR"
	if [[ "$with_ci" == "true" ]]; then
		install_template_file "adapters/github/workflows/palari.yml" ".github/workflows/palari.yml" "$force"
		install_template_file "adapters/github/rulesets/palari-required-checks.json" ".github/palari-required-checks.ruleset.json" "$force"
		printf 'init: important: the workflow alone does not protect merges until the ruleset is installed.\n'
		printf 'init: activate required checks with:\n'
		while IFS= read -r line; do
			printf '  %s\n' "$line"
		done < <(ruleset_activation_command)
	fi
	if [[ "$with_hooks" == "true" ]]; then
		install_template_file "adapters/hooks/lefthook.yml" "lefthook.yml" "$force"
	fi
}

cmd_authority() {
	local sub="${1:-show}"
	shift || true
	local action="" user_explicit="false" key value
	case "$sub" in
	show | "")
		printf 'Palari authority profile\n'
		printf 'profile: %s\n' "$AUTHORITY_PROFILE"
		printf 'agent_can_commit: %s\n' "$(authority_value agent_can_commit)"
		printf 'agent_can_push_branch: %s\n' "$(authority_value agent_can_push_branch)"
		printf 'agent_can_open_pr: %s\n' "$(authority_value agent_can_open_pr)"
		printf 'agent_can_merge_main: %s\n' "$(authority_value agent_can_merge_main)"
		printf 'agent_can_accept: %s\n' "$(authority_value agent_can_accept)"
		printf 'note: these permissions describe autonomous agent authority; humans can still run explicit Palari gates.\n'
		;;
	check)
		action="${1:-}"
		shift || true
		while (($# > 0)); do
			case "$1" in
			--user-explicit)
				user_explicit="true"
				shift
				;;
			*) die "unknown authority check option: $1" ;;
			esac
		done
		[[ -n "$action" ]] || die "authority check requires an action"
		key="$(authority_action_key "$action")" || die "unknown authority action: $action"
		value="$(authority_value "$key")"
		case "$value" in
		true | allowed | yes)
			printf 'authority: ok for %s under %s\n' "$action" "$AUTHORITY_PROFILE"
			;;
		user-explicit)
			if [[ "$user_explicit" == "true" ]]; then
				printf 'authority: ok for %s under %s with explicit user instruction\n' "$action" "$AUTHORITY_PROFILE"
			else
				printf 'authority: refused for %s under %s; requires --user-explicit\n' "$action" "$AUTHORITY_PROFILE" >&2
				return 1
			fi
			;;
		*)
			printf 'authority: refused for %s under %s\n' "$action" "$AUTHORITY_PROFILE" >&2
			return 1
			;;
		esac
		;;
	*) die "unknown authority command: $sub" ;;
	esac
}

ticket_evidence_present_quiet() {
	local ticket_id="$1"
	local dir="$ROOT/$EVIDENCE_DIR/$ticket_id"
	local name
	for name in verification.log junit.xml palari.sarif manifest.json; do
		[[ -s "$dir/$name" ]] || return 1
	done
	return 0
}

ticket_report_lint_quiet() {
	local ticket_id="$1"
	local code
	set +e
	cmd_report_lint "$ticket_id" >/dev/null 2>&1
	code=$?
	set -e
	return "$code"
}

ticket_next_action() {
	local file="$1"
	local id status target title
	id="$(frontmatter_value "$file" id)"
	title="$(frontmatter_value "$file" title)"
	status="$(frontmatter_value "$file" status)"
	target="$(frontmatter_value "$file" target_branch)"
	[[ -n "$id" ]] || id="$(ticket_title_from_file "$file")"
	[[ -n "$target" ]] || target="$DEFAULT_BRANCH"
	case "$status" in
	open)
		printf 'claim and isolate: palari ticket claim %s YOUR-NAME && palari worktree %s\n' "$id" "$id"
		;;
	claimed)
		if ticket_evidence_present_quiet "$id" && ticket_report_lint_quiet "$id"; then
			printf 'move to review: palari ticket ready %s\n' "$id"
		else
			printf 'finish evidence: palari worktree %s; palari packet %s specialist; palari ci %s --base %s\n' "$id" "$id" "$id" "$target"
		fi
		;;
	in-review)
		if ! ticket_evidence_present_quiet "$id"; then
			printf 'create evidence: palari ci %s --base %s\n' "$id" "$target"
		elif ! ticket_report_lint_quiet "$id"; then
			printf 'complete review reports: palari packet %s reviewer\n' "$id"
		else
			printf 'accept or reopen: palari accept %s --by founder\n' "$id"
		fi
		;;
	blocked)
		printf 'resolve blocker or hand off: inspect %s and add a handoff note\n' "${file#"$ROOT"/}"
		;;
	needs-human)
		printf 'human decision required: add report under %s for %s\n' "$HUMAN_REPORTS_DIR" "$id"
		;;
	reopened)
		printf 'continue revised work: palari ticket claim %s YOUR-NAME && palari packet %s specialist\n' "$id" "$id"
		;;
	*)
		printf 'inspect ticket state: %s has status %s\n' "$id" "${status:-missing}"
		;;
	esac
	: "$title"
}

cmd_lifecycle_audit() {
	require_base_folders
	local limit="" count=0 file id status title next
	while (($# > 0)); do
		case "$1" in
		--limit)
			limit="$2"
			shift 2
			;;
		*) die "unknown lifecycle audit option: $1" ;;
		esac
	done
	printf 'Lifecycle audit\n'
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		id="$(frontmatter_value "$file" id)"
		status="$(frontmatter_value "$file" status)"
		title="$(frontmatter_value "$file" title)"
		[[ -n "$id" ]] || id="$(ticket_title_from_file "$file")"
		next="$(ticket_next_action "$file")"
		printf '%s [%s] %s\n' "$id" "${status:-missing}" "${title:-}"
		printf '  next: %s\n' "$next"
		count=$((count + 1))
		[[ -n "$limit" && "$count" -ge "$limit" ]] && break
	done < <(ticket_files)
	if ((count == 0)); then
		printf 'next: no active tickets; create or adopt the next scoped ticket.\n'
	fi
}

cmd_status() {
	require_base_folders
	local show_next="false"
	while (($# > 0)); do
		case "$1" in
		--next)
			show_next="true"
			shift
			;;
		*) die "unknown status option: $1" ;;
		esac
	done
	local proposals active accepted reports human evidence changed
	proposals="$(proposal_files | wc -l | tr -d ' ')"
	active="$(ticket_files | wc -l | tr -d ' ')"
	accepted="$(closed_ticket_files | wc -l | tr -d ' ')"
	reports="$(find "$ROOT/$REPORTS_DIR" -maxdepth 1 -type f \( -name '*.md' -o -name '*.markdown' \) ! -name 'README.md' | wc -l | tr -d ' ')"
	human="$(find "$ROOT/$HUMAN_REPORTS_DIR" -maxdepth 1 -type f \( -name '*.md' -o -name '*.markdown' \) ! -name 'README.md' | wc -l | tr -d ' ')"
	evidence="$(find "$ROOT/$EVIDENCE_DIR" -type f ! -name '.gitkeep' 2>/dev/null | wc -l | tr -d ' ')"
	if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		changed="$(git_changed_count_at "$ROOT")"
	else
		changed="not-a-git-repo"
	fi
	printf 'Palari Orchestration status\n'
	printf 'root: %s\n' "$ROOT"
	printf 'project: %s\n' "$PROJECT_NAME"
	printf 'proposals: %s proposed\n' "$proposals"
	printf 'tickets: %s active, %s accepted\n' "$active" "$accepted"
	printf 'open:%s claimed:%s blocked:%s needs-human:%s in-review:%s reopened:%s\n' \
		"$(count_status open)" "$(count_status claimed)" "$(count_status blocked)" \
		"$(count_status needs-human)" "$(count_status in-review)" "$(count_status reopened)"
	printf 'reports: %s specialist/reviewer, %s human\n' "$reports" "$human"
	printf 'evidence: %s files\n' "$evidence"
	printf 'git: %s changed paths in workspace\n' "$changed"
	if [[ "$show_next" == "true" ]]; then
		printf '\nNext required action\n'
		cmd_lifecycle_audit --limit 1 | sed '1d'
	fi
}

doctor_check_file() {
	local rel="$1"
	local errors_ref="$2"
	if [[ -e "$ROOT/$rel" ]]; then
		printf 'doctor: ok file %s\n' "$rel"
	else
		printf 'doctor: missing file %s\n' "$rel" >&2
		printf -v "$errors_ref" '%s' "$((${!errors_ref} + 1))"
	fi
}

doctor_check_dir() {
	local rel="$1"
	local errors_ref="$2"
	if [[ -d "$ROOT/$rel" ]]; then
		printf 'doctor: ok dir %s\n' "$rel"
	else
		printf 'doctor: missing dir %s; run ./bin/palari init\n' "$rel" >&2
		printf -v "$errors_ref" '%s' "$((${!errors_ref} + 1))"
	fi
}

cmd_doctor() {
	if [[ "${1:-}" == "lifecycle" ]]; then
		shift
		cmd_lifecycle_audit "$@"
		return 0
	fi
	[[ -z "${1:-}" ]] || die "unknown doctor command: $1"
	local errors=0
	printf 'Palari adoption doctor\n'
	printf 'root: %s\n' "$ROOT"
	if command -v git >/dev/null 2>&1; then
		printf 'doctor: ok command git\n'
	else
		printf 'doctor: missing command git\n' >&2
		errors=$((errors + 1))
	fi
	if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		printf 'doctor: ok git worktree\n'
	else
		printf 'doctor: not a git worktree\n' >&2
		errors=$((errors + 1))
	fi
	if [[ -x "$ROOT/bin/palari" ]]; then
		printf 'doctor: ok executable bin/palari\n'
	else
		printf 'doctor: bin/palari is missing or not executable\n' >&2
		errors=$((errors + 1))
	fi
	doctor_check_file "lib/palari/core.bash" errors
	doctor_check_file "lib/palari/authority_lifecycle.bash" errors
	doctor_check_file "lib/palari/roles.bash" errors
	doctor_check_file "lib/palari/init_adopt.bash" errors
	doctor_check_file "lib/palari/proposals.bash" errors
	doctor_check_file "lib/palari/tickets_workspace.bash" errors
	doctor_check_file "lib/palari/agents_review_scope.bash" errors
	doctor_check_file "lib/palari/ci_accept.bash" errors
	doctor_check_file "lib/palari/dashboard_snapshot.bash" errors
	doctor_check_file "lib/palari/adapters_snapshot.bash" errors
	doctor_check_file "palari.config.yaml" errors
	if [[ -f "$ROOT/AGENTS.md" ]]; then
		printf 'doctor: ok file AGENTS.md\n'
	elif [[ -f "$ROOT/AGENTS.palari.md" ]]; then
		printf 'doctor: warning AGENTS.md exists elsewhere; merge AGENTS.palari.md into your agent contract\n' >&2
	else
		printf 'doctor: missing file AGENTS.md\n' >&2
		errors=$((errors + 1))
	fi
	doctor_check_file "contracts/ticket-lifecycle.md" errors
	doctor_check_file "contracts/adoption.md" errors
	doctor_check_file "contracts/authority-and-lifecycle.md" errors
	doctor_check_file "templates/technical-report.md" errors
	doctor_check_file "skills/orchestrator/SKILL.md" errors
	doctor_check_file "skills/adoption/SKILL.md" errors
	doctor_check_file "schemas/palari.config.schema.json" errors
	doctor_check_dir "$PROPOSED_DIR" errors
	doctor_check_dir "$OPEN_DIR" errors
	doctor_check_dir "$CLOSED_DIR" errors
	doctor_check_dir "$REPORTS_DIR" errors
	doctor_check_dir "$PLANNING_REPORTS_DIR" errors
	doctor_check_dir "$EVIDENCE_DIR" errors
	doctor_check_dir "$HANDOFFS_DIR" errors
	if [[ -d "$ROOT/$ROLES_ACTIVE_DIR" || -d "$ROOT/$ROLES_PROPOSED_DIR" || -d "$ROOT/$ROLES_REVOKED_DIR" ]]; then
		doctor_check_dir "$ROLES_ACTIVE_DIR" errors
		doctor_check_dir "$ROLES_PROPOSED_DIR" errors
		doctor_check_dir "$ROLES_REVOKED_DIR" errors
	else
		printf 'doctor: optional role directories not installed; run ./bin/palari init to add them\n'
	fi
	if [[ -f "$ROOT/.github/workflows/palari.yml" ]]; then
		printf 'doctor: ok optional GitHub workflow\n'
	else
		printf 'doctor: optional GitHub workflow not installed; run ./bin/palari init --ci when ready\n'
	fi
	if ((errors == 0)); then
		printf 'doctor: ok\n'
	else
		printf 'doctor: failed with %s issue(s)\n' "$errors" >&2
		exit 1
	fi
}

adoption_target_abs() {
	local target="$1"
	[[ -d "$target" ]] || die "adopt target directory not found: $target"
	(cd "$target" && pwd)
}

copy_adoption_path() {
	local rel="$1"
	local target="$2"
	local force="$3"
	local dry_run="$4"
	local src="$ROOT/$rel"
	local dest="$target/$rel"
	[[ -e "$src" ]] || die "adopt source missing: $rel"
	if [[ -e "$dest" ]]; then
		if [[ "$force" == "true" ]]; then
			printf 'adopt: overwrite %s\n' "$rel"
			[[ "$dry_run" == "true" ]] || rm -rf "$dest"
		else
			printf 'adopt: kept existing %s\n' "$rel"
			return 0
		fi
	else
		printf 'adopt: write %s\n' "$rel"
	fi
	if [[ "$dry_run" == "true" ]]; then
		return 0
	fi
	mkdir -p "$(dirname "$dest")"
	cp -R "$src" "$dest"
}

copy_agent_contract() {
	local target="$1"
	local force="$2"
	local dry_run="$3"
	local dest="$target/AGENTS.md"
	local alt="$target/AGENTS.palari.md"
	if [[ -e "$dest" && "$force" != "true" ]]; then
		printf 'adopt: kept existing AGENTS.md\n'
		if [[ -e "$alt" ]]; then
			printf 'adopt: kept existing AGENTS.palari.md\n'
		else
			printf 'adopt: write AGENTS.palari.md for merge\n'
			[[ "$dry_run" == "true" ]] || cp "$ROOT/AGENTS.md" "$alt"
		fi
		return 0
	fi
	if [[ -e "$dest" ]]; then
		printf 'adopt: overwrite AGENTS.md\n'
	else
		printf 'adopt: write AGENTS.md\n'
	fi
	if [[ "$dry_run" != "true" ]]; then
		cp "$ROOT/AGENTS.md" "$dest"
	fi
}

cmd_adopt() {
	local target="${1:-}"
	shift || true
	[[ -n "$target" ]] || die "adopt requires target repository path"
	local with_ci="false" with_hooks="false" force="false" dry_run="false" arg target_abs rel
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--ci)
			with_ci="true"
			shift
			;;
		--hooks)
			with_hooks="true"
			shift
			;;
		--all)
			with_ci="true"
			with_hooks="true"
			shift
			;;
		--force)
			force="true"
			shift
			;;
		--dry-run)
			dry_run="true"
			shift
			;;
		*) die "unknown adopt option: $arg" ;;
		esac
	done
	target_abs="$(adoption_target_abs "$target")"
	[[ "$target_abs" != "$ROOT" ]] || die "adopt target is this Palari package; run ./bin/palari init instead"
	if ! git -C "$target_abs" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		die "adopt target must be an existing git repository: $target_abs"
	fi
	printf 'adopt: source %s\n' "$ROOT"
	printf 'adopt: target %s\n' "$target_abs"
	for rel in "${ADOPTION_PATHS[@]}"; do
		copy_adoption_path "$rel" "$target_abs" "$force" "$dry_run"
	done
	copy_agent_contract "$target_abs" "$force" "$dry_run"
	if [[ "$dry_run" == "true" ]]; then
		printf 'adopt: dry-run complete\n'
		return 0
	fi
	chmod +x "$target_abs/bin/palari" "$target_abs/scripts/palari"
	local -a init_args=()
	[[ "$with_ci" == "true" ]] && init_args+=("--ci")
	[[ "$with_hooks" == "true" ]] && init_args+=("--hooks")
	PALARI_ROOT="$target_abs" "$target_abs/bin/palari" init "${init_args[@]}" >/dev/null
	PALARI_ROOT="$target_abs" "$target_abs/bin/palari" doctor
	printf 'adopt: ok\n'
	printf 'next:\n'
	printf '  cd %s\n' "$(shell_quote "$target_abs")"
	printf '  ./bin/palari status\n'
	printf '  ./bin/palari propose create APP-PROP-0001 "First scoped change" --intent "Describe the change you want."\n'
	if [[ "$with_ci" == "true" ]]; then
		printf '  ./bin/palari github ruleset-command --repo OWNER/REPO\n'
	fi
}
