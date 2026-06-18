# shellcheck shell=bash
# shellcheck disable=SC2153 # This module is sourced after core/init modules define shared globals.
#
# Autonomous-agent hygiene helpers. These do not mutate lifecycle state; they
# classify local repository drift so long-running agents can clean up before
# starting another ticket.

HYGIENE_DEFAULT_GENERATED_PATTERNS=(
	"__pycache__/**"
	"**/__pycache__/**"
	"*.pyc"
	"**/*.pyc"
	".DS_Store"
	".palari/**"
	".expo/**"
	".metro/**"
	"node_modules/**"
	"coverage/**"
	".turbo/**"
	".next/**"
	"dist/**"
	"build/**"
	"android/.gradle/**"
	"android/app/build/**"
	"ios/Pods/**"
)

HYGIENE_GITIGNORE_ENTRIES=(
	".palari/"
	"__pycache__/"
	"*.pyc"
	".DS_Store"
	".expo/"
	".metro/"
	"node_modules/"
	"coverage/"
	".turbo/"
	".next/"
	"dist/"
	"build/"
	"android/.gradle/"
	"android/app/build/"
	"ios/Pods/"
)

hygiene_ensure_gitignore() {
	local ignore="$ROOT/.gitignore" entry added=0
	[[ -e "$ignore" ]] || : >"$ignore"
	for entry in "${HYGIENE_GITIGNORE_ENTRIES[@]}"; do
		if ! grep -Fxq "$entry" "$ignore"; then
			printf '%s\n' "$entry" >>"$ignore"
			added=$((added + 1))
		fi
	done
	if ((added > 0)); then
		printf 'init: updated .gitignore hygiene entries (%s)\n' "$added"
	fi
}

hygiene_generated_patterns() {
	local item count=0
	while IFS= read -r item; do
		[[ -n "$item" ]] || continue
		printf '%s\n' "$item"
		count=$((count + 1))
	done < <(config_list hygiene_generated_paths || true)
	if ((count == 0)); then
		for item in "${HYGIENE_DEFAULT_GENERATED_PATTERNS[@]}"; do
			printf '%s\n' "$item"
		done
	fi
}

hygiene_status_path() {
	local line="$1"
	line="${line#???}"
	case "$line" in
	*" -> "*) line="${line##* -> }" ;;
	esac
	printf '%s\n' "$line"
}

hygiene_status_tracked() {
	local line="$1"
	[[ "${line:0:2}" != "??" ]]
}

hygiene_dirty_lines() {
	git -C "$ROOT" status --short -- . 2>/dev/null || true
}

hygiene_path_generated_with_patterns() {
	local path="${1#./}"
	shift
	local pattern
	for pattern in "$@"; do
		[[ -n "$pattern" ]] || continue
		if path_matches_pattern "$path" "$pattern"; then
			return 0
		fi
	done
	return 1
}

hygiene_path_generated() {
	local -a patterns=()
	mapfile -t patterns < <(hygiene_generated_patterns)
	hygiene_path_generated_with_patterns "$1" "${patterns[@]}"
}

hygiene_scope_pattern_generated() {
	local pattern="${1#./}" generated pattern_root generated_root
	local -a generated_patterns=()
	mapfile -t generated_patterns < <(hygiene_generated_patterns)
	for generated in "${generated_patterns[@]}"; do
		[[ -n "$generated" ]] || continue
		if [[ "$pattern" == "$generated" ]]; then
			return 0
		fi
		pattern_root="${pattern%/**}"
		generated_root="${generated%/**}"
		if [[ -n "$pattern_root" && -n "$generated_root" ]] &&
			[[ "$pattern_root" == "$generated_root" || "$pattern_root" == "$generated_root/"* ]]; then
			return 0
		fi
	done
	return 1
}

