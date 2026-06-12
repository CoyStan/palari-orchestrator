# shellcheck shell=bash
# shellcheck disable=SC2153 # This module is sourced after core.bash, which defines shared globals.
cmd_skill_create() {
	local name="${1:-}"
	shift || true
	[[ -n "$name" ]] || die "skill create requires a lowercase skill name"

	local description="" dir="$AGENT_SKILLS_DIR" title
	while (($# > 0)); do
		case "$1" in
		--description)
			description="$2"
			shift 2
			;;
		--dir)
			dir="$2"
			shift 2
			;;
		*) die "unknown skill create option: $1" ;;
		esac
	done

	valid_skill_name "$name" ||
		die "invalid skill name: $name; use lowercase letters, numbers, and hyphens"
	[[ -n "$description" ]] || die "skill create requires --description TEXT"

	local skill_dir="$ROOT/$dir/$name"
	local skill_file="$skill_dir/SKILL.md"
	[[ ! -e "$skill_file" ]] || die "skill already exists: ${skill_file#"$ROOT"/}"

	mkdir -p "$skill_dir"
	title="$(titleize_slug "$name")"
	{
		printf -- '---\n'
		printf 'name: %s\n' "$name"
		printf 'description: %s\n' "$description"
		printf -- '---\n\n'
		printf '# %s\n\n' "$title"
		printf '## When This Applies\n\n'
		printf 'Use this when touching TODO paths, APIs, workflows, or reviews for this feature.\n\n'
		printf '## Feature Promise\n\n'
		printf 'State the user-facing or operator-facing promise this feature must preserve.\n\n'
		printf '## Invariants\n\n'
		printf -- '- TODO: invariant that future work must not break.\n'
		printf -- '- TODO: source-of-truth or data boundary that must remain true.\n\n'
		printf '## Owned Files And APIs\n\n'
		# shellcheck disable=SC2016 # Backticks are literal Markdown in generated skill text.
		printf -- '- TODO: `path/to/file`\n'
		printf -- '- TODO: API, command, or workflow surface\n\n'
		printf '## Forbidden Behavior\n\n'
		printf -- '- Do not move product truth, safety boundaries, or acceptance authority into this skill.\n'
		printf -- '- Do not add live external writes, secrets, production behavior, or broad framework changes unless a ticket explicitly scopes them.\n\n'
		printf '## Required Tests And Browser Paths\n\n'
		printf -- '- TODO: automated check, manual check, or rendered path required when this feature changes.\n\n'
		printf '## Gotchas\n\n'
		printf -- '- TODO: project-specific trap learned from prior tickets, reviews, or incidents.\n\n'
		printf '## Acceptance Checklist\n\n'
		printf -- '- The feature promise and invariants still hold.\n'
		printf -- '- Required tests or review paths were run, or a clear not-run reason is recorded.\n'
		printf -- '- No forbidden behavior was introduced.\n'
	} >"$skill_file"

	printf 'skill create: %s\n' "${skill_file#"$ROOT"/}"
}

skill_roots() {
	printf 'skills\n'
	printf '%s\n' "$AGENT_SKILLS_DIR"
	printf 'plugin/skills\n'
}

skill_files_in_root() {
	local root="$1"
	[[ -d "$ROOT/$root" ]] || return 0
	find "$ROOT/$root" -mindepth 2 -maxdepth 2 -type f -name SKILL.md | LC_ALL=C sort
}

all_skill_files() {
	local root
	while IFS= read -r root; do
		[[ -n "$root" ]] || continue
		skill_files_in_root "$root"
	done < <(skill_roots | awk '!seen[$0]++')
}

# Resolution order is the skill_roots order (skills, agent-skills,
# plugin/skills): a shipped skill wins over an adopter or plugin skill with
# the same name, deterministically.
find_skill_file() {
	local name="$1"
	local file
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		if [[ "$(frontmatter_value "$file" name)" == "$name" ]]; then
			printf '%s\n' "$file"
			return 0
		fi
	done < <(all_skill_files)
	return 1
}

# Heuristic guard, not a parser: flags grant-shaped sentences while skipping
# negated or human-gated ones, because skills may describe authority they must
# never claim ("only a human accepts") without tripping the linter.
skill_authority_claim_lines() {
	local file="$1"
	grep -inE '(this skill|the skill|this agent|the agent|skills) (may|can|is allowed to|is permitted to|is authorized to|grants?|allows?)[^.]*\b(accept|accepts|merge|merges|push|pushes)\b|overrid(e|es|ing)[^.]*AGENTS\.md' "$file" 2>/dev/null |
		grep -ivE '\b(not|never|cannot|only)\b' || true
}

