render_proposal_packet() {
	local file="$1"
	local proposal_id title planner model rel
	proposal_id="$(frontmatter_value "$file" id)"
	title="$(frontmatter_value "$file" title)"
	planner="$(frontmatter_value "$file" planner)"
	model="$(frontmatter_value "$file" model)"
	rel="${file#"$ROOT"/}"
	printf 'Palari Lead planning packet\n'
	printf 'Role: lead\n'
	printf 'Proposal: %s - %s\n' "$proposal_id" "${title:-}"
	printf 'Proposal path: %s\n' "$rel"
	printf 'Planner: %s\n' "${planner:-unspecified}"
	printf 'Model: %s\n\n' "${model:-unspecified}"
	printf 'Authority:\n'
	printf '  Lead/planner mode. Read repository context, selected memory, skills, and contracts.\n'
	printf '  Write only proposal files under %s and planning notes under %s.\n' "$PROPOSED_DIR" "$PLANNING_REPORTS_DIR"
	printf '  Do not edit source files, run executor work, accept tickets, push, commit, or broaden governance.\n'
	printf '  Produce small, adoptable tickets with explicit allowed paths, forbidden paths, verification, review gates, and human gates.\n\n'
	printf 'Context sources:\n'
	printf '  - AGENTS.md\n'
	printf '  - contracts/lead.md\n'
	printf '  - skills/planner/SKILL.md\n'
	printf '  - memory/**/*.md only when relevant or selected by the orchestrator\n'
	printf '  - the proposal file named above\n\n'
	printf 'Memory and skills rule:\n'
	printf '  Use active repo memory and planner skills as guidance, not authority.\n'
	printf '  If memory is missing, stale, contradictory, or too broad, record a question instead of guessing.\n'
	printf '  The executor will receive its own selected memory in the eventual ticket packet.\n\n'
	printf 'Stop conditions:\n'
	printf '  - the request needs implementation rather than planning\n'
	printf '  - proposed scope would touch secrets, production, deploys, live external writes, or destructive commands\n'
	printf '  - acceptance criteria or product direction are unclear enough to risk waste\n'
	printf '  - one proposed ticket becomes too broad to verify in one review pass\n\n'
	printf 'Closeout:\n'
	printf '  - recommended ticket split\n'
	printf '  - allowed and forbidden paths for each proposed ticket\n'
	printf '  - verification commands or manual checks\n'
	printf '  - open questions for the human/founder\n'
	printf '  - memory updates worth proposing\n'
}

write_proposal_packet() {
	local file="$1"
	local proposal_id packet
	proposal_id="$(frontmatter_value "$file" id)"
	mkdir -p "$ROOT/$PLANNING_REPORTS_DIR"
	packet="$ROOT/$PLANNING_REPORTS_DIR/$proposal_id-lead-packet.md"
	render_proposal_packet "$file" >"$packet"
	printf '%s\n' "$packet"
}

