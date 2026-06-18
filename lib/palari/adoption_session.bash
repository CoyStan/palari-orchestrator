# shellcheck shell=bash
# shellcheck disable=SC2153 # Sourced after core.bash/init_adopt.bash.

write_session_file() {
	local rel="$1" force="$2" dry_run="$3" dest="$4"
	if [[ -e "$dest" && "$force" != "true" ]]; then
		printf 'adopt: kept existing %s\n' "$rel"
		return 0
	fi
	[[ -e "$dest" ]] && printf 'adopt: overwrite %s\n' "$rel" || printf 'adopt: write %s\n' "$rel"
	[[ "$dry_run" == "true" ]] && return 0
	mkdir -p "$(dirname "$dest")"
	cat >"$dest"
}

write_governance_session_config() {
	local target="$1" force="$2" dry_run="$3" project_name
	project_name="$(basename "$target")"
	write_session_file "palari.config.yaml" "$force" "$dry_run" "$target/palari.config.yaml" <<EOF
project_name: "$project_name"
default_branch: main
state_dir: .palari
worktree_base: ../$project_name-worktrees
require_serves_goal: warn
scope_overlap_policy: block
session:
  mode: governance-only
  orchestrator_source: "$ROOT"
EOF
}

write_governance_session_agent_contract() {
	local target="$1" force="$2" dry_run="$3" dest="$target/AGENTS.md" rel="AGENTS.md"
	if [[ -e "$dest" && "$force" != "true" ]]; then
		dest="$target/AGENTS.palari.md"
		rel="AGENTS.palari.md"
	fi
	write_session_file "$rel" "$force" "$dry_run" "$dest" <<EOF
# Palari Governance Session

This repository uses Palari governance-session scaffolding without vendoring the
Palari orchestrator runtime.

- Use tickets, goals, decisions, workflows, humans, reports, handoffs, and
  evidence as the governance source of truth for AI-assisted work.
- Do not copy upstream Palari internals into this repository, including
  lib/palari, adapters, gate, research, upstream tests, vendor data, or POS/COS
  report history.
- Run commands from the external orchestrator checkout with PALARI_ROOT pointing
  at this repository.

\`\`\`bash
PALARI_ROOT=$(shell_quote "$target") \\
PALARI_LIB_DIR=$(shell_quote "$ROOT/lib/palari") \\
$(shell_quote "$ROOT/bin/palari") status
\`\`\`
EOF
}

cmd_adopt_governance_only() {
	local target_abs="$1" force="$2" dry_run="$3"
	printf 'adopt: mode governance-only\n'
	write_governance_session_config "$target_abs" "$force" "$dry_run"
	write_governance_session_agent_contract "$target_abs" "$force" "$dry_run"
	[[ "$dry_run" == "true" ]] && {
		printf 'adopt: dry-run complete\n'
		return 0
	}
	PALARI_ROOT="$target_abs" PALARI_LIB_DIR="$ROOT/lib/palari" "$ROOT/bin/palari" init >/dev/null
	printf 'adopt: ok governance-only\n'
	printf 'next:\n'
	printf '  cd %s\n' "$(shell_quote "$target_abs")"
	printf '  PALARI_ROOT=%s PALARI_LIB_DIR=%s %s status\n' \
		"$(shell_quote "$target_abs")" "$(shell_quote "$ROOT/lib/palari")" "$(shell_quote "$ROOT/bin/palari")"
	printf '  PALARI_ROOT=%s PALARI_LIB_DIR=%s %s propose create APP-PROP-0001 "First scoped change" --intent "Describe the change you want."\n' \
		"$(shell_quote "$target_abs")" "$(shell_quote "$ROOT/lib/palari")" "$(shell_quote "$ROOT/bin/palari")"
}