cmd_skill_list() {
	local file rel name desc count=0
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		rel="${file#"$ROOT"/}"
		name="$(frontmatter_value "$file" name)"
		desc="$(frontmatter_value "$file" description)"
		[[ -n "$name" ]] || name="(missing-name)"
		printf '%s\t%s\n' "$name" "$rel"
		if [[ -n "$desc" ]]; then
			if ((${#desc} > 96)); then
				printf '  %s...\n' "${desc:0:96}"
			else
				printf '  %s\n' "$desc"
			fi
		fi
		count=$((count + 1))
	done < <(all_skill_files)
	printf 'skill list: %s skill(s)\n' "$count"
}

cmd_skill_lint() {
	local file rel name desc errors=0 count=0 pairs="" dup line
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		count=$((count + 1))
		rel="${file#"$ROOT"/}"
		if ! has_frontmatter "$file"; then
			printf 'skill-lint: %s: missing YAML frontmatter\n' "$rel" >&2
			errors=$((errors + 1))
			continue
		fi
		name="$(frontmatter_value "$file" name)"
		desc="$(frontmatter_value "$file" description)"
		if [[ -z "$name" ]]; then
			printf 'skill-lint: %s: missing frontmatter name\n' "$rel" >&2
			errors=$((errors + 1))
		elif ! valid_skill_name "$name"; then
			printf 'skill-lint: %s: invalid skill name: %s\n' "$rel" "$name" >&2
			errors=$((errors + 1))
		else
			# Names must be unique per skill root; the plugin packaging of a
			# shipped skill may legitimately reuse its name.
			pairs+="${rel%/*/SKILL.md} $name"$'\n'
		fi
		if [[ -z "$desc" ]]; then
			printf 'skill-lint: %s: missing frontmatter description\n' "$rel" >&2
			errors=$((errors + 1))
		fi
		while IFS= read -r line; do
			[[ -n "$line" ]] || continue
			printf 'skill-lint: %s: line %s claims authority a skill may never hold (accept/merge/push/override)\n' "$rel" "${line%%:*}" >&2
			errors=$((errors + 1))
		done < <(skill_authority_claim_lines "$file")
	done < <(all_skill_files)
	while IFS= read -r dup; do
		[[ -n "$dup" ]] || continue
		printf 'skill-lint: duplicate skill name in %s: %s\n' "${dup% *}" "${dup#* }" >&2
		errors=$((errors + 1))
	done < <(printf '%s' "$pairs" | sort | uniq -d)
	((errors == 0)) || {
		printf 'skill-lint: failed with %s issue(s)\n' "$errors" >&2
		exit 1
	}
	printf 'skill-lint: ok (%s skill(s))\n' "$count"
}

cmd_skill() {
	local sub="${1:-}"
	shift || true
	case "$sub" in
	create | new) cmd_skill_create "$@" ;;
	list) cmd_skill_list "$@" ;;
	lint) cmd_skill_lint "$@" ;;
	*) die "unknown skill command: ${sub:-}; try \`palari skill create NAME --description TEXT\`, \`palari skill list\`, or \`palari skill lint\`" ;;
	esac
}

cmd_mcp() {
	local sub="${1:-manifest}"
	case "$sub" in
	manifest | tools)
		cat "$ROOT/adapters/mcp/tools.json"
		;;
	*)
		die "unknown mcp command: $sub"
		;;
	esac
}

github_ci_ticket_id_from_file() {
	local path="$1"
	local abs="$ROOT/$path"
	local tmp="" id="" base
	if [[ -f "$abs" ]]; then
		frontmatter_value "$abs" id
		return
	fi
	if git -C "$ROOT" cat-file -e "HEAD:$path" 2>/dev/null; then
		tmp="$(mktemp)"
		git -C "$ROOT" show "HEAD:$path" >"$tmp"
		id="$(frontmatter_value "$tmp" id || true)"
		rm -f "$tmp"
		if [[ -n "$id" ]]; then
			printf '%s\n' "$id"
			return
		fi
	fi
	base="$(basename "$path")"
	if [[ "$base" =~ ^([A-Za-z][A-Za-z0-9]*-[0-9]+) ]]; then
		printf '%s\n' "${BASH_REMATCH[1]}"
	fi
}

github_ci_changed_ticket_ids() {
	local base_ref="$1"
	local path id file
	[[ -n "$base_ref" ]] || return 0
	git -C "$ROOT" rev-parse --verify "$base_ref" >/dev/null 2>&1 ||
		die "github ci base ref not found: $base_ref"
	while IFS= read -r path; do
		[[ -n "$path" ]] || continue
		id="$(github_ci_ticket_id_from_file "$path" || true)"
		[[ -n "$id" ]] || continue
		file="$(find_ticket_file "$id" || true)"
		[[ -n "$file" ]] || continue
		github_ci_should_include_changed_ticket "$base_ref" "$id" "$file" &&
			printf '%s\n' "$id"
	done < <(
		git -C "$ROOT" diff --name-only "$base_ref"...HEAD -- \
			"$OPEN_DIR/*.md" "$OPEN_DIR/*.markdown" \
			"$CLOSED_DIR/*.md" "$CLOSED_DIR/*.markdown"
	)
}