cmd_propose_create() {
	require_base_folders
	local id="${1:-}"
	local title="${2:-}"
	shift 2 || true
	[[ -n "$id" && -n "$title" ]] || die "propose create requires PROPOSAL-ID and title"
	valid_proposal_id "$id" || die "invalid proposal id: $id; use POS-PROP-0001 or PROP-0001"

	local planner="human" model="" intent="" source="" arg
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--planner)
			planner="$2"
			shift 2
			;;
		--model)
			model="$2"
			shift 2
			;;
		--intent)
			intent="$2"
			shift 2
			;;
		--source)
			source="$2"
			shift 2
			;;
		*) die "unknown propose create option: $arg" ;;
		esac
	done

	local slug file created packet
	slug="$(slugify "$title")"
	file="$ROOT/$PROPOSED_DIR/$id-$slug.md"
	[[ ! -e "$file" ]] || die "proposal already exists: ${file#"$ROOT"/}"
	created="$(today_utc)"
	{
		printf -- '---\n'
		printf 'id: %s\n' "$id"
		printf 'title: %s\n' "$title"
		printf 'status: proposed\n'
		printf 'planner: %s\n' "$planner"
		printf 'model: %s\n' "$model"
		printf 'source: %s\n' "$source"
		printf 'adopted_ticket:\n'
		printf 'adopted_at:\n'
		printf 'created: %s\n' "$created"
		printf 'updated: %s\n' "$created"
		printf -- '---\n\n'
		printf '# %s %s\n\n' "$id" "$title"
		printf '## Founder Intent\n\n'
		printf '%s\n\n' "${intent:-TODO: State the human/founder intent that should become scoped tickets.}"
		printf '## Planner Read\n\n'
		printf 'TODO: Summarize repository facts, relevant memory, and product or engineering constraints.\n\n'
		printf '## Proposed Tickets\n\n'
		printf '### TICKET-ID Ticket title\n\n'
		printf 'Goal:\n\n'
		printf 'Allowed paths:\n\n'
		printf -- '- TODO\n\n'
		printf 'Forbidden paths:\n\n'
		printf -- '- TODO\n\n'
		printf 'Verification:\n\n'
		printf -- '- TODO\n\n'
		printf 'Review gates:\n\n'
		printf -- '- TODO\n\n'
		printf '## Questions\n\n'
		# shellcheck disable=SC2016 # Backticks are literal Markdown in generated proposal text.
		printf -- '- TODO: Question for the human/founder, or `none`.\n\n'
		printf '## Authority Boundary\n\n'
		printf -- '- The lead may propose tickets and memory updates.\n'
		printf -- '- The lead may not implement code, accept work, push, commit, or broaden scope.\n'
		printf -- '- A human must adopt this proposal before executor work begins.\n'
	} >"$file"
	packet="$(write_proposal_packet "$file")"
	printf 'propose create: %s\n' "${file#"$ROOT"/}"
	printf 'lead packet: %s\n' "${packet#"$ROOT"/}"
}

cmd_propose_list() {
	require_base_folders
	local file count=0 id status title planner adopted
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		id="$(frontmatter_value "$file" id)"
		status="$(frontmatter_value "$file" status)"
		title="$(frontmatter_value "$file" title)"
		planner="$(frontmatter_value "$file" planner)"
		adopted="$(frontmatter_value "$file" adopted_ticket)"
		printf '%s\t%s\t%s\t%s\t%s\n' "$id" "${status:-missing}" "${planner:-unknown}" "${adopted:-"-"}" "$title"
		count=$((count + 1))
	done < <(proposal_files)
	((count > 0)) || printf 'propose list: none\n'
}

cmd_propose_show() {
	require_base_folders
	local proposal="${1:-}"
	[[ -n "$proposal" ]] || die "propose show requires PROPOSAL-ID"
	local file
	file="$(find_proposal_file "$proposal")" || die "proposal not found: $proposal"
	cat "$file"
}

cmd_propose_packet() {
	require_base_folders
	local proposal="${1:-}"
	[[ -n "$proposal" ]] || die "propose packet requires PROPOSAL-ID"
	local file
	file="$(find_proposal_file "$proposal")" || die "proposal not found: $proposal"
	render_proposal_packet "$file"
}

lint_one_proposal() {
	local file="$1"
	local errors=0 field value heading
	if ! has_frontmatter "$file"; then
		printf 'propose lint: %s: missing YAML frontmatter\n' "${file#"$ROOT"/}" >&2
		return 1
	fi
	for field in id title status planner adopted_ticket adopted_at created updated; do
		if ! frontmatter_has_key "$file" "$field"; then
			printf 'propose lint: %s: missing required field: %s\n' "${file#"$ROOT"/}" "$field" >&2
			errors=$((errors + 1))
		fi
	done
	value="$(frontmatter_value "$file" id)"
	if [[ -n "$value" ]] && ! valid_proposal_id "$value"; then
		printf 'propose lint: %s: invalid id: %s\n' "${file#"$ROOT"/}" "$value" >&2
		errors=$((errors + 1))
	fi
	value="$(frontmatter_value "$file" status)"
	case "$value" in
	proposed | adopted | rejected) ;;
	*)
		printf 'propose lint: %s: invalid status: %s\n' "${file#"$ROOT"/}" "${value:-missing}" >&2
		errors=$((errors + 1))
		;;
	esac
	for heading in "Founder Intent" "Planner Read" "Proposed Tickets" "Questions" "Authority Boundary"; do
		if ! grep -Eq "^##[[:space:]]+${heading}[[:space:]]*$" "$file"; then
			printf 'propose lint: %s: missing heading: ## %s\n' "${file#"$ROOT"/}" "$heading" >&2
			errors=$((errors + 1))
		fi
	done
	return "$errors"
}