hygiene_dirty_counts() {
	local total_ref="$1"
	local generated_ref="$2"
	local source_ref="$3"
	local tracked_generated_ref="${4:-}"
	local line path dirty_total=0 dirty_generated=0 dirty_source=0 dirty_tracked_generated=0
	local -a generated_patterns=()
	mapfile -t generated_patterns < <(hygiene_generated_patterns)
	while IFS= read -r line; do
		[[ -n "$line" ]] || continue
		path="$(hygiene_status_path "$line")"
		dirty_total=$((dirty_total + 1))
		if hygiene_path_generated_with_patterns "$path" "${generated_patterns[@]}"; then
			dirty_generated=$((dirty_generated + 1))
			if hygiene_status_tracked "$line"; then
				dirty_tracked_generated=$((dirty_tracked_generated + 1))
			fi
		else
			dirty_source=$((dirty_source + 1))
		fi
	done < <(hygiene_dirty_lines)
	printf -v "$total_ref" '%s' "$dirty_total"
	printf -v "$generated_ref" '%s' "$dirty_generated"
	printf -v "$source_ref" '%s' "$dirty_source"
	[[ -z "$tracked_generated_ref" ]] || printf -v "$tracked_generated_ref" '%s' "$dirty_tracked_generated"
}

hygiene_print_dirty() {
	local wanted="$1"
	local line path printed=0
	while IFS= read -r line; do
		[[ -n "$line" ]] || continue
		path="$(hygiene_status_path "$line")"
		if [[ "$wanted" == "generated" ]]; then
			hygiene_path_generated "$path" || continue
		elif [[ "$wanted" == "tracked-generated" ]]; then
			hygiene_path_generated "$path" || continue
			hygiene_status_tracked "$line" || continue
		else
			! hygiene_path_generated "$path" || continue
		fi
		printf '  %s\n' "$line"
		printed=$((printed + 1))
	done < <(hygiene_dirty_lines)
	return "$printed"
}

hygiene_claimed_tickets() {
	local file id by expires lease
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		[[ "$(frontmatter_value "$file" status)" == "claimed" ]] || continue
		id="$(frontmatter_value "$file" id)"
		by="$(frontmatter_value "$file" claimed_by)"
		expires="$(frontmatter_value "$file" claim_expires_at)"
		lease="$(ticket_lease_status "$file")"
		printf '%s\t%s\t%s\t%s\n' "${id:-$(ticket_title_from_file "$file")}" "${by:-unknown}" "$lease" "$expires"
	done < <(ticket_files)
}

hygiene_resolve_target_ref() {
	local target="$1"
	if [[ -n "$target" ]] && git -C "$ROOT" rev-parse --verify "origin/$target" >/dev/null 2>&1; then
		printf 'origin/%s\n' "$target"
	elif [[ -n "$target" ]] && git -C "$ROOT" rev-parse --verify "$target" >/dev/null 2>&1; then
		printf '%s\n' "$target"
	else
		printf '%s\n' "$target"
	fi
}

hygiene_branch_ahead_count() {
	local branch="$1"
	local target="$2"
	local target_ref
	target_ref="$(hygiene_resolve_target_ref "$target")"
	[[ -n "$branch" && -n "$target_ref" && "$branch" != "$target_ref" ]] || {
		printf '0\n'
		return 0
	}
	git -C "$ROOT" show-ref --verify --quiet "refs/heads/$branch" || {
		printf '0\n'
		return 0
	}
	git -C "$ROOT" rev-parse --verify "$target_ref" >/dev/null 2>&1 || {
		printf '0\n'
		return 0
	}
	git -C "$ROOT" rev-list --count "$target_ref..$branch" 2>/dev/null || printf '0\n'
}

hygiene_branch_findings() {
	local file id status branch target target_ref ahead
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		id="$(frontmatter_value "$file" id)"
		[[ -n "$id" ]] || id="$(ticket_title_from_file "$file")"
		status="$(frontmatter_value "$file" status)"
		branch="$(ticket_declared_branch "$file" "$id")"
		target="$(frontmatter_value "$file" target_branch)"
		[[ -n "$target" ]] || target="$DEFAULT_BRANCH"
		target_ref="$(hygiene_resolve_target_ref "$target")"
		ahead="$(hygiene_branch_ahead_count "$branch" "$target")"
		[[ "$ahead" =~ ^[0-9]+$ ]] || ahead=0
		((ahead > 0)) || continue
		printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$status" "$branch" "$target_ref" "$ahead"
	done < <(ticket_files)
}

