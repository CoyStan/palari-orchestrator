# shellcheck shell=bash
# shellcheck disable=SC2153 # This module is sourced after core and lifecycle helpers.

prompt_usage() {
	cat <<'USAGE'
usage: palari prompt COMMAND [ARGS]
commands:
  prompt next                         Print a prompt for the next active ticket.
  prompt ticket ID                    Print a prompt for a specific ticket.
  prompt long-run --goal TEXT         Print a long-running agent prompt.

options:
  --goal TEXT                         Founder/operator goal for long-run mode.
  --ticket ID                         Optional starting ticket for long-run mode.
USAGE
}

prompt_print_list() {
	local file="$1"
	local key="$2"
	local item count=0
	while IFS= read -r item; do
		[[ -n "$item" ]] || continue
		printf -- '- %s\n' "$item"
		count=$((count + 1))
	done < <(frontmatter_list_items "$file" "$key")
	((count > 0)) || printf -- '- none recorded\n'
}

prompt_first_active_ticket() {
	local file
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		printf '%s\n' "$file"
		return 0
	done < <(ticket_files)
	return 1
}

prompt_ticket_header() {
	local file="$1"
	local id title status risk priority stream target branch worktree rel next
	id="$(frontmatter_value "$file" id)"
	title="$(frontmatter_value "$file" title)"
	status="$(frontmatter_value "$file" status)"
	risk="$(frontmatter_value "$file" risk)"
	priority="$(frontmatter_value "$file" priority)"
	stream="$(frontmatter_value "$file" stream)"
	target="$(frontmatter_value "$file" target_branch)"
	branch="$(frontmatter_value "$file" branch)"
	worktree="$(ticket_declared_worktree "$file" "${id:-ticket}")"
	rel="${file#"$ROOT"/}"
	next="$(ticket_next_action "$file")"

	cat <<EOF
Ticket context:
- Ticket: ${id:-unknown} - ${title:-untitled}
- Status: ${status:-missing}
- Risk: ${risk:-missing}
- Priority: ${priority:-missing}
- Stream: ${stream:-missing}
- Ticket file: $rel
- Target branch: ${target:-$DEFAULT_BRANCH}
- Ticket branch: ${branch:-ticket/${id:-unknown}}
- Ticket worktree: $worktree
- Current next action: $next

Allowed paths:
EOF
	prompt_print_list "$file" allowed_paths
	printf '\nForbidden paths:\n'
	prompt_print_list "$file" forbidden_paths
	printf '\nVerification commands:\n'
	prompt_print_list "$file" verification
}

prompt_common_rules() {
	cat <<'EOF'
Operating rules:
- Preserve unrelated dirty files and user work.
- Stay inside the ticket allowed paths and respect forbidden paths.
- Do not touch secrets, production, deploys, databases, or destructive git commands.
- Do not commit, push, merge, deploy, or accept unless the human explicitly asks.
- Do not self-accept. Human acceptance remains the final authority.
- Keep claims factual: separate what changed, what passed, limitations, and next gates.
- Prefer repo-native Bash, Markdown, git, and stdlib patterns already present.

Evidence expectations:
- Create or update the ticket technical report when implementation work happens.
- Run ticket verification commands plus relevant local checks.
- Run `./bin/palari scope-check TICKET-ID` and `./bin/palari lint TICKET-ID`.
- Run `./bin/palari ci TICKET-ID` when the ticket is ready for evidence.
- Move implementation tickets to review with `./bin/palari ticket ready TICKET-ID` only after evidence passes.
EOF
}

prompt_roles_block() {
	cat <<'EOF'
Roles to simulate and document when relevant:
- Product Manager: chooses the next highest-value scoped slice and records tradeoffs.
- UX/UI Lead: checks clarity, hierarchy, copy, accessibility, and professional polish.
- QA Lead: covers regressions, edge cases, empty/loading/error states, and screenshots when UI changes.
- Release Lead: checks packaging, config, CI, permissions, and external-account blockers.
- Backend/Platform Architect: separates local/demo work from storage, auth, sync, and production claims.
- Security/Governance Reviewer: checks scope, evidence, authority, and human gates.
- Integrator: prepares the work for review without bypassing acceptance or merge authority.
EOF
}

