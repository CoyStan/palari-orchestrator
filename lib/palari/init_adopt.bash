palari_init_dirs() {
	printf '%s\n' \
		"$PROPOSED_DIR" "$OPEN_DIR" "$CLOSED_DIR" "$REPORTS_DIR" \
		"$HUMAN_REPORTS_DIR" "$PLANNING_REPORTS_DIR" "$EVIDENCE_DIR" \
		"$HANDOFFS_DIR" "$ROLES_ACTIVE_DIR" "$ROLES_PROPOSED_DIR" \
		"$ROLES_REVOKED_DIR" "$GOALS_ACTIVE_DIR" "$GOALS_PROPOSED_DIR" \
		"$GOALS_CLOSED_DIR" "$WORKFLOWS_PROPOSED_DIR" "$WORKFLOWS_ACTIVE_DIR" \
		"$WORKFLOWS_CLOSED_DIR" "$HUMANS_PROPOSED_DIR" "$HUMANS_ACTIVE_DIR" \
		"$HUMANS_REVOKED_DIR" "$POLICIES_PROPOSED_DIR" "$POLICIES_ACTIVE_DIR" \
		"$POLICIES_REVOKED_DIR" "$OUTCOMES_OPEN_DIR" "$OUTCOMES_RECORDED_DIR" \
		"$DECISIONS_OPEN_DIR" "$DECISIONS_DECIDED_DIR"
}
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
	while IFS= read -r dir; do
		mkdir -p "$ROOT/$dir"
		: >"$ROOT/$dir/.gitkeep"
	done < <(palari_init_dirs)
	# shellcheck disable=SC2153 # STATE_DIR is loaded from the Palari config/core module.
	mkdir -p "$ROOT/${STATE_DIR}/locks"
	if declare -F hygiene_ensure_gitignore >/dev/null; then
		hygiene_ensure_gitignore
	fi
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
	(cmd_report_lint "$ticket_id") >/dev/null 2>&1
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
			printf 'review ready: palari ticket ready %s\n' "$id"
		elif ! ticket_evidence_present_quiet "$id"; then
			printf 'evidence needed: palari worktree %s; palari packet %s specialist; palari ci %s --base %s\n' "$id" "$id" "$id" "$target"
		else
			printf 'reports needed: palari packet %s specialist; verify with palari lint %s\n' "$id" "$id"
		fi
		;;
	in-review)
		if ! ticket_evidence_present_quiet "$id"; then
			printf 'evidence needed: create evidence: palari ci %s --base %s\n' "$id" "$target"
		elif ! ticket_report_lint_quiet "$id"; then
			printf 'reviewer reports needed: palari packet %s reviewer; verify with palari lint %s\n' "$id" "$id"
		else
			printf 'acceptance: %s (or reopen: palari ticket reopen %s to send back)\n' "$(accept_command_for_ticket "$file" "$id" "founder" "palari")" "$id"
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
	local proposals active accepted reports human evidence changed generated_dirty source_dirty
	proposals="$(proposal_files | wc -l | tr -d ' ')"
	active="$(ticket_files | wc -l | tr -d ' ')"
	accepted="$(closed_ticket_files | wc -l | tr -d ' ')"
	reports="$(find "$ROOT/$REPORTS_DIR" -maxdepth 1 -type f \( -name '*.md' -o -name '*.markdown' \) ! -name 'README.md' | wc -l | tr -d ' ')"
	human="$(find "$ROOT/$HUMAN_REPORTS_DIR" -maxdepth 1 -type f \( -name '*.md' -o -name '*.markdown' \) ! -name 'README.md' | wc -l | tr -d ' ')"
	evidence="$(find "$ROOT/$EVIDENCE_DIR" -type f ! -name '.gitkeep' 2>/dev/null | wc -l | tr -d ' ')"
	if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		if declare -F hygiene_dirty_counts >/dev/null; then
			hygiene_dirty_counts changed generated_dirty source_dirty
		else
			changed="$(git_changed_count_at "$ROOT")"
			generated_dirty="0"
			source_dirty="$changed"
		fi
	else
		changed="not-a-git-repo"
		generated_dirty="0"
		source_dirty="0"
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
	if [[ "$changed" == "not-a-git-repo" ]]; then
		printf 'git: not-a-git-repo\n'
	else
		printf 'git: %s changed paths in workspace (%s generated, %s source)\n' "$changed" "$generated_dirty" "$source_dirty"
	fi
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
secure_doctor_bool() {
	local section="$1" key="$2" default="$3"
	[[ "$(cfg_nested "$section" "$key" "$default")" == "true" ]]
}
secure_doctor_broker_observations_available() {
	local found
	found="$(find "$ROOT/$EVIDENCE_DIR" -path '*/broker/*/summary.json' -type f -print -quit 2>/dev/null || true)"
	[[ -n "$found" ]]
}
secure_doctor_accept_enforces_human_quorum() {
	type accept_enforces_human_quorum >/dev/null 2>&1 || return 1
	accept_enforces_human_quorum
}
cmd_secure_doctor() {
	local gate_configured="false" gate_ready="false" broker_real="false" broker_boundary="false"
	local policy_acceptance="false" r5_human_quorum_configured="0" r5_human_quorum_enforced="false" broker_observations="false"
	local policy_simulation_only="true"
	local posture="weak"
	secure_doctor_bool gate enabled false && gate_configured="true"
	if [[ "$gate_configured" == "true" ]] && gate_available; then
		gate_ready="true"
	fi
	secure_doctor_bool governance broker_real_side_effects_enabled false && broker_real="true"
	secure_doctor_bool governance broker_security_boundary_enabled false && broker_boundary="true"
	secure_doctor_bool governance policy_acceptance_enabled false && policy_acceptance="true"
	[[ "$policy_acceptance" == "true" ]] && policy_simulation_only="false"
	if type accept_human_approval_quorum_for_risk >/dev/null 2>&1; then
		r5_human_quorum_configured="$(accept_human_approval_quorum_for_risk R5)"
	fi
	secure_doctor_accept_enforces_human_quorum && r5_human_quorum_enforced="true"
	secure_doctor_broker_observations_available && broker_observations="true"
	if [[ "$gate_ready" == "true" && "$broker_real" == "false" && "$policy_acceptance" == "false" && "$r5_human_quorum_configured" -ge 1 && "$r5_human_quorum_enforced" == "true" && "$broker_observations" == "true" ]]; then
		posture="stronger"
	fi
	printf 'Palari secure governance doctor\n'
	printf 'root: %s\n' "$ROOT"
	printf 'R5 human approval quorum configured: %s\n' "$r5_human_quorum_configured"
	printf 'R5 human approval quorum enforced by accept: %s\n' "$r5_human_quorum_enforced"
	printf 'Policy acceptance real mode enabled: %s\n' "$policy_acceptance"
	printf 'Policy acceptance simulation-only: %s\n' "$policy_simulation_only"
	printf 'Broker real side effects enabled: %s\n' "$broker_real"
	printf 'Broker is a security boundary: %s\n' "$broker_boundary"
	printf 'Broker observations available: %s\n' "$broker_observations"
	printf 'ForgeGate enabled: %s\n' "$gate_configured"
	printf 'ForgeGate enforcement available: %s\n' "$gate_ready"
	printf 'Branch protection verified locally: false\n'
	printf 'Posture: %s\n' "$posture"
	cat <<'DOCTOR'
Recommended modes:
- local/demo: ForgeGate optional
- R2+ team work: require ForgeGate policy before acceptance
- R5: require a configured and enforced human approval quorum before real autonomous governance
Local verification limits:
- This doctor does not verify hosted branch protection or remote rulesets.
- Do not claim branch protection is active from this local output alone.
DOCTOR
}
cmd_doctor() {
	if [[ "${1:-}" == "lifecycle" ]]; then
		shift
		cmd_lifecycle_audit "$@"
		return 0
	fi
	if [[ "${1:-}" == "secure" || "${1:-}" == "governance" ]]; then
		shift
		[[ -z "${1:-}" ]] || die "unknown doctor option: $1"
		cmd_secure_doctor
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
	doctor_check_file "lib/palari/hygiene.bash" errors
	doctor_check_file "lib/palari/proposals.bash" errors
	doctor_check_file "lib/palari/tickets_workspace.bash" errors
	doctor_check_file "lib/palari/demo.bash" errors
	doctor_check_file "lib/palari/prompt.bash" errors
	doctor_check_file "lib/palari/agents_review_scope.bash" errors
	doctor_check_file "lib/palari/ci_accept.bash" errors
	doctor_check_file "lib/palari/dashboard_snapshot.bash" errors
	doctor_check_file "lib/palari/adapters_snapshot.bash" errors
	doctor_check_file "lib/palari/gate.bash" errors
	doctor_check_file "lib/palari/goals.bash" errors
	doctor_check_file "lib/palari/workflows.bash" errors
	doctor_check_file "lib/palari/humans.bash" errors
	doctor_check_file "lib/palari/burden.bash" errors
	doctor_check_file "lib/palari/decisions.bash" errors
	doctor_check_file "lib/palari/run.bash" errors
	doctor_check_file "adapters/gate/palari_gate.py" errors
	doctor_check_file "gate/forgegate/gate.py" errors
	doctor_check_file "layouts/palari-change.yml" errors
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
	# Strict YAML audit: Palari's own parser is tolerant, but tickets, roles,
	# goals, and decisions must stay valid YAML for external tooling. Uses
	# python3+PyYAML when present; degrades to a warning when absent.
	if command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; then
		local yaml_bad
		yaml_bad="$(
			python3 - "$ROOT" <<'PYEOF'
import sys, glob, os
import yaml
root = sys.argv[1]
bad = 0
patterns = ["tickets/**/*.md", "roles/**/*.md", "goals/**/*.md", "decisions/**/*.md"]
for pattern in patterns:
    for f in glob.glob(os.path.join(root, pattern), recursive=True):
        try:
            s = open(f, encoding="utf-8").read()
        except OSError:
            continue
        if not s.startswith("---"):
            continue
        parts = s.split("---", 2)
        if len(parts) < 3:
            continue
        try:
            yaml.safe_load(parts[1])
        except yaml.YAMLError as e:
            print(f"{os.path.relpath(f, root)}: {str(e).splitlines()[0]}", file=sys.stderr)
            bad += 1
print(bad)
PYEOF
		)"
		if [[ "$yaml_bad" == "0" ]]; then
			printf 'doctor: ok strict yaml frontmatter\n'
		else
			printf 'doctor: %s file(s) with invalid YAML frontmatter (see above)\n' "$yaml_bad" >&2
			errors=$((errors + 1))
		fi
	else
		printf 'doctor: warning python3+PyYAML unavailable; skipping strict YAML frontmatter audit\n'
	fi
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
	gate_doctor_report
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
adoption_git_head_or_unavailable() {
	local repo_abs="$1"
	if git -C "$repo_abs" rev-parse --verify -q HEAD >/dev/null 2>&1; then
		git -C "$repo_abs" rev-parse --verify HEAD
	else
		printf 'unavailable\n'
	fi
}
adoption_source_ref() {
	if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		adoption_git_head_or_unavailable "$ROOT"
	else
		printf 'unavailable\n'
	fi
}
adoption_source_governance_history_path() {
	case "${1%/}" in tickets | tickets/* | reports | reports/* | memory | memory/* | tests | tests/* | humans | humans/* | workflows | workflows/* | policies | policies/* | outcomes | outcomes/* | goals | goals/* | decisions | decisions/* | handoffs | handoffs/*) return 0 ;; esac
	return 1
}
adoption_foreign_governance_artifacts() { printf '%s\n' "tickets/proposed, tickets/open, and tickets/closed records from the source repo" "reports, evidence bundles, human reports, and planning reports from the source repo" "memory and handoff records from the source repo" "source-repo tests and self-test artifacts" "human, workflow, policy, outcome, goal, and decision records from the source repo"; }
adoption_source_manifest_hash() {
	(
		cd "$ROOT"
		for rel in "${ADOPTION_PATHS[@]}" "AGENTS.md"; do
			adoption_source_governance_history_path "$rel" && continue
			if [[ -L "$rel" ]]; then
				printf '%s\n' "$rel"
			elif [[ -f "$rel" ]]; then
				printf '%s\n' "$rel"
			elif [[ -d "$rel" ]]; then
				find "$rel" \( -type f -o -type l \) -print | sort
			fi
		done |
			while IFS= read -r file; do
				[[ -n "$file" ]] || continue
				if [[ -L "$file" ]]; then
					printf 'symlink:%s  %s\n' "$(readlink "$file")" "$file"
				else
					printf 'file:%s  %s\n' "$(sha256_file "$file")" "$file"
				fi
			done
	) | sha256_text
}
target_config_scalar() {
	local target_abs="$1" key="$2" default="$3"
	local config="$target_abs/palari.config.yaml" value
	if [[ -f "$config" ]]; then
		value="$(
			awk -v key="$key" '
    $0 ~ "^[[:space:]]*" key ":" {
      sub("^[[:space:]]*" key ":[[:space:]]*", "", $0)
      sub(/[[:space:]]#.*$/, "", $0)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      gsub(/^["'\'']|["'\'']$/, "", $0)
      print
      exit
    }
  ' "$config"
		)"
	fi
	[[ -n "${value:-}" ]] && printf '%s\n' "$value" || printf '%s\n' "$default"
}
adoption_target_path_in_plan() {
	local target_abs="$1" with_ci="$2" with_hooks="$3" force="$4" path="$5"
	local planned
	path="${path%/}"
	while IFS= read -r planned; do
		planned="${planned#  - }"
		planned="${planned%/**}"
		planned="${planned%/.gitkeep}"
		[[ -n "$planned" ]] || continue
		if [[ "$path" == "$planned" || "$path" == "$planned/"* || "$planned" == "$path/"* ]]; then
			return 0
		fi
	done < <(adoption_plan_write_paths "$target_abs" "$with_ci" "$with_hooks" "$force")
	return 1
}
adoption_require_clean_target_worktree() {
	local target_abs="$1" with_ci="$2" with_hooks="$3" force="$4"
	local status ignored_line ignored_path
	status="$(git -C "$target_abs" status --porcelain=v1 --untracked-files=all)"
	[[ -z "$status" ]] ||
		die "adopt plan target worktree changed after plan; commit, stash, or remove target changes and regenerate the plan"
	while IFS= read -r ignored_line; do
		[[ "${ignored_line:0:2}" == "!!" ]] || continue
		ignored_path="${ignored_line:3}"
		ignored_path="${ignored_path%\"}"
		ignored_path="${ignored_path#\"}"
		if adoption_target_path_in_plan "$target_abs" "$with_ci" "$with_hooks" "$force" "$ignored_path"; then
			die "adopt plan target worktree changed after plan; ignored target path overlaps planned adoption write: $ignored_path"
		fi
	done < <(git -C "$target_abs" status --porcelain=v1 --untracked-files=all --ignored=matching)
}
target_init_dirs() {
	local target_abs="$1" force="$2"
	if [[ "$force" == "true" || ! -f "$target_abs/palari.config.yaml" ]]; then
		palari_init_dirs
		return
	fi
	printf '%s\n' \
		"$(target_config_scalar "$target_abs" tickets_proposed_dir "tickets/proposed")" \
		"$(target_config_scalar "$target_abs" tickets_open_dir "tickets/open")" \
		"$(target_config_scalar "$target_abs" tickets_closed_dir "tickets/closed")" \
		"$(target_config_scalar "$target_abs" reports_dir "reports")" \
		"$(target_config_scalar "$target_abs" human_reports_dir "reports/human")" \
		"$(target_config_scalar "$target_abs" planning_reports_dir "reports/planning")" \
		"$(target_config_scalar "$target_abs" evidence_dir "reports/evidence")" \
		"$(target_config_scalar "$target_abs" handoffs_dir "handoffs")" \
		"$(target_config_scalar "$target_abs" roles_active_dir "roles/active")" \
		"$(target_config_scalar "$target_abs" roles_proposed_dir "roles/proposed")" \
		"$(target_config_scalar "$target_abs" roles_revoked_dir "roles/revoked")" \
		"$(target_config_scalar "$target_abs" goals_active_dir "goals/active")" \
		"$(target_config_scalar "$target_abs" goals_proposed_dir "goals/proposed")" \
		"$(target_config_scalar "$target_abs" goals_closed_dir "goals/closed")" \
		"$(target_config_scalar "$target_abs" workflows_proposed_dir "workflows/proposed")" \
		"$(target_config_scalar "$target_abs" workflows_active_dir "workflows/active")" \
		"$(target_config_scalar "$target_abs" workflows_closed_dir "workflows/closed")" \
		"$(target_config_scalar "$target_abs" humans_proposed_dir "humans/proposed")" \
		"$(target_config_scalar "$target_abs" humans_active_dir "humans/active")" \
		"$(target_config_scalar "$target_abs" humans_revoked_dir "humans/revoked")" \
		"$(target_config_scalar "$target_abs" policies_proposed_dir "policies/proposed")" \
		"$(target_config_scalar "$target_abs" policies_active_dir "policies/active")" \
		"$(target_config_scalar "$target_abs" policies_revoked_dir "policies/revoked")" \
		"$(target_config_scalar "$target_abs" outcomes_open_dir "outcomes/open")" \
		"$(target_config_scalar "$target_abs" outcomes_recorded_dir "outcomes/recorded")" \
		"$(target_config_scalar "$target_abs" decisions_open_dir "decisions/open")" \
		"$(target_config_scalar "$target_abs" decisions_decided_dir "decisions/decided")"
}
target_state_dir() {
	local target_abs="$1" force="$2"
	if [[ "$force" == "true" || ! -f "$target_abs/palari.config.yaml" ]]; then
		printf '%s\n' "$STATE_DIR"
	else
		target_config_scalar "$target_abs" state_dir ".palari"
	fi
}
yaml_quote() {
	local value="${1:-}"
	value="${value//\\/\\\\}"
	value="${value//\"/\\\"}"
	printf '"%s"' "$value"
}
adoption_plan_write_paths() {
	local target_abs="$1" with_ci="$2" with_hooks="$3" force="$4" rel dir state_dir
	for rel in "${ADOPTION_PATHS[@]}"; do
		adoption_source_governance_history_path "$rel" && continue
		if [[ -d "$ROOT/$rel" ]]; then
			printf '  - %s/**\n' "$rel"
		else
			printf '  - %s\n' "$rel"
		fi
	done
	printf '  - AGENTS.md\n'
	printf '  - AGENTS.palari.md\n'
	while IFS= read -r dir; do
		[[ -n "$dir" ]] || continue
		printf '  - %s/.gitkeep\n' "$dir"
	done < <(target_init_dirs "$target_abs" "$force")
	state_dir="$(target_state_dir "$target_abs" "$force")"
	printf '  - %s/locks/**\n' "$state_dir"
	printf '  - .gitignore\n'
	if [[ "$with_ci" == "true" ]]; then
		printf '  - .github/workflows/palari.yml\n'
		printf '  - .github/palari-required-checks.ruleset.json\n'
	fi
	if [[ "$with_hooks" == "true" ]]; then
		printf '  - lefthook.yml\n'
	fi
}
adoption_plan_required_message() {
	printf 'adopt requires approved bootstrap/adoption plan before writing target files.\n' >&2
	printf 'run: ./bin/palari adopt plan TARGET --out ADOPTION-PLAN.md\n' >&2
	printf 'then have a human mark status: approved and rerun adopt with --plan ADOPTION-PLAN.md\n' >&2
}
cmd_adopt_plan() {
	local target="${1:-}" out="" with_ci="false" with_hooks="false" force="false" arg target_abs source_ref source_hash
	shift || true
	[[ -n "$target" ]] || die "adopt plan requires target repository path"
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--out)
			out="${2:-}"
			[[ -n "$out" ]] || die "adopt plan --out requires a path"
			shift 2
			;;
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
		*) die "unknown adopt plan option: $arg" ;;
		esac
	done
	[[ -n "$out" ]] || die "adopt plan requires --out PATH"
	target_abs="$(adoption_target_abs "$target")"
	[[ "$target_abs" != "$ROOT" ]] || die "adopt target is this Palari package; run ./bin/palari init instead"
	if ! git -C "$target_abs" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		die "adopt target must be an existing git repository: $target_abs"
	fi
	adoption_require_clean_target_worktree "$target_abs" "$with_ci" "$with_hooks" "$force"
	source_ref="$(adoption_source_ref)"
	source_hash="$(adoption_source_manifest_hash)"
	mkdir -p "$(dirname "$out")"
	{
		printf -- '---\n'
		printf 'type: bootstrap-adoption-plan\n'
		printf 'status: proposed\n'
		printf 'source_path: '
		yaml_quote "$ROOT"
		printf '\n'
		printf 'source_sha: '
		yaml_quote "$source_ref"
		printf '\n'
		printf 'source_manifest_hash: '
		yaml_quote "$source_hash"
		printf '\n'
		printf 'target_path: '
		yaml_quote "$target_abs"
		printf '\n'
		printf 'target_head: '
		yaml_quote "$(adoption_git_head_or_unavailable "$target_abs")"
		printf '\n'
		printf 'with_ci: %s\n' "$with_ci"
		printf 'with_hooks: %s\n' "$with_hooks"
		printf 'force: %s\n' "$force"
		printf 'approved_by:\n'
		printf 'approved_at:\n'
		printf 'path_manifest:\n'
		adoption_plan_write_paths "$target_abs" "$with_ci" "$with_hooks" "$force"
		printf 'excluded_paths:\n'
		printf '  - .git/**\n'
		printf '  - node_modules/**\n'
		printf '  - dist/**\n'
		printf '  - .env\n'
		printf '  - .env.*\n'
		printf 'excluded_foreign_governance_artifacts:\n'
		adoption_foreign_governance_artifacts | sed 's/^/  - /'
		printf 'downstream_customization_boundaries:\n'
		printf '  - Palari substrate files may be installed.\n'
		printf '  - Existing product source files must not be edited by adoption.\n'
		printf '  - Existing AGENTS.md is preserved unless --force is explicit.\n'
		printf -- '---\n\n'
		printf '# Palari Bootstrap Adoption Plan\n\n'
		printf 'Review this plan before running non-dry-run adoption.\n\n'
		printf "To approve, a human should change \`status: proposed\` to \`status: approved\` and fill \`approved_by\` and \`approved_at\`.\n"
	} >"$out"
	printf 'adopt plan: %s\n' "$out"
}
adoption_plan_list_items() {
	local plan="$1" key="$2"
	awk -v key="$key" '
    $0 == key ":" { in_list = 1; next }
    in_list && $0 ~ /^[^[:space:]][A-Za-z0-9_]+:/ { exit }
    in_list && $0 ~ /^[[:space:]]*-[[:space:]]+/ {
      sub(/^[[:space:]]*-[[:space:]]+/, "", $0)
      print
    }
  ' "$plan"
}
adoption_plan_has_list() {
	local plan="$1" key="$2"
	[[ -n "$(adoption_plan_list_items "$plan" "$key")" ]]
}
adoption_expected_path_manifest_hash() {
	local target_abs="$1" with_ci="$2" with_hooks="$3" force="$4"
	adoption_plan_write_paths "$target_abs" "$with_ci" "$with_hooks" "$force" |
		sed 's/^[[:space:]]*-[[:space:]]*//' |
		sha256_text
}
adoption_plan_path_manifest_hash() {
	local plan="$1"
	adoption_plan_list_items "$plan" path_manifest | sha256_text
}
validate_adoption_plan() {
	local plan="$1" target_abs="$2" with_ci="$3" with_hooks="$4" force="$5"
	local status source_path target_path source_ref plan_ref approved_by approved_at plan_with_ci plan_with_hooks plan_force
	local plan_target_head current_target_head
	local plan_hash source_hash expected_path_hash plan_path_hash
	[[ -f "$plan" ]] || die "adopt plan not found: $plan"
	status="$(frontmatter_value "$plan" status)"
	[[ "$status" == "approved" || "$status" == "accepted" ]] ||
		die "adopt plan must be approved before writing target files; current status: ${status:-missing}"
	approved_by="$(frontmatter_value "$plan" approved_by)"
	approved_at="$(frontmatter_value "$plan" approved_at)"
	[[ -n "$approved_by" ]] || die "adopt plan missing approved_by"
	[[ -n "$approved_at" ]] || die "adopt plan missing approved_at"
	source_path="$(frontmatter_value "$plan" source_path)"
	target_path="$(frontmatter_value "$plan" target_path)"
	[[ "$source_path" == "$ROOT" ]] ||
		die "adopt plan source mismatch: expected $ROOT, got ${source_path:-missing}"
	[[ "$target_path" == "$target_abs" ]] ||
		die "adopt plan target mismatch: expected $target_abs, got ${target_path:-missing}"
	plan_target_head="$(frontmatter_value "$plan" target_head)"
	current_target_head="$(adoption_git_head_or_unavailable "$target_abs")"
	if [[ "$plan_target_head" != "$current_target_head" ]]; then
		die "adopt plan target_head mismatch: expected $current_target_head, got $plan_target_head"
	fi
	adoption_require_clean_target_worktree "$target_abs" "$with_ci" "$with_hooks" "$force"
	plan_with_ci="$(frontmatter_value "$plan" with_ci)"
	plan_with_hooks="$(frontmatter_value "$plan" with_hooks)"
	plan_force="$(frontmatter_value "$plan" force)"
	[[ "$plan_with_ci" == "$with_ci" ]] ||
		die "adopt plan with_ci mismatch: expected $with_ci, got ${plan_with_ci:-missing}"
	[[ "$plan_with_hooks" == "$with_hooks" ]] ||
		die "adopt plan with_hooks mismatch: expected $with_hooks, got ${plan_with_hooks:-missing}"
	[[ "$plan_force" == "$force" ]] ||
		die "adopt plan force mismatch: expected $force, got ${plan_force:-missing}"
	plan_ref="$(frontmatter_value "$plan" source_sha)"
	source_ref="$(adoption_source_ref)"
	[[ -n "$plan_ref" ]] || die "adopt plan missing source_sha"
	: "$source_ref"
	plan_hash="$(frontmatter_value "$plan" source_manifest_hash)"
	source_hash="$(adoption_source_manifest_hash)"
	[[ "$plan_hash" == "$source_hash" ]] ||
		die "adopt plan source_manifest_hash mismatch: expected $source_hash, got ${plan_hash:-missing}"
	adoption_plan_has_list "$plan" path_manifest ||
		die "adopt plan missing path_manifest entries"
	expected_path_hash="$(adoption_expected_path_manifest_hash "$target_abs" "$with_ci" "$with_hooks" "$force")"
	plan_path_hash="$(adoption_plan_path_manifest_hash "$plan")"
	[[ "$plan_path_hash" == "$expected_path_hash" ]] ||
		die "adopt plan path_manifest mismatch"
	adoption_plan_has_list "$plan" excluded_paths ||
		die "adopt plan missing excluded_paths entries"
	adoption_plan_has_list "$plan" excluded_foreign_governance_artifacts ||
		die "adopt plan missing excluded_foreign_governance_artifacts entries"
	[[ "$(adoption_plan_list_items "$plan" excluded_foreign_governance_artifacts | sha256_text)" == "$(adoption_foreign_governance_artifacts | sha256_text)" ]] ||
		die "adopt plan excluded_foreign_governance_artifacts mismatch"
	adoption_plan_has_list "$plan" downstream_customization_boundaries ||
		die "adopt plan missing downstream_customization_boundaries entries"
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
	if [[ "$target" == "plan" ]]; then
		cmd_adopt_plan "$@"
		return
	fi
	[[ -n "$target" ]] || die "adopt requires target repository path"
	local with_ci="false" with_hooks="false" force="false" dry_run="false" plan="" governance_only="false" arg target_abs rel
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
		--plan)
			plan="${2:-}"
			[[ -n "$plan" ]] || die "adopt --plan requires a path"
			shift 2
			;;
		--governance-only | --session-only)
			governance_only="true"
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
	if [[ "$governance_only" == "true" ]]; then
		[[ "$with_ci" == "false" ]] || die "adopt --governance-only cannot install CI; use full adopt when the target needs local Palari runtime"
		[[ "$with_hooks" == "false" ]] || die "adopt --governance-only cannot install hooks; use full adopt when the target needs local Palari runtime"
	fi
	if [[ "$dry_run" != "true" && "$governance_only" != "true" ]]; then
		if [[ -z "$plan" ]]; then
			adoption_plan_required_message
			return 2
		fi
		validate_adoption_plan "$plan" "$target_abs" "$with_ci" "$with_hooks" "$force"
	fi
	printf 'adopt: source %s\n' "$ROOT"
	printf 'adopt: target %s\n' "$target_abs"
	if [[ "$governance_only" == "true" ]]; then
		cmd_adopt_governance_only "$target_abs" "$force" "$dry_run"
		return 0
	fi
	printf 'adopt: excludes upstream governance history\n'
	adoption_foreign_governance_artifacts | sed 's/^/adopt: exclude /'
	for rel in "${ADOPTION_PATHS[@]}"; do
		adoption_source_governance_history_path "$rel" && {
			printf 'adopt: skip upstream governance history %s\n' "$rel"
			continue
		}
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