cmd_propose_lint() {
	require_base_folders
	local proposal="${1:-}"
	local errors=0 file count=0
	if [[ -n "$proposal" ]]; then
		file="$(find_proposal_file "$proposal")" || die "proposal not found: $proposal"
		lint_one_proposal "$file" || errors=$((errors + 1))
		count=1
	else
		while IFS= read -r file; do
			[[ -n "$file" ]] || continue
			lint_one_proposal "$file" || errors=$((errors + 1))
			count=$((count + 1))
		done < <(proposal_files)
	fi
	((errors == 0)) || {
		printf 'propose lint: failed with %s issue(s)\n' "$errors" >&2
		exit 1
	}
	if [[ -n "$proposal" ]]; then
		printf 'propose lint: ok for %s\n' "$proposal"
	elif ((count == 0)); then
		printf 'propose lint: ok (no proposals)\n'
	else
		printf 'propose lint: ok\n'
	fi
}

cmd_propose_adopt() {
	require_base_folders
	local proposal="${1:-}"
	shift || true
	[[ -n "$proposal" ]] || die "propose adopt requires PROPOSAL-ID"
	local file status proposal_id ticket="" title="" arg adopted_at
	local -a ticket_args=()
	file="$(find_proposal_file "$proposal")" || die "proposal not found: $proposal"
	status="$(frontmatter_value "$file" status)"
	[[ "$status" == "proposed" ]] || die "proposal $proposal is not proposed; current status: ${status:-missing}"
	proposal_id="$(frontmatter_value "$file" id)"
	title="$(frontmatter_value "$file" title)"
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--ticket)
			ticket="$2"
			shift 2
			;;
		--title)
			title="$2"
			shift 2
			;;
		--review | --human | --contract)
			ticket_args+=("$arg")
			shift
			;;
		--stream | --risk | --priority | --allowed | --forbidden | --verify | --required-report | --target-branch)
			ticket_args+=("$arg" "$2")
			shift 2
			;;
		*) die "unknown propose adopt option: $arg" ;;
		esac
	done
	[[ -n "$ticket" ]] || die "propose adopt requires --ticket TICKET-ID"
	[[ -n "$title" ]] || die "proposal $proposal_id has no title; pass --title"
	cmd_ticket_create "$ticket" "$title" "${ticket_args[@]}"
	adopted_at="$(now_utc)"
	update_frontmatter_scalars "$file" \
		"status"$'\035'"adopted"$'\034' \
		"adopted_ticket"$'\035'"$ticket"$'\034' \
		"adopted_at"$'\035'"$adopted_at"$'\034' \
		"updated"$'\035'"$(today_utc)"$'\034'
	{
		printf '\n## Adoption\n\n'
		printf -- '- Adopted ticket: %s\n' "$ticket"
		printf -- '- Adopted at: %s\n' "$adopted_at"
	} >>"$file"
	printf 'propose adopt: %s -> %s\n' "$proposal_id" "$ticket"
}

cmd_propose() {
	local sub="${1:-}"
	shift || true
	case "$sub" in
	create | new) cmd_propose_create "$@" ;;
	list | ls) cmd_propose_list "$@" ;;
	show | view) cmd_propose_show "$@" ;;
	packet) cmd_propose_packet "$@" ;;
	lint) cmd_propose_lint "$@" ;;
	adopt) cmd_propose_adopt "$@" ;;
	*) die "unknown propose command: ${sub:-}; try \`palari propose create POS-PROP-0001 TITLE\`" ;;
	esac
}
