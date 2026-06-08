#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
	printf 'cli-structure: %s\n' "$*" >&2
	exit 1
}

entry_lines="$(wc -l <"$ROOT/bin/palari" | tr -d ' ')"
((entry_lines <= 300)) || fail "bin/palari has $entry_lines lines; expected <= 300"

if grep -Eq '^cmd_[A-Za-z0-9_]+\(\)' "$ROOT/bin/palari"; then
	fail "bin/palari defines command implementations; keep implementations in lib/palari"
fi

modules=(
	core
	authority_lifecycle
	roles
	init_adopt
	proposals
	tickets_workspace
	agents_review_scope
	ci_accept
	dashboard_snapshot
	adapters_snapshot
)

for module in "${modules[@]}"; do
	path="$ROOT/lib/palari/$module.bash"
	[[ -s "$path" ]] || fail "missing module: lib/palari/$module.bash"
	bash -n "$path"
	grep -Fq "source \"\$PALARI_LIB_DIR/$module.bash\"" "$ROOT/bin/palari" ||
		fail "bin/palari does not source $module.bash"
	lines="$(wc -l <"$path" | tr -d ' ')"
	((lines <= 900)) || fail "lib/palari/$module.bash has $lines lines; expected <= 900"
done

grep -Fq '"lib"' "$ROOT/lib/palari/core.bash" ||
	fail "adoption path list does not include lib"

grep -Fq "doctor_check_file \"lib/palari/core.bash\"" "$ROOT/lib/palari/init_adopt.bash" ||
	fail "doctor does not check the Palari module set"

grep -Fq "## Fixed Enough Criteria" "$ROOT/contracts/cli-maintainability.md" ||
	fail "missing CLI maintainability criteria"

printf 'cli-structure: ok\n'