hygiene_review_findings() {
	local file id status missing=0
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		status="$(frontmatter_value "$file" status)"
		[[ "$status" == "in-review" ]] || continue
		id="$(frontmatter_value "$file" id)"
		[[ -n "$id" ]] || id="$(ticket_title_from_file "$file")"
		missing=0
		ticket_evidence_present_quiet "$id" || missing=1
		ticket_report_lint_quiet "$id" || missing=1
		((missing == 0)) || printf '%s\t%s\n' "$id" "$(ticket_next_action "$file")"
	done < <(ticket_files)
}

cmd_hygiene() {
	require_base_folders
	local strict="false" arg total generated source tracked_generated line id by lease expires status branch target ahead issue_count=0
	while (($# > 0)); do
		arg="$1"
		case "$arg" in
		--strict)
			strict="true"
			shift
			;;
		-h | --help)
			cat <<'HYGIENEUSAGE'
usage: palari hygiene [--strict]

Classify dirty files, stale claims, incomplete review gates, and ticket branches
with work not integrated into their target branch. Use --strict to exit nonzero
when action is needed.
HYGIENEUSAGE
			return 0
			;;
		*) die "unknown hygiene option: $arg" ;;
		esac
	done

	hygiene_dirty_counts total generated source tracked_generated
	printf 'Palari hygiene\n'
	printf 'root: %s\n' "$ROOT"
	printf 'git: %s dirty path(s) (%s generated, %s source, %s tracked generated)\n' "$total" "$generated" "$source" "$tracked_generated"
	if ((generated > 0)); then
		printf 'generated dirty paths:\n'
		hygiene_print_dirty generated || true
	fi
	if ((tracked_generated > 0)); then
		printf 'tracked generated paths:\n'
		hygiene_print_dirty tracked-generated || true
		issue_count=$((issue_count + tracked_generated))
	fi
	if ((source > 0)); then
		printf 'source dirty paths:\n'
		hygiene_print_dirty source || true
		issue_count=$((issue_count + source))
	fi

	printf 'claims:\n'
	local claim_count=0 stale_count=0
	while IFS=$'\t' read -r id by lease expires; do
		[[ -n "$id" ]] || continue
		printf '  %s claimed_by=%s lease=%s expires=%s\n' "$id" "$by" "$lease" "$expires"
		claim_count=$((claim_count + 1))
		if [[ "$lease" == "expired" ]]; then
			stale_count=$((stale_count + 1))
			issue_count=$((issue_count + 1))
		fi
	done < <(hygiene_claimed_tickets)
	((claim_count > 0)) || printf '  none\n'

	printf 'ticket branches:\n'
	local branch_count=0
	while IFS=$'\t' read -r id status branch target ahead; do
		[[ -n "$id" ]] || continue
		printf '  %s [%s] %s is %s commit(s) ahead of %s\n' "$id" "$status" "$branch" "$ahead" "$target"
		if [[ "$status" == "claimed" ]]; then
			printf '    next: finish evidence/report and run `./bin/palari ticket ready %s`, or explicitly defer before claiming more work.\n' "$id"
		fi
		branch_count=$((branch_count + 1))
		issue_count=$((issue_count + 1))
	done < <(hygiene_branch_findings)
	((branch_count > 0)) || printf '  none\n'

	printf 'review gates:\n'
	local review_count=0 next
	while IFS=$'\t' read -r id next; do
		[[ -n "$id" ]] || continue
		printf '  %s: %s\n' "$id" "$next"
		review_count=$((review_count + 1))
		issue_count=$((issue_count + 1))
	done < <(hygiene_review_findings)
	((review_count > 0)) || printf '  none\n'

	if ((issue_count == 0)); then
		printf 'summary: clean enough for the next autonomous ticket\n'
	else
		printf 'summary: action needed (%s issue(s), %s stale claim(s))\n' "$issue_count" "$stale_count"
	fi
	[[ "$strict" == "true" && "$issue_count" != "0" ]] && return 1
	return 0
}
