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
	demo
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

# --- Manifest validation coverage ---
ci_accept="$ROOT/lib/palari/ci_accept.bash"

check_manifest_has() {
	local label="$1" pattern="$2"
	grep -q "$pattern" "$ci_accept" || fail "manifest validation missing: $label"
}

check_manifest_has "schema_version check" '"schema_version"'
check_manifest_has "generator check" '"generator"'
check_manifest_has "ticket id match" '"ticket"'
check_manifest_has "status passed requirement" '"status"'
check_manifest_has "artifacts list type check" 'isinstance(artifacts, list)'
check_manifest_has "sha256 length check" 'len(digest)'
check_manifest_has "path escape guard" 'relative_to'
check_manifest_has "sha256 checksum verify" 'hashlib.sha256'
check_manifest_has "required artifact set check" 'required - seen'
check_manifest_has "missing artifact report" 'missing artifact'
check_manifest_has "ci_existing_evidence_valid function" 'ci_existing_evidence_valid()'
check_manifest_has "ticket_evidence_manifest_valid function" 'ticket_evidence_manifest_valid()'
check_manifest_has "ci diagnostic output" 'invalid evidence manifest'
check_manifest_has "accept diagnostic output" 'invalid evidence manifest'

# Overlap-detection regression: verify scope-overlaps diagnostic
OVERLAP_OUT="$(mktemp)"
cleanup_overlap() {
	rm -f "$ROOT/tickets/open/POS-TEST-001-alpha.md" \
		"$ROOT/tickets/open/POS-TEST-002-beta.md" \
		"$OVERLAP_OUT"
}
trap cleanup_overlap EXIT

cat >"$ROOT/tickets/open/POS-TEST-001-alpha.md" <<'TICKET'
---
id: POS-TEST-001
title: Overlap Alpha
status: open
risk: R1
allowed_paths:
  - check-alpha/**
---
TICKET

cat >"$ROOT/tickets/open/POS-TEST-002-beta.md" <<'TICKET'
---
id: POS-TEST-002
title: Overlap Beta
status: open
risk: R1
allowed_paths:
  - check-alpha/golden/**
---
TICKET

if "$ROOT/bin/palari" scope-overlaps POS-TEST-001 >"$OVERLAP_OUT" 2>&1; then
	fail "scope-overlaps expected overlap detection"
fi

grep -Fq "scope-overlaps: POS-TEST-001 overlaps POS-TEST-002" "$OVERLAP_OUT" ||
	fail "overlap diagnostic missing scope-overlaps wording"

printf 'cli-structure: ok\n'