github_ci_should_include_changed_ticket() {
	local base_ref="$1"
	local ticket_id="$2"
	local file="$3"
	local status path
	status="$(frontmatter_value "$file" status)"
	[[ "$status" == "open" ]] || return 0

	while IFS= read -r path; do
		[[ -n "$path" ]] || continue
		case "$path" in
		"$OPEN_DIR/$ticket_id"-* | "$CLOSED_DIR/$ticket_id"-*) continue ;;
		esac
		[[ "$path" == *"$ticket_id"* ]] && return 0
	done < <(git_changed_paths "$base_ref")
	return 1
}

github_ci_no_ticket_message() {
	local base_ref="$1"
	cat >&2 <<EOF
error: github ci could not find a Palari ticket for this PR.

Palari checked:
- PALARI_TICKET_ID
- GITHUB_HEAD_REF matching ticket/TICKET-ID
- the current branch matching ticket/TICKET-ID
- changed ticket files under $OPEN_DIR/ and $CLOSED_DIR/ against ${base_ref:-BASE}...HEAD

Use one governed path:
- name the branch ticket/TICKET-ID
- include or move a ticket file under $OPEN_DIR/ or $CLOSED_DIR/
- set PALARI_TICKET_ID when the PR intentionally maps to one ticket

For maintenance-only repository checks, run:
- palari github ci --repo-only

Do not use --repo-only as a merge-gate substitute for ticketed agent work.
EOF
}

