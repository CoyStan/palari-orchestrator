# shellcheck shell=bash
# shellcheck disable=SC2034 # Core globals are consumed by other sourced Palari modules.
VALID_STATUSES="open claimed blocked needs-human in-review reopened accepted"
VALID_RISKS="R0 R1 R2 R3 R4"
VALID_PRIORITIES="P0 P1 P2 P3"
REQUIRED_FIELDS=(
	id title status risk priority stream allowed_paths forbidden_paths
	verification requires_review requires_human_confirmation target_branch
	branch worktree claimed_by claimed_at claim_ref claim_heartbeat_at claim_expires_at
	accepted_by accepted_at created updated
)
# Precise, auditable secret-surface patterns. Substring globs such as
# "**/*secret*" or "**/*token*" are intentionally avoided: they block
# legitimate source files (for example gate/forgegate/token.py) while a
# renamed credentials file evades them. Pair these path rules with content
# scanning (for example gitleaks) in CI for real secret protection.
DEFAULT_FORBIDDEN_PATHS=(
	".env"
	".env.*"
	"**/.env"
	"**/.env.*"
	"**/secrets/**"
	"**/*.pem"
	"**/*.key"
	"**/*.keystore"
	"**/*.p12"
	"**/id_rsa*"
	"**/id_ed25519*"
	"**/credentials*"
	"**/.aws/**"
	"**/.ssh/**"
	"infra/prod/**"
	"prod/**"
)
ADOPTION_PATHS=(
	"bin"
	"lib"
	"scripts"
	"templates"
	"contracts"
	"skills"
	"schemas"
	"roles"
	"adapters"
	"gate"
	"layouts"
	"examples"
	"palari.config.yaml"
)

die() {
	printf 'error: %s\n' "$*" >&2
	exit 2
}