cmd_prompt_ticket() {
	require_base_folders
	local ticket="${1:-}"
	[[ -n "$ticket" ]] || die "prompt ticket requires ticket ID"
	local file id title
	file="$(find_ticket_file "$ticket")" || die "ticket not found: $ticket"
	id="$(frontmatter_value "$file" id)"
	title="$(frontmatter_value "$file" title)"

	cat <<EOF
You are working in $ROOT.

Goal:
Work on ${id:-$ticket} only: ${title:-the scoped Palari ticket}.

Before editing:
1. Inspect git status.
2. Inspect Palari status with \`./bin/palari status --next\`.
3. Inspect the ticket and any reports/evidence it names.
4. Briefly summarize the focused plan before changing files.

EOF
	prompt_ticket_header "$file"
	printf '\n'
	prompt_common_rules
	cat <<EOF

Execution loop:
1. Claim and isolate the ticket if it is open or reopened.
2. Implement only the scoped change.
3. Add or update tests only where useful for the changed behavior.
4. Run the verification commands listed above.
5. Capture evidence and a concise technical report.
6. Move the ticket to review if all checks pass.
7. Stop for human/reviewer gate. Do not accept, commit, push, or merge.

Deliverable:
Summarize what changed, checks passed/failed, evidence captured, limitations, and the exact next Palari action.
EOF
}

cmd_prompt_next() {
	require_base_folders
	local file
	if ! file="$(prompt_first_active_ticket)"; then
		cat <<EOF
You are working in $ROOT.

There are no active Palari tickets. Inspect the repo, summarize the current product/research state, and propose the next small scoped ticket before editing.

Constraints:
- Do not commit, push, merge, deploy, or accept unless the human explicitly asks.
- Preserve unrelated dirty files.
- Prefer \`./bin/palari ticket create\` or \`./bin/palari propose create\` for new work.
EOF
		return 0
	fi
	cmd_prompt_ticket "$(frontmatter_value "$file" id)"
}

cmd_prompt_long_run() {
	require_base_folders
	local goal="" start_ticket="" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--goal)
			goal="$2"
			shift 2
			;;
		--ticket)
			start_ticket="$2"
			shift 2
			;;
		*) die "unknown prompt long-run option: $arg" ;;
		esac
	done
	[[ -n "$goal" ]] || die "prompt long-run requires --goal TEXT"

	cat <<EOF
You are working in $ROOT.

Long-running goal:
$goal

Mission:
Work for as long as there is meaningful unblocked Palari-governed work that advances the goal. Do not stop after one small ticket unless a true human gate blocks safe progress.

Current orientation:
- Start by running \`git status --short --branch\`.
- Then run \`./bin/palari status --next\` and \`./bin/palari ticket audit\`.
- Run \`./bin/palari state\` to see landed capabilities and current repo notes.
- Run \`./bin/palari run --dry-run --until blocked\` before choosing follow-on work.
- After context compaction, verify the current branch and ticket \`target_branch\`; do not assume an old stacked branch or deleted worktree is still the right base.
EOF
	if [[ -n "$start_ticket" ]]; then
		printf -- '- Start with ticket: %s\n' "$start_ticket"
	else
		local file id next
		if file="$(prompt_first_active_ticket)"; then
			id="$(frontmatter_value "$file" id)"
			next="$(ticket_next_action "$file")"
			printf -- '- Suggested first ticket: %s\n' "${id:-unknown}"
			printf -- '- Suggested first action: %s\n' "$next"
		else
			printf -- '- No active ticket exists yet; create a small scoped planning or implementation ticket before editing.\n'
		fi
	fi
	printf '\n'
	prompt_common_rules
	printf '\n'
	prompt_roles_block
	cat <<'EOF'

Autonomous execution loop:
1. Inspect the next safe ticket and its allowed/forbidden paths.
2. Claim and isolate only one implementation ticket at a time.
3. Implement the smallest useful slice that satisfies the ticket.
4. Run focused tests plus the ticket verification commands.
5. Capture the technical report, screenshots or logs when useful, and Palari CI evidence.
6. Move the ticket to review when ready.
7. If another unblocked ticket is available and does not require human acceptance first, continue to it.
8. If the goal needs more work, create scoped follow-on tickets with clear verification and continue only when safe.

Stopping rules:
Stop and report when any of these is true:
- Human acceptance, product decision, credentials, external account access, or production authority is required.
- The next safe action is commit, push, merge, deploy, or accept and the human has not explicitly requested it.
- Scope, risk, allowed paths, or authority are unclear.
- Checks fail and fixing them would exceed the current ticket.
- There is no meaningful unblocked work left under the goal.

Deliverable at each stop:
Summarize tickets worked, features or artifacts changed, checks passed/failed, evidence captured, blockers/confounders, and the exact next Palari action.
EOF
}

cmd_prompt() {
	local sub="${1:-}"
	shift || true
	case "$sub" in
	next) cmd_prompt_next "$@" ;;
	ticket) cmd_prompt_ticket "$@" ;;
	long-run) cmd_prompt_long_run "$@" ;;
	-h | --help | help | "") prompt_usage ;;
	*) die "unknown prompt command: ${sub:-}; try \`palari prompt help\`" ;;
	esac
}