cmd_github_ci() {
	require_base_folders
	local base_ref="" evidence_dir="" repo_only="false" ticket="" branch_ticket="" arg
	local -a ticket_ids=()
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--base)
			base_ref="$2"
			shift 2
			;;
		--evidence-dir)
			evidence_dir="$2"
			shift 2
			;;
		--repo-only)
			repo_only="true"
			shift
			;;
		--*) die "unknown github ci option: $arg" ;;
		*) die "github ci does not accept positional ticket IDs; use palari ci TICKET-ID for direct local runs" ;;
		esac
	done
	[[ -n "$base_ref" ]] || base_ref="${GITHUB_BASE_REF:-$DEFAULT_BRANCH}"

	if [[ "$repo_only" == "true" ]]; then
		local -a repo_args=(--repo-only)
		[[ -n "$base_ref" ]] && repo_args+=(--base "$base_ref")
		[[ -n "$evidence_dir" ]] && repo_args+=(--evidence-dir "$evidence_dir")
		cmd_ci "${repo_args[@]}"
		return
	fi

	ticket="${PALARI_TICKET_ID:-}"
	if [[ -n "$ticket" ]]; then
		ticket_ids+=("$ticket")
	else
		if [[ "${GITHUB_HEAD_REF:-}" == ticket/* ]]; then
			branch_ticket="${GITHUB_HEAD_REF#ticket/}"
		else
			branch_ticket="$(infer_ticket_from_branch || true)"
		fi
		[[ -n "$branch_ticket" ]] && ticket_ids+=("$branch_ticket")
	fi
	if ((${#ticket_ids[@]} == 0)); then
		mapfile -t ticket_ids < <(github_ci_changed_ticket_ids "$base_ref" | sed '/^$/d' | sort -u)
	fi
	if ((${#ticket_ids[@]} == 0)); then
		github_ci_no_ticket_message "$base_ref"
		exit 2
	fi

	printf 'github ci: tickets: %s\n' "${ticket_ids[*]}"
	local -a ci_args=(--base "$base_ref")
	[[ -n "$evidence_dir" ]] && ci_args+=(--evidence-dir "$evidence_dir")
	cmd_ci "${ci_args[@]}" "${ticket_ids[@]}"
}

cmd_github() {
	local sub="${1:-}"
	shift || true
	local repo="" file=".github/palari-required-checks.ruleset.json" arg ruleset_name jq_filter ruleset_id
	if [[ "$sub" == "ci" ]]; then
		cmd_github_ci "$@"
		return
	fi
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--repo)
			repo="$2"
			shift 2
			;;
		--file)
			file="$2"
			shift 2
			;;
		*) die "unknown github option: $arg" ;;
		esac
	done
	[[ -n "$repo" ]] || repo="$(github_repo_slug || true)"
	[[ -n "$repo" ]] || repo="OWNER/REPO"
	case "$sub" in
	ruleset-command)
		ruleset_activation_command "$repo" "$file"
		;;
	install-ruleset)
		[[ "$repo" != "OWNER/REPO" ]] || die "install-ruleset needs --repo OWNER/REPO or a GitHub origin remote"
		[[ -f "$ROOT/$file" ]] || die "ruleset file not found: $file"
		command -v gh >/dev/null 2>&1 || die "install-ruleset requires GitHub CLI: gh"
		ruleset_name="$(ruleset_name_from_file "$file")"
		jq_filter=".[] | select(.name == \"$ruleset_name\") | .id"
		ruleset_id="$(gh api "repos/$repo/rulesets" --jq "$jq_filter" 2>/dev/null || true)"
		ruleset_id="${ruleset_id%%$'\n'*}"
		if [[ -n "$ruleset_id" ]]; then
			gh api --method PATCH "repos/$repo/rulesets/$ruleset_id" --input "$ROOT/$file"
			printf 'github install-ruleset: updated %s (%s)\n' "$ruleset_name" "$ruleset_id"
		else
			gh api --method POST "repos/$repo/rulesets" --input "$ROOT/$file"
			printf 'github install-ruleset: created %s\n' "$ruleset_name"
		fi
		;;
	*)
		die "unknown github command: ${sub:-}; try \`palari github ci\` or \`palari github ruleset-command\`"
		;;
	esac
}

capture_command_json() {
	local out err code
	out="$(mktemp)"
	err="$(mktemp)"
	set +e
	"$@" >"$out" 2>"$err"
	code=$?
	set -e
	printf '{"ok":'
	[[ "$code" == "0" ]] && printf 'true' || printf 'false'
	printf ',"code":%s,"stdout":' "$code"
	json_string "$(cat "$out")"
	printf ',"stderr":'
	json_string "$(cat "$err")"
	printf '}'
	rm -f "$out" "$err"
}

ticket_lease_status() {
	local file="$1"
	local claim_ref expires now_epoch expires_epoch remaining
	claim_ref="$(frontmatter_value "$file" claim_ref)"
	expires="$(frontmatter_value "$file" claim_expires_at)"
	if [[ -z "$claim_ref" && -z "$expires" ]]; then
		printf 'none\n'
		return 0
	fi
	now_epoch="$(epoch_utc)"
	expires_epoch="$(epoch_from_iso "$expires")"
	if [[ "$expires_epoch" == "0" ]]; then
		printf 'active\n'
		return 0
	fi
	remaining=$((expires_epoch - now_epoch))
	if ((remaining < 0)); then
		printf 'expired\n'
	elif ((remaining < 90)); then
		printf 'expiring\n'
	else
		printf 'active\n'
	fi
}

ticket_lease_remaining() {
	local file="$1"
	local expires now_epoch expires_epoch remaining
	expires="$(frontmatter_value "$file" claim_expires_at)"
	expires_epoch="$(epoch_from_iso "$expires")"
	[[ "$expires_epoch" != "0" ]] || {
		printf 'null'
		return 0
	}
	now_epoch="$(epoch_utc)"
	remaining=$((expires_epoch - now_epoch))
	((remaining < 0)) && remaining=0
	printf '%s' "$remaining"
}

evidence_json() {
	local ticket_id="$1"
	local dir="$ROOT/$EVIDENCE_DIR/$ticket_id"
	local rel="" files has_log="false" has_junit="false" has_sarif="false" has_manifest="false" count=0
	[[ -d "$dir" ]] && rel="${dir#"$ROOT"/}"
	files="$(json_file_list "$dir")"
	[[ -f "$dir/verification.log" ]] && has_log="true"
	[[ -f "$dir/junit.xml" ]] && has_junit="true"
	[[ -f "$dir/palari.sarif" ]] && has_sarif="true"
	[[ -f "$dir/manifest.json" ]] && has_manifest="true"
	if [[ -d "$dir" ]]; then
		count="$(find "$dir" -maxdepth 1 -type f ! -name '.gitkeep' | wc -l | tr -d ' ')"
	fi
	printf '{"path":'
	json_string "$rel"
	printf ',"files":%s,"has_log":%s,"has_junit":%s,"has_sarif":%s,"has_manifest":%s,"file_count":%s}' \
		"$files" "$has_log" "$has_junit" "$has_sarif" "$has_manifest" "$count"
}

reports_json() {
	local ticket_id="$1"
	local file technical reviewer human required_report custom_report first="true"
	file="$(find_ticket_file "$ticket_id" || true)"
	technical="$(find_report_file "$REPORTS_DIR" "$ticket_id" '(^# .*Technical Report$|^## Files Changed$|^## Verification$|^## Risks / Follow-Ups$)' || true)"
	reviewer="$(find_report_file "$REPORTS_DIR" "$ticket_id" '(^# .*Reviewer Note$|^## Review Result$|^## Required Changes$)' || true)"
	human="$(find_report_file "$HUMAN_REPORTS_DIR" "$ticket_id" || true)"
	printf '{"technical":%s,"reviewer":%s,"human":%s,"custom":[' \
		"$(json_nonempty_bool "$technical")" \
		"$(json_nonempty_bool "$reviewer")" \
		"$(json_nonempty_bool "$human")"
	if [[ -n "$file" ]]; then
		while IFS= read -r required_report; do
			[[ -n "$required_report" ]] || continue
			case "$required_report" in
			specialist | technical | reviewer | human | founder) continue ;;
			esac
			custom_report="$(find_named_report_file "$ticket_id" "$required_report" || true)"
			[[ "$first" == "true" ]] || printf ','
			printf '{"name":'
			json_string "$required_report"
			printf ',"present":%s}' "$(json_nonempty_bool "$custom_report")"
			first="false"
		done < <(ticket_required_reports "$file" | awk '!seen[$0]++')
	fi
	printf ']}'
}

ticket_required_reports_json() {
	local file="$1"
	local item first="true"
	printf '['
	while IFS= read -r item; do
		[[ -n "$item" ]] || continue
		[[ "$first" == "true" ]] || printf ','
		json_string "$item"
		first="false"
	done < <(ticket_required_reports "$file" | awk '!seen[$0]++')
	printf ']'
}

snapshot_ticket_json() {
	local file="$1"
	local state="$2"
	local mode="${3:-full}"
	local ticket_id title status risk priority stream rel claimed_by claimed_at claim_ref expires heartbeat branch worktree lease_status
	local created_by_role delegated_to_role accepted_by accepted_at implemented_by
	ticket_id="$(frontmatter_value "$file" id)"
	[[ -n "$ticket_id" ]] || ticket_id="$(ticket_title_from_file "$file")"
	title="$(frontmatter_value "$file" title)"
	[[ -n "$title" ]] || title="$ticket_id"
	status="$(frontmatter_value "$file" status)"
	[[ -n "$status" ]] || status="$([[ "$state" == "accepted" ]] && printf accepted || printf open)"
	risk="$(frontmatter_value "$file" risk)"
	priority="$(frontmatter_value "$file" priority)"
	stream="$(frontmatter_value "$file" stream)"
	rel="${file#"$ROOT"/}"
	claimed_by="$(frontmatter_value "$file" claimed_by)"
	claimed_at="$(frontmatter_value "$file" claimed_at)"
	claim_ref="$(frontmatter_value "$file" claim_ref)"
	expires="$(frontmatter_value "$file" claim_expires_at)"
	heartbeat="$(frontmatter_value "$file" claim_heartbeat_at)"
	created_by_role="$(frontmatter_value "$file" created_by_role)"
	[[ -n "$created_by_role" ]] || created_by_role="$(frontmatter_value "$file" issued_by_role)"
	delegated_to_role="$(frontmatter_value "$file" delegated_to_role)"
	[[ -n "$delegated_to_role" ]] || delegated_to_role="$(frontmatter_value "$file" delegate_to_role)"
	accepted_by="$(frontmatter_value "$file" accepted_by)"
	accepted_at="$(frontmatter_value "$file" accepted_at)"
	implemented_by="$(frontmatter_value "$file" implemented_by)"
	branch="$(ticket_declared_branch "$file" "$ticket_id")"
	worktree="$(ticket_declared_worktree "$file" "$ticket_id")"
	lease_status="$(ticket_lease_status "$file")"
	printf '{"id":'
	json_string "$ticket_id"
	printf ',"title":'
	json_string "$title"
	printf ',"status":'
	json_string "$status"
	printf ',"risk":'
	json_string "${risk:-R1}"
	printf ',"priority":'
	json_string "${priority:-P2}"
	printf ',"stream":'
	json_string "${stream:-process}"
	printf ',"state":'
	json_string "$state"
	printf ',"path":'
	json_string "$rel"
	printf ',"allowed_paths":'
	json_frontmatter_list "$file" allowed_paths
	printf ',"forbidden_paths":'
	json_frontmatter_list "$file" forbidden_paths
	printf ',"verification":'
	json_frontmatter_list "$file" verification
	printf ',"required_reports":'
	ticket_required_reports_json "$file"
	printf ',"claimed_by":'
	json_string "$claimed_by"
	printf ',"claimed_at":'
	json_string "$claimed_at"
	printf ',"created_by_role":'
	json_string "$created_by_role"
	printf ',"delegated_to_role":'
	json_string "$delegated_to_role"
	printf ',"accepted_by":'
	json_string "$accepted_by"
	printf ',"accepted_at":'
	json_string "$accepted_at"
	printf ',"implemented_by":'
	json_string "$implemented_by"
	printf ',"claim_ref":'
	json_string "$claim_ref"
	printf ',"claim_expires_at":'
	json_string "$expires"
	printf ',"claim_heartbeat_at":'
	json_string "$heartbeat"
	printf ',"requires_review":%s,"requires_human_confirmation":%s' \
		"$(json_bool "$(frontmatter_value "$file" requires_review)")" \
		"$(json_bool "$(frontmatter_value "$file" requires_human_confirmation)")"
	printf ',"branch":'
	json_string "$branch"
	printf ',"worktree":'
	json_string "$worktree"
	printf ',"evidence":'
	evidence_json "$ticket_id"
	printf ',"reports":'
	reports_json "$ticket_id"
	printf ',"next_action":'
	snapshot_next_action_json "$file" "$state" "$mode"
	printf ',"lease":{"status":'
	json_string "$lease_status"
	printf ',"expires_at":'
	json_string "$expires"
	printf ',"seconds_remaining":'
	ticket_lease_remaining "$file"
	printf '}}'
}

snapshot_tickets_json() {
	local mode="${1:-fast}"
	local file first="true"
	printf '['
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		[[ "$first" == "true" ]] || printf ','
		if [[ "$mode" == "full" ]]; then
			snapshot_ticket_json "$file" "active" "$mode"
		else
			snapshot_ticket_fast_json "$file" "active"
		fi
		first="false"
	done < <(ticket_files)
	if [[ "$mode" == "full" ]]; then
		while IFS= read -r file; do
			[[ -n "$file" ]] || continue
			[[ "$first" == "true" ]] || printf ','
			snapshot_ticket_json "$file" "accepted" "$mode"
			first="false"
		done < <(closed_ticket_files)
	fi
	printf ']'
}

snapshot_proposal_json() {
	local file="$1"
	local proposal_id title status planner model rel adopted_ticket adopted_at
	proposal_id="$(frontmatter_value "$file" id)"
	title="$(frontmatter_value "$file" title)"
	status="$(frontmatter_value "$file" status)"
	planner="$(frontmatter_value "$file" planner)"
	model="$(frontmatter_value "$file" model)"
	adopted_ticket="$(frontmatter_value "$file" adopted_ticket)"
	adopted_at="$(frontmatter_value "$file" adopted_at)"
	rel="${file#"$ROOT"/}"
	printf '{"id":'
	json_string "$proposal_id"
	printf ',"title":'
	json_string "$title"
	printf ',"status":'
	json_string "$status"
	printf ',"planner":'
	json_string "$planner"
	printf ',"model":'
	json_string "$model"
	printf ',"path":'
	json_string "$rel"
	printf ',"adopted_ticket":'
	json_string "$adopted_ticket"
	printf ',"adopted_at":'
	json_string "$adopted_at"
	printf '}'
}

snapshot_proposals_json() {
	local file first="true"
	printf '['
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		[[ "$first" == "true" ]] || printf ','
		snapshot_proposal_json "$file"
		first="false"
	done < <(proposal_files)
	printf ']'
}

snapshot_overlaps_json() {
	local left_file right_file left_id right_id left_pattern right_pattern right_status first="true"
	printf '['
	while IFS= read -r left_file; do
		[[ -n "$left_file" ]] || continue
		left_id="$(frontmatter_value "$left_file" id)"
		while IFS= read -r right_file; do
			[[ -n "$right_file" && "$right_file" != "$left_file" ]] || continue
			right_status="$(frontmatter_value "$right_file" status)"
			case "$right_status" in
			open | claimed | reopened | in-review) ;;
			*) continue ;;
			esac
			right_id="$(frontmatter_value "$right_file" id)"
			[[ "$left_id" < "$right_id" ]] || continue
			while IFS= read -r left_pattern; do
				[[ -n "$left_pattern" ]] || continue
				while IFS= read -r right_pattern; do
					[[ -n "$right_pattern" ]] || continue
					if patterns_overlap "$left_pattern" "$right_pattern"; then
						[[ "$first" == "true" ]] || printf ','
						printf '{"left":'
						json_string "$left_id"
						printf ',"right":'
						json_string "$right_id"
						printf ',"left_pattern":'
						json_string "$left_pattern"
						printf ',"right_pattern":'
						json_string "$right_pattern"
						printf '}'
						first="false"
					fi
				done < <(frontmatter_list_items "$right_file" allowed_paths)
			done < <(frontmatter_list_items "$left_file" allowed_paths)
		done < <(ticket_files)
	done < <(ticket_files)
	printf ']'
}

snapshot_workflow_json() {
	local workflow="$ROOT/.github/workflows/palari.yml"
	local ruleset="$ROOT/.github/palari-required-checks.ruleset.json"
	local workflow_text="" workflow_exists="" ruleset_exists=""
	[[ -f "$workflow" ]] && workflow_text="$(cat "$workflow")"
	[[ -f "$workflow" ]] && workflow_exists="true"
	[[ -f "$ruleset" ]] && ruleset_exists="true"
	printf '{"workflow_installed":%s,"ruleset_template":%s,"merge_group":%s,"attestation":%s,"sarif":%s,"workflow_path":".github/workflows/palari.yml","ruleset_path":".github/palari-required-checks.ruleset.json"}' \
		"$(json_nonempty_bool "$workflow_exists")" \
		"$(json_nonempty_bool "$ruleset_exists")" \
		"$(json_bool "$([[ "$workflow_text" == *merge_group* ]] && printf true || printf false)")" \
		"$(json_bool "$([[ "$workflow_text" == *actions/attest* ]] && printf true || printf false)")" \
		"$(json_bool "$([[ "$workflow_text" == *upload-sarif* ]] && printf true || printf false)")"
}

snapshot_memory_json() {
	if command -v python3 >/dev/null 2>&1 && [[ -f "$ROOT/adapters/memory/memory.py" ]]; then
		python3 -B "$ROOT/adapters/memory/memory.py" --root "$ROOT" summary --json 2>/dev/null && return 0
	fi
	printf '{"enabled":'
	json_bool "$([[ -d "$ROOT/$MEMORY_DIR" ]] && printf true || printf false)"
	printf ',"dir":'
	json_string "$MEMORY_DIR"
	printf ',"backend":'
	json_string "$MEMORY_INDEX_BACKEND"
	printf ',"total":0,"active":0,"proposed":0,"stale_review":0,"lint_ok":true,"index_exists":false}'
}

cmd_snapshot() {
	require_base_folders
	local format="" mode="fast" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--json)
			format="json"
			shift
			;;
		--full)
			mode="full"
			shift
			;;
		"")
			shift
			;;
		*) die "snapshot supports only --json [--full]" ;;
		esac
	done
	[[ -n "$format" ]] || format="json"
	local proposals active accepted reports human evidence git_branch palari_status dirty generated_dirty source_dirty stale overlaps_json overlap_count missing_evidence=0 file status lease id
	proposals="$(proposal_files | wc -l | tr -d ' ')"
	active="$(ticket_files | wc -l | tr -d ' ')"
	accepted="$(closed_ticket_files | wc -l | tr -d ' ')"
	reports="$(find "$ROOT/$REPORTS_DIR" -maxdepth 1 -type f \( -name '*.md' -o -name '*.markdown' \) ! -name 'README.md' | wc -l | tr -d ' ')"
	human="$(find "$ROOT/$HUMAN_REPORTS_DIR" -maxdepth 1 -type f \( -name '*.md' -o -name '*.markdown' \) ! -name 'README.md' | wc -l | tr -d ' ')"
	evidence="$(find "$ROOT/$EVIDENCE_DIR" -type f ! -name '.gitkeep' 2>/dev/null | wc -l | tr -d ' ')"
	git_branch="$(git -C "$ROOT" branch --show-current 2>/dev/null || printf 'detached')"
	palari_status="$(capture_command_json cmd_status)"
	if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 && declare -F hygiene_dirty_counts >/dev/null; then
		hygiene_dirty_counts dirty generated_dirty source_dirty
	else
		dirty="$({ git -C "$ROOT" status --short -- . 2>/dev/null || true; } | awk 'END { print NR }')"
		generated_dirty=0
		source_dirty="$dirty"
	fi
	stale=0
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		lease="$(ticket_lease_status "$file")"
		[[ "$lease" == "expired" ]] && stale=$((stale + 1))
	done < <(ticket_files)
	if [[ "$mode" == "full" ]]; then
		while IFS= read -r file; do
			[[ -n "$file" ]] || continue
			status="$(frontmatter_value "$file" status)"
			if [[ "$status" == "in-review" || "$status" == "accepted" ]]; then
				id="$(frontmatter_value "$file" id)"
				if [[ ! -s "$ROOT/$EVIDENCE_DIR/$id/verification.log" ||
					! -s "$ROOT/$EVIDENCE_DIR/$id/junit.xml" ||
					! -s "$ROOT/$EVIDENCE_DIR/$id/palari.sarif" ||
					! -s "$ROOT/$EVIDENCE_DIR/$id/manifest.json" ]]; then
					missing_evidence=$((missing_evidence + 1))
				fi
			fi
		done < <(all_ticket_files)
	else
		while IFS= read -r file; do
			[[ -n "$file" ]] || continue
			status="$(frontmatter_value "$file" status)"
			if [[ "$status" == "in-review" ]]; then
				id="$(frontmatter_value "$file" id)"
				if [[ ! -s "$ROOT/$EVIDENCE_DIR/$id/verification.log" ||
					! -s "$ROOT/$EVIDENCE_DIR/$id/junit.xml" ||
					! -s "$ROOT/$EVIDENCE_DIR/$id/palari.sarif" ||
					! -s "$ROOT/$EVIDENCE_DIR/$id/manifest.json" ]]; then
					missing_evidence=$((missing_evidence + 1))
				fi
			fi
		done < <(ticket_files)
	fi
	overlaps_json="$(snapshot_overlaps_json)"
	overlap_count="$(awk -v text="$overlaps_json" 'BEGIN { print gsub(/"left"/, "", text) }')"

	printf '{\n'
	printf '  "project": '
	json_string "$PROJECT_NAME"
	printf ',\n  "snapshot_mode": '
	json_string "$mode"
	printf ',\n  "root": '
	json_string "$ROOT"
	printf ',\n  "generated_at": '
	json_string "$(now_utc)"
	printf ',\n  "config": {"default_branch":'
	json_string "$DEFAULT_BRANCH"
	printf ',"scope_overlap_policy":'
	json_string "$SCOPE_OVERLAP_POLICY"
	printf ',"claim_lease_seconds":'
	json_string "$CLAIM_LEASE_SECONDS"
	printf ',"authority_profile":'
	json_string "$AUTHORITY_PROFILE"
	printf ',"evidence_dir":'
	json_string "$EVIDENCE_DIR"
	printf '},\n'
	printf '  "counts": {"proposals":%s,"open":%s,"claimed":%s,"blocked":%s,"needs-human":%s,"in-review":%s,"reopened":%s,"accepted":%s},\n' \
		"$proposals" \
		"$(count_status open)" "$(count_status claimed)" "$(count_status blocked)" \
		"$(count_status needs-human)" "$(count_status in-review)" "$(count_status reopened)" "$accepted"
	printf '  "proposals": '
	snapshot_proposals_json
	printf ',\n'
	printf '  "tickets": '
	snapshot_tickets_json "$mode"
	printf ',\n  "operator": '
	snapshot_operator_json "$mode"
	printf ',\n  "roles": '
	snapshot_roles_json "$mode"
	printf ',\n  "overlaps": %s,\n' "$overlaps_json"
	printf '  "workflow": '
	snapshot_workflow_json
	printf ',\n  "memory": '
	snapshot_memory_json
	printf ',\n  "gate": '
	snapshot_gate_json
	printf ',\n  "health": {"status_ok":true,"dirty_paths":%s,"generated_dirty_paths":%s,"source_dirty_paths":%s,"stale_claims":%s,"missing_evidence":%s,"overlaps":%s},\n' \
		"$dirty" "$generated_dirty" "$source_dirty" "$stale" "$missing_evidence" "$overlap_count"
	printf '  "git": {"branch":'
	json_string "$git_branch"
	printf ',"status":'
	json_string "$(git -C "$ROOT" status --short --branch 2>/dev/null || true)"
	printf '},\n'
	printf '  "palari_status": %s,\n' "$palari_status"
	printf '  "authority": {"profile":'
	json_string "$AUTHORITY_PROFILE"
	printf ',"agent_can_commit":'
	json_string "$(authority_value agent_can_commit)"
	printf ',"agent_can_push_branch":'
	json_string "$(authority_value agent_can_push_branch)"
	printf ',"agent_can_open_pr":'
	json_string "$(authority_value agent_can_open_pr)"
	printf ',"agent_can_merge_main":'
	json_string "$(authority_value agent_can_merge_main)"
	printf ',"agent_can_accept":'
	json_string "$(authority_value agent_can_accept)"
	printf '},\n'
	printf '  "commands": {"status":"./bin/palari status","status_next":"./bin/palari status --next","hygiene":"./bin/palari hygiene","authority":"./bin/palari authority","ticket_audit":"./bin/palari ticket audit","lint":"./bin/palari lint","scope_overlaps":"./bin/palari scope-overlaps","ruleset":"./bin/palari github ruleset-command --repo OWNER/REPO"}\n'
	printf '}\n'
	: "$active" "$reports" "$human" "$evidence"
}

cmd_web() {
	local host="127.0.0.1" port="8765" check="false" full="false" unsafe_bind="false" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--host)
			host="$2"
			shift 2
			;;
		--port)
			port="$2"
			shift 2
			;;
		--check)
			check="true"
			shift
			;;
		--full)
			full="true"
			shift
			;;
		--unsafe-bind)
			unsafe_bind="true"
			shift
			;;
		-h | --help)
			cat <<'WEBUSAGE'
usage: palari web [--host HOST] [--port PORT] [--check] [--full] [--unsafe-bind]

Run the optional local Palari Console web dashboard.

options:
  --host HOST   Bind host. Default: 127.0.0.1
  --port PORT   Bind port. Default: 8765
  --check       Print the dashboard JSON snapshot and exit.
  --full        With --check, include expensive closed-ticket and role diagnostics.
  --unsafe-bind Allow binding outside loopback. Intended only for trusted networks.
WEBUSAGE
			return 0
			;;
		*) die "unknown web option: $arg" ;;
		esac
	done
	[[ "$port" =~ ^[0-9]+$ ]] || die "web port must be numeric"
	command -v python3 >/dev/null 2>&1 || die "palari web requires python3"
	if [[ "$check" == "true" ]]; then
		if [[ "$full" == "true" ]]; then
			cmd_snapshot --json --full
		else
			exec python3 -B -S "$ROOT/adapters/web/server.py" --root "$ROOT" --check
		fi
	elif [[ "$unsafe_bind" == "true" ]]; then
		python3 -B "$ROOT/adapters/web/server.py" --root "$ROOT" --host "$host" --port "$port" --unsafe-bind
	else
		python3 -B "$ROOT/adapters/web/server.py" --root "$ROOT" --host "$host" --port "$port"
	fi
}

cmd_memory() {
	command -v python3 >/dev/null 2>&1 || die "palari memory requires python3"
	[[ -f "$ROOT/adapters/memory/memory.py" ]] || die "missing memory adapter: adapters/memory/memory.py"
	python3 -B "$ROOT/adapters/memory/memory.py" --root "$ROOT" "$@"
}