config_scalar() {
	local key="$1"
	[[ -f "$CONFIG" ]] || return 1
	awk -v key="$key" '
    $0 ~ "^[[:space:]]*" key ":" {
      sub("^[[:space:]]*" key ":[[:space:]]*", "", $0)
      sub(/[[:space:]]#.*$/, "", $0)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      gsub(/^["'\'']|["'\'']$/, "", $0)
      print
      exit
    }
  ' "$CONFIG"
}

config_nested_scalar() {
	local section="$1"
	local key="$2"
	[[ -f "$CONFIG" ]] || return 1
	awk -v section="$section" -v key="$key" '
    $0 ~ "^[[:space:]]*" section ":" {
      in_section = 1
      next
    }
    in_section && $0 ~ "^[^[:space:]][A-Za-z0-9_]+:" {
      exit
    }
    in_section && $0 ~ "^[[:space:]]+" key ":" {
      sub("^[[:space:]]*" key ":[[:space:]]*", "", $0)
      sub(/[[:space:]]#.*$/, "", $0)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      gsub(/^["'\'']|["'\'']$/, "", $0)
      print
      exit
    }
  ' "$CONFIG"
}

config_list() {
	local key="$1"
	[[ -f "$CONFIG" ]] || return 1
	awk -v key="$key" '
    $0 ~ "^[[:space:]]*" key ":" {
      in_key = 1
      next
    }
    in_key && $0 ~ "^[A-Za-z0-9_]+:" {
      exit
    }
    in_key && $0 ~ "^[[:space:]]*-[[:space:]]+" {
      value = $0
      sub("^[[:space:]]*-[[:space:]]+", "", value)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      gsub(/^["'\'']|["'\'']$/, "", value)
      if (value != "") print value
    }
  ' "$CONFIG"
}

cfg() {
	local key="$1"
	local default="$2"
	local value
	value="$(config_scalar "$key" || true)"
	[[ -n "$value" ]] && printf '%s\n' "$value" || printf '%s\n' "$default"
}

cfg_nested() {
	local section="$1"
	local key="$2"
	local default="$3"
	local value
	value="$(config_nested_scalar "$section" "$key" || true)"
	[[ -n "$value" ]] && printf '%s\n' "$value" || printf '%s\n' "$default"
}

PROJECT_NAME="$(cfg project_name "Palari Orchestration")"
OPEN_DIR="$(cfg tickets_open_dir "tickets/open")"
PROPOSED_DIR="$(cfg tickets_proposed_dir "tickets/proposed")"
CLOSED_DIR="$(cfg tickets_closed_dir "tickets/closed")"
REPORTS_DIR="$(cfg reports_dir "reports")"
HUMAN_REPORTS_DIR="$(cfg human_reports_dir "reports/human")"
PLANNING_REPORTS_DIR="$(cfg planning_reports_dir "reports/planning")"
HANDOFFS_DIR="$(cfg handoffs_dir "handoffs")"
AGENT_SKILLS_DIR="$(cfg agent_skills_dir "agent-skills")"
STATE_DIR="$(cfg state_dir ".palari")"
EVIDENCE_DIR="$(cfg evidence_dir "reports/evidence")"
ROLES_ACTIVE_DIR="$(cfg roles_active_dir "roles/active")"
ROLES_PROPOSED_DIR="$(cfg roles_proposed_dir "roles/proposed")"
ROLES_REVOKED_DIR="$(cfg roles_revoked_dir "roles/revoked")"
GOALS_ACTIVE_DIR="$(cfg goals_active_dir "goals/active")"
GOALS_PROPOSED_DIR="$(cfg goals_proposed_dir "goals/proposed")"
GOALS_CLOSED_DIR="$(cfg goals_closed_dir "goals/closed")"
DECISIONS_OPEN_DIR="$(cfg decisions_open_dir "decisions/open")"
DECISIONS_DECIDED_DIR="$(cfg decisions_decided_dir "decisions/decided")"
REQUIRE_SERVES_GOAL="$(cfg require_serves_goal "warn")"
DEFAULT_BRANCH="$(cfg default_branch "main")"
WORKTREE_BASE="$(cfg worktree_base "../$(basename "$ROOT")-worktrees")"
CLAIM_LEASE_SECONDS="$(cfg claim_lease_seconds "300")"
SCOPE_OVERLAP_POLICY="$(cfg scope_overlap_policy "block")"
MEMORY_DIR="$(cfg memory_dir "memory")"
MEMORY_INDEX_BACKEND="$(cfg memory_index_backend "sqlite")"

abs_path() {
	local path="$1"
	[[ "$path" == /* ]] || path="$ROOT/$path"
	# Normalize "." and ".." segments so computed worktree paths are stable
	# and never re-embed traversal segments (the source of a past committed
	# "ID/../base/ID" artifact).
	local IFS='/' segment
	local -a parts=() out=()
	read -r -a parts <<<"$path"
	for segment in "${parts[@]}"; do
		case "$segment" in
		"" | ".") ;;
		"..")
			((${#out[@]} > 0)) && unset 'out[${#out[@]}-1]'
			;;
		*) out+=("$segment") ;;
		esac
	done
	printf '/%s\n' "$(
		IFS='/'
		printf '%s' "${out[*]-}"
	)"
}

WORKTREE_BASE_ABS="$(abs_path "$WORKTREE_BASE")"

today_utc() {
	date -u +%F
}

now_utc() {
	date -u +%Y-%m-%dT%H:%M:%SZ
}

epoch_utc() {
	date -u +%s
}

iso_from_epoch() {
	local epoch="$1"
	date -u -d "@$epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null ||
		date -u -r "$epoch" +%Y-%m-%dT%H:%M:%SZ
}

epoch_from_iso() {
	local iso="$1"
	date -u -d "$iso" +%s 2>/dev/null ||
		date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso" +%s 2>/dev/null ||
		printf '0\n'
}

xml_escape() {
	sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g' -e "s/'/\&apos;/g"
}

json_escape() {
	sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g'
}

shell_quote() {
	local value="$1"
	printf "'%s'" "$(printf '%s' "$value" | sed "s/'/'\\\\''/g")"
}

json_string() {
	# Pure-Bash JSON escaping for the common cases; avoids one sed subprocess
	# per string, which dominates legacy snapshot cost when called hundreds
	# of times. Control characters other than \n/\t/\r fall back to sed.
	local value="${1:-}"
	if [[ "$value" == *[$'\x01'-$'\x08\x0b\x0c\x0e'-$'\x1f']* ]]; then
		printf '"%s"' "$(printf '%s' "$value" | json_escape)"
		return
	fi
	value="${value//\\/\\\\}"
	value="${value//\"/\\\"}"
	value="${value//$'\n'/\\n}"
	value="${value//$'\t'/\\t}"
	value="${value//$'\r'/\\r}"
	printf '"%s"' "$value"
}

json_bool() {
	[[ "${1:-}" == "true" ]] && printf 'true' || printf 'false'
}

json_nonempty_bool() {
	[[ -n "${1:-}" ]] && printf 'true' || printf 'false'
}

sha256_file() {
	local file="$1"
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$file" | awk '{ print $1 }'
	elif command -v shasum >/dev/null 2>&1; then
		shasum -a 256 "$file" | awk '{ print $1 }'
	else
		die "sha256sum or shasum is required for evidence integrity checks"
	fi
}

sha256_text() {
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum | awk '{ print $1 }'
	elif command -v shasum >/dev/null 2>&1; then
		shasum -a 256 | awk '{ print $1 }'
	else
		die "sha256sum or shasum is required for evidence integrity checks"
	fi
}

json_frontmatter_list() {
	local file="$1"
	local key="$2"
	local item first="true"
	printf '['
	while IFS= read -r item; do
		[[ -n "$item" ]] || continue
		[[ "$first" == "true" ]] || printf ','
		json_string "$item"
		first="false"
	done < <(frontmatter_list_items "$file" "$key")
	printf ']'
}

json_file_list() {
	local dir="$1"
	local file first="true"
	printf '['
	[[ -d "$dir" ]] || {
		printf ']'
		return 0
	}
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		[[ "$first" == "true" ]] || printf ','
		json_string "$(basename "$file")"
		first="false"
	done < <(find "$dir" -maxdepth 1 -type f ! -name '.gitkeep' | sort)
	printf ']'
}

configured_default_forbidden_paths() {
	local item count=0
	while IFS= read -r item; do
		[[ -n "$item" ]] || continue
		printf '%s\n' "$item"
		count=$((count + 1))
	done < <(config_list default_forbidden_paths || true)
	if ((count == 0)); then
		printf '%s\n' "${DEFAULT_FORBIDDEN_PATHS[@]}"
	fi
}

require_dir() {
	local rel="$1"
	[[ -d "$ROOT/$rel" ]] || die "missing required folder: $rel; run \`palari init\`"
}

require_base_folders() {
	require_dir "$PROPOSED_DIR"
	require_dir "$OPEN_DIR"
	require_dir "$CLOSED_DIR"
	require_dir "$REPORTS_DIR"
	require_dir "$HUMAN_REPORTS_DIR"
	require_dir "$PLANNING_REPORTS_DIR"
	require_dir "$EVIDENCE_DIR"
	require_dir "$HANDOFFS_DIR"
}

ticket_files() {
	require_dir "$OPEN_DIR"
	find "$ROOT/$OPEN_DIR" -maxdepth 1 -type f \( -name '*.md' -o -name '*.markdown' \) ! -name 'README.md' | sort
}

proposal_files() {
	require_dir "$PROPOSED_DIR"
	find "$ROOT/$PROPOSED_DIR" -maxdepth 1 -type f \( -name '*.md' -o -name '*.markdown' \) ! -name 'README.md' | sort
}

closed_ticket_files() {
	require_dir "$CLOSED_DIR"
	find "$ROOT/$CLOSED_DIR" -maxdepth 1 -type f \( -name '*.md' -o -name '*.markdown' \) ! -name 'README.md' | sort
}

all_ticket_files() {
	ticket_files
	closed_ticket_files
}

frontmatter_value() {
	local file="$1"
	local key="$2"
	awk -v key="$key" '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm {
      split($0, parts, ":")
      if (parts[1] == key) {
        sub("^[^:]*:[[:space:]]*", "", $0)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
        gsub(/^["'\'']|["'\'']$/, "", $0)
        print $0
        exit
      }
    }
  ' "$file"
}

has_frontmatter() {
	local file="$1"
	awk '
    NR == 1 && $0 == "---" { start = 1; next }
    start && $0 == "---" { end = 1; exit }
    END { exit !(start && end) }
  ' "$file"
}

frontmatter_has_key() {
	local file="$1"
	local key="$2"
	awk -v key="$key" '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && $0 ~ "^[A-Za-z0-9_]+:" {
      split($0, parts, ":")
      if (parts[1] == key) { found = 1; exit }
    }
    END { exit !found }
  ' "$file"
}

frontmatter_list_items() {
	local file="$1"
	local key="$2"
	awk -v key="$key" '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && $0 ~ "^[A-Za-z0-9_]+:" {
      split($0, parts, ":")
      if (parts[1] == key) {
        in_key = 1
        next
      }
      if (in_key) exit
    }
    in_fm && in_key && $0 ~ "^[[:space:]]*-[[:space:]]+" {
      value = $0
      sub("^[[:space:]]*-[[:space:]]+", "", value)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      gsub(/^["'\'']|["'\'']$/, "", value)
      if (value != "") print value
    }
  ' "$file"
}

frontmatter_yaml_issues() {
	# Print one line per frontmatter line that a strict YAML parser would
	# reject or misread: unquoted list items or scalars starting with an
	# alias/anchor/tag indicator (*, &, !). Palari's own parser tolerates
	# these, but tickets must stay valid YAML for external tooling.
	local file="$1"
	awk '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && $0 ~ /^[[:space:]]*-[[:space:]]+[*&!]/ {
      printf "line %d: unquoted YAML list item starts with an indicator character: %s\n", NR, $0
    }
    in_fm && $0 ~ /^[A-Za-z0-9_]+:[[:space:]]+[*&!]/ {
      printf "line %d: unquoted YAML scalar starts with an indicator character: %s\n", NR, $0
    }
  ' "$file"
}

frontmatter_list_count() {
	local file="$1"
	local key="$2"
	frontmatter_list_items "$file" "$key" | wc -l | tr -d ' '
}

in_words() {
	local value="$1"
	local words="$2"
	local word
	for word in $words; do
		[[ "$value" == "$word" ]] && return 0
	done
	return 1
}

valid_ticket_id() {
	local id="$1"
	[[ "$id" =~ ^[A-Z][A-Z0-9]{2}-[0-9]{4}(-[A-Z]+){0,2}$ ]]
}

valid_proposal_id() {
	local id="$1"
	[[ "$id" =~ ^([A-Z][A-Z0-9]{2}-)?PROP-[0-9]{4}$ ]]
}

ticket_title_from_file() {
	local file="$1"
	basename "$file" | sed -E 's/\.(md|markdown)$//'
}

find_proposal_file() {
	local proposal="$1"
	local file id base
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		id="$(frontmatter_value "$file" id)"
		base="$(basename "$file")"
		if [[ "$id" == "$proposal" || "$base" == "$proposal" || "${base%.md}" == "$proposal" ]]; then
			printf '%s\n' "$file"
			return 0
		fi
	done < <(proposal_files)
	return 1
}

find_ticket_file() {
	local ticket="$1"
	local file id base
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		id="$(frontmatter_value "$file" id)"
		base="$(basename "$file")"
		if [[ "$id" == "$ticket" || "$base" == "$ticket" || "${base%.md}" == "$ticket" ]]; then
			printf '%s\n' "$file"
			return 0
		fi
	done < <(all_ticket_files)
	return 1
}

ticket_default_branch() {
	local ticket_id="$1"
	printf 'ticket/%s\n' "$ticket_id"
}

ticket_default_worktree() {
	local ticket_id="$1"
	printf '%s/%s\n' "$WORKTREE_BASE_ABS" "$ticket_id"
}

ticket_declared_branch() {
	local file="$1"
	local ticket_id="$2"
	local branch
	branch="$(frontmatter_value "$file" branch)"
	[[ -n "$branch" ]] || branch="$(ticket_default_branch "$ticket_id")"
	printf '%s\n' "$branch"
}

ticket_declared_worktree() {
	local file="$1"
	local ticket_id="$2"
	local worktree
	worktree="$(frontmatter_value "$file" worktree)"
	[[ -n "$worktree" ]] || worktree="$(ticket_default_worktree "$ticket_id")"
	printf '%s\n' "$worktree"
}

update_frontmatter_scalars() {
	local file="$1"
	shift
	local tmp="${file}.tmp.$$"
	local pairs="" pair
	for pair in "$@"; do
		pairs+="$pair"
	done
	awk -v pairs="$pairs" '
    BEGIN {
      n = split(pairs, raw, "\034")
      for (i = 1; i <= n; i++) {
        if (raw[i] == "") continue
        split(raw[i], kv, "\035")
        updates[kv[1]] = kv[2]
      }
    }
    NR == 1 && $0 == "---" { in_fm = 1; print; next }
    in_fm && $0 == "---" { in_fm = 0; print; next }
    in_fm && $0 ~ "^[A-Za-z0-9_]+:" {
      split($0, parts, ":")
      key = parts[1]
      if (key in updates) {
        print key ": " updates[key]
        next
      }
    }
    { print }
  ' "$file" >"$tmp"
	mv "$tmp" "$file"
}

git_changed_paths() {
	local base_ref="${1:-}"
	if ! git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		die "not inside a git worktree: $ROOT"
	fi
	if [[ -n "$base_ref" ]]; then
		git -C "$ROOT" rev-parse --verify "$base_ref" >/dev/null 2>&1 ||
			die "scope-check base ref not found: $base_ref"
		git -C "$ROOT" diff --name-only --relative "$base_ref"...HEAD -- . | sed '/^$/d' | sort -u
	else
		(
			git -C "$ROOT" diff --name-only --relative -- .
			git -C "$ROOT" diff --name-only --cached --relative -- .
			git -C "$ROOT" ls-files --others --exclude-standard -- .
		) | sed '/^$/d' | sort -u
	fi
}

git_changed_count_at() {
	local path="$1"
	git -C "$path" status --short -- . 2>/dev/null | wc -l | tr -d ' '
}

require_clean_git_at() {
	local path="$1"
	local label="$2"
	local changed
	changed="$(git_changed_count_at "$path")"
	[[ "$changed" == "0" ]] || die "$label has $changed changed path(s); commit accepted work or choose a clean worktree first"
}

branch_contains_ref_at() {
	local path="$1"
	local branch="$2"
	local ref="$3"
	git -C "$path" merge-base --is-ancestor "$ref" "$branch" >/dev/null 2>&1
}

require_ticket_worktree_ready() {
	local ticket_id="$1"
	local branch="$2"
	local worktree="$3"
	local purpose="$4"
	local target_branch="$5"
	local actual_branch changed
	[[ -d "$worktree" ]] || die "$purpose: missing ticket worktree: $worktree; run \`palari worktree $ticket_id\`"
	git -C "$worktree" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
		die "$purpose: not a git worktree: $worktree"
	actual_branch="$(git -C "$worktree" branch --show-current 2>/dev/null || true)"
	[[ "$actual_branch" == "$branch" ]] ||
		die "$purpose: branch mismatch for $worktree; expected $branch, got ${actual_branch:-detached}"
	if git -C "$ROOT" rev-parse --verify "$target_branch" >/dev/null 2>&1; then
		branch_contains_ref_at "$ROOT" "$branch" "$target_branch" ||
			die "$purpose: ticket branch $branch does not contain $target_branch"
	fi
	changed="$(git_changed_count_at "$worktree")"
	[[ "$changed" == "0" ]] || die "$purpose: ticket worktree has $changed changed path(s): $worktree"
}

path_matches_pattern() {
	local path="${1#./}"
	local pattern="${2#./}"
	# shellcheck disable=SC2053 # Ticket path patterns intentionally use shell globs.
	[[ "$path" == $pattern ]]
}

check_path_against_patterns() {
	local path="$1"
	shift
	local pattern
	for pattern in "$@"; do
		[[ -n "$pattern" ]] || continue
		if path_matches_pattern "$path" "$pattern"; then
			printf '%s\n' "$pattern"
			return 0
		fi
	done
	return 1
}

report_candidate_files() {
	local dir="$1"
	require_dir "$dir"
	find "$ROOT/$dir" -maxdepth 1 -type f \( -name '*.md' -o -name '*.markdown' \) ! -name 'README.md' | sort
}

file_references_ticket() {
	local file="$1"
	local ticket_id="$2"
	local base
	base="$(basename "$file")"
	[[ "$base" == *"$ticket_id"* ]] && return 0
	grep -Eq "(^# ${ticket_id}([[:space:]]|$)|^[[:space:]]*[-*]?[[:space:]]*Ticket:[[:space:]]*${ticket_id}([[:space:]]|$)|^[[:space:]]*ticket:[[:space:]]*${ticket_id}([[:space:]]|$))" "$file"
}

find_report_file() {
	local dir="$1"
	local ticket_id="$2"
	local marker="${3:-}"
	local file
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		file_references_ticket "$file" "$ticket_id" || continue
		if [[ -n "$marker" ]] && ! grep -Eq "$marker" "$file"; then
			continue
		fi
		printf '%s\n' "$file"
		return 0
	done < <(report_candidate_files "$dir")
	return 1
}

frontmatter_list_contains() {
	local file="$1"
	local key="$2"
	local wanted="$3"
	local item
	while IFS= read -r item; do
		[[ "$item" == "$wanted" ]] && return 0
	done < <(frontmatter_list_items "$file" "$key")
	return 1
}

ticket_required_reports() {
	local file="$1"
	local item
	while IFS= read -r item; do
		[[ -n "$item" ]] && printf '%s\n' "$item"
	done < <(config_list required_reports || true)
	while IFS= read -r item; do
		[[ -n "$item" ]] && printf '%s\n' "$item"
	done < <(frontmatter_list_items "$file" required_reports)
	return 0
}

find_named_report_file() {
	local ticket_id="$1"
	local report_name="$2"
	local slug="${report_name,,}"
	local file base text
	slug="${slug//_/-}"
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		file_references_ticket "$file" "$ticket_id" || continue
		base="$(basename "$file")"
		base="${base,,}"
		text="$(awk 'NR <= 40 { print tolower($0) }' "$file")"
		if [[ "$base" == *"$slug"* || "$text" == *"$slug"* || "$text" == *"${slug//-/ }"* ]]; then
			printf '%s\n' "$file"
			return 0
		fi
	done < <(report_candidate_files "$REPORTS_DIR")
	return 1
}

print_frontmatter_list_block() {
	local label="$1"
	local file="$2"
	local key="$3"
	local item count=0
	printf '%s:\n' "$label"
	while IFS= read -r item; do
		[[ -n "$item" ]] || continue
		printf '  - %s\n' "$item"
		count=$((count + 1))
	done < <(frontmatter_list_items "$file" "$key")
	((count > 0)) || printf '  - none detected\n'
}

count_status() {
	local wanted="$1"
	local count=0 file
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		[[ "$(frontmatter_value "$file" status)" == "$wanted" ]] && count=$((count + 1))
	done < <(ticket_files)
	printf '%s\n' "$count"
}

slugify() {
	printf '%s' "$*" |
		tr '[:upper:]' '[:lower:]' |
		sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}

titleize_slug() {
	local slug="$1"
	printf '%s\n' "$slug" | awk -F '-' '{
    for (i = 1; i <= NF; i++) {
      if ($i == "") continue
      printf "%s%s", toupper(substr($i, 1, 1)) substr($i, 2), (i == NF ? ORS : " ")
    }
  }'
}

valid_skill_name() {
	local name="$1"
	[[ "$name" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]
}

yaml_quote_item() {
	# Quote any scalar that a strict YAML parser would misread: leading
	# indicator characters (*, &, !, ?, -, etc), comments, or mapping colons.
	local value="$1"
	local needs_quote="false"
	case "$value" in
	"" | [\*\&\!\?\|\>\%\@\`\"\'\{\}\[\]-]* | ,*) needs_quote="true" ;;
	esac
	case "$value" in
	*": "* | *"#"* | *:) needs_quote="true" ;;
	esac
	if [[ "$value" == *$'\t'* ]]; then
		needs_quote="true"
	fi
	if [[ "$needs_quote" == "true" ]]; then
		value="${value//\\/\\\\}"
		value="${value//\"/\\\"}"
		printf '"%s"' "$value"
	else
		printf '%s' "$value"
	fi
}

write_yaml_list() {
	local name="$1"
	shift
	local value
	printf '%s:\n' "$name"
	if (($# == 0)); then
		printf '  - TODO\n'
		return
	fi
	for value in "$@"; do
		printf '  - %s\n' "$(yaml_quote_item "$value")"
	done
}

install_template_file() {
	local src="$1"
	local dest="$2"
	local force="${3:-false}"
	[[ -f "$ROOT/$src" ]] || die "missing adapter template: $src"
	mkdir -p "$(dirname "$ROOT/$dest")"
	if [[ -e "$ROOT/$dest" && "$force" != "true" ]]; then
		printf 'init: kept existing %s\n' "$dest"
		return 0
	fi
	cp "$ROOT/$src" "$ROOT/$dest"
	printf 'init: wrote %s\n' "$dest"
}

claim_ref_for_ticket() {
	local ticket_id="$1"
	printf 'refs/palari/claims/%s\n' "$ticket_id"
}

ticket_claim_expired() {
	local file="$1"
	local expires now_epoch expires_epoch
	expires="$(frontmatter_value "$file" claim_expires_at)"
	[[ -n "$expires" ]] || return 1
	now_epoch="$(epoch_utc)"
	expires_epoch="$(epoch_from_iso "$expires")"
	[[ "$expires_epoch" != "0" && "$now_epoch" -gt "$expires_epoch" ]]
}

create_git_claim_ref() {
	local ticket_id="$1"
	local ref="$2"
	local head zeros
	zeros="0000000000000000000000000000000000000000"
	git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
	head="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null)" || return 0
	if git -C "$ROOT" update-ref "$ref" "$head" "$zeros" 2>/dev/null; then
		printf '%s\n' "$head"
		return 0
	fi
	die "ticket $ticket_id already has a git claim ref: $ref"
}

github_repo_slug() {
	local remote
	remote="$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)"
	case "$remote" in
	git@github.com:*)
		remote="${remote#git@github.com:}"
		remote="${remote%.git}"
		;;
	https://github.com/* | http://github.com/*)
		remote="${remote#https://github.com/}"
		remote="${remote#http://github.com/}"
		remote="${remote%.git}"
		;;
	*)
		remote=""
		;;
	esac
	[[ "$remote" == */* ]] && printf '%s\n' "$remote" || return 1
}

ruleset_name_from_file() {
	local file="${1:-.github/palari-required-checks.ruleset.json}"
	local path="$file" name
	[[ "$path" == /* ]] || path="$ROOT/$path"
	name="$(awk '
    match($0, /"name"[[:space:]]*:[[:space:]]*"[^"]+"/) {
      value = substr($0, RSTART, RLENGTH)
      sub(/^"name"[[:space:]]*:[[:space:]]*"/, "", value)
      sub(/"$/, "", value)
      print value
      exit
    }
  ' "$path" 2>/dev/null || true)"
	[[ -n "$name" ]] && printf '%s\n' "$name" || printf 'Palari required checks\n'
}

ruleset_activation_command() {
	local repo="${1:-}"
	local file="${2:-.github/palari-required-checks.ruleset.json}"
	local ruleset_name jq_filter
	[[ -n "$repo" ]] || repo="$(github_repo_slug || true)"
	[[ -n "$repo" ]] || repo="OWNER/REPO"
	ruleset_name="$(ruleset_name_from_file "$file")"
	jq_filter=".[] | select(.name == \"$ruleset_name\") | .id"
	# shellcheck disable=SC2016 # The printed command must contain a literal command substitution.
	printf 'id=$(gh api repos/%s/rulesets --jq %s)\n' "$repo" "$(shell_quote "$jq_filter")"
	# shellcheck disable=SC2016 # The printed command must contain literal $id references.
	printf 'if [ -n "$id" ]; then gh api --method PATCH repos/%s/rulesets/"$id" --input %s; else gh api --method POST repos/%s/rulesets --input %s; fi\n' \
		"$repo" "$(shell_quote "$file")" "$repo" "$(shell_quote "$file")"
}

OVERLAP_IGNORED_PATTERNS_LOADED="false"
OVERLAP_IGNORED_PATTERNS=()
OVERLAP_IGNORED_PREFIXES=()

load_ignored_overlap_patterns() {
	[[ "$OVERLAP_IGNORED_PATTERNS_LOADED" == "true" ]] && return 0
	local item prefix count=0
	while IFS= read -r item; do
		[[ -n "$item" ]] || continue
		OVERLAP_IGNORED_PATTERNS+=("$item")
		count=$((count + 1))
	done < <(config_list concurrency_ignored_overlap_paths || true)
	if ((count == 0)); then
		OVERLAP_IGNORED_PATTERNS=("tickets/**" "reports/**" "reports/human/**" "handoffs/**" ".palari/**")
	fi
	for item in "${OVERLAP_IGNORED_PATTERNS[@]}"; do
		pattern_prefix_to_var "$item" prefix
		OVERLAP_IGNORED_PREFIXES+=("$prefix")
	done
	OVERLAP_IGNORED_PATTERNS_LOADED="true"
}

ignored_overlap_patterns() {
	local item
	load_ignored_overlap_patterns
	for item in "${OVERLAP_IGNORED_PATTERNS[@]}"; do
		printf '%s\n' "$item"
	done
}

pattern_prefix_to_var() {
	local pattern="${1#./}"
	local var_name="$2"
	pattern="${pattern%/**}"
	pattern="${pattern%/*}"
	printf -v "$var_name" '%s' "$pattern"
}

pattern_prefix() {
	local prefix
	pattern_prefix_to_var "$1" prefix
	printf '%s\n' "$prefix"
}

pattern_ignored_for_overlap() {
	local pattern="$1"
	local pattern_prefix_value ignored index
	load_ignored_overlap_patterns
	pattern_prefix_to_var "$pattern" pattern_prefix_value
	for index in "${!OVERLAP_IGNORED_PATTERNS[@]}"; do
		ignored="${OVERLAP_IGNORED_PATTERNS[$index]}"
		[[ -n "$ignored" ]] || continue
		[[ "$pattern" == "$ignored" ]] && return 0
		[[ "$pattern_prefix_value" == "${OVERLAP_IGNORED_PREFIXES[$index]}" ]] && return 0
	done
	return 1
}

patterns_overlap() {
	local left="$1"
	local right="$2"
	local lp rp
	pattern_ignored_for_overlap "$left" && return 1
	pattern_ignored_for_overlap "$right" && return 1
	[[ "$left" == "$right" ]] && return 0
	pattern_prefix_to_var "$left" lp
	pattern_prefix_to_var "$right" rp
	[[ -n "$lp" && -n "$rp" ]] || return 1
	[[ "$lp" == "$rp" ]] && return 0
	[[ "$lp" == "$rp/"* || "$rp" == "$lp/"* ]]
}

scope_overlap_errors() {
	local focus_file="$1"
	local focus_id other_file other_id focus_pattern other_pattern other_status errors=0
	focus_id="$(frontmatter_value "$focus_file" id)"
	while IFS= read -r other_file; do
		[[ -n "$other_file" && "$other_file" != "$focus_file" ]] || continue
		other_status="$(frontmatter_value "$other_file" status)"
		case "$other_status" in
		open | claimed | reopened | in-review) ;;
		*) continue ;;
		esac
		other_id="$(frontmatter_value "$other_file" id)"
		while IFS= read -r focus_pattern; do
			[[ -n "$focus_pattern" ]] || continue
			while IFS= read -r other_pattern; do
				[[ -n "$other_pattern" ]] || continue
				if patterns_overlap "$focus_pattern" "$other_pattern"; then
					printf 'scope-overlaps: %s overlaps %s (%s <> %s)\n' \
						"$focus_id" "$other_id" "$focus_pattern" "$other_pattern" >&2
					errors=$((errors + 1))
				fi
			done < <(frontmatter_list_items "$other_file" allowed_paths)
		done < <(frontmatter_list_items "$focus_file" allowed_paths)
	done < <(ticket_files)
	return "$errors"
}
