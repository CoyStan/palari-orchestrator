#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'decisions: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* goals decisions memory/decisions/*.md
mkdir -p goals/active decisions/open decisions/decided

git init -b main >/dev/null
git config user.email "decisions@example.invalid"
git config user.name "Decisions Test"
git add .
git commit -m "decisions baseline" >/dev/null

# A decision needs at least two options.
if ./bin/palari decide create DEC-0001 "One option" --option "Only path" >/dev/null 2>&1; then
	fail "single-option decision should be rejected"
fi

# Create a valid decision.
./bin/palari decide create DEC-0001 "Pick storage backend" \
	--option "SQLite (simple, single file)" \
	--option "Postgres (heavier, multi-user)" \
	--recommend 1 --default 1 --respond-by 2099-01-01 >"$TMP_ROOT/create.out"
grep -Fq "decide create: decisions/open/DEC-0001-pick-storage-backend.md" "$TMP_ROOT/create.out" ||
	fail "decide create did not write the open decision file"
grep -Fq "recommended_option: 1" decisions/open/DEC-0001-*.md ||
	fail "decision frontmatter missing recommendation"

# Recommendation outside the option range is rejected.
if ./bin/palari decide create DEC-0002 "Bad rec" --option a --option b --recommend 3 >/dev/null 2>&1; then
	fail "out-of-range --recommend should be rejected"
fi

# Open decisions appear in the snapshot.
./bin/palari snapshot --json >"$TMP_ROOT/snapshot.json"
grep -Fq '"open_decisions":[{"id":"DEC-0001"' "$TMP_ROOT/snapshot.json" ||
	fail "snapshot missing open decision"

# decide lint passes on the well-formed decision.
./bin/palari decide lint >/dev/null || fail "decide lint should pass"

# Recording requires a human (--by) and a valid choice.
if ./bin/palari decide record DEC-0001 --choice 1 >/dev/null 2>&1; then
	fail "decide record without --by should be rejected"
fi
if ./bin/palari decide record DEC-0001 --choice 9 --by founder >/dev/null 2>&1; then
	fail "decide record with an invalid choice should be rejected"
fi
./bin/palari decide record DEC-0001 --choice 2 --by founder --note "Multi-user matters" >"$TMP_ROOT/record.out"
[[ -f decisions/decided/DEC-0001-pick-storage-backend.md ]] ||
	fail "recorded decision not moved to decisions/decided"
grep -Fq "chosen_option: 2" decisions/decided/DEC-0001-*.md ||
	fail "recorded decision missing chosen_option"
grep -Fq "Chosen: Option 2" decisions/decided/DEC-0001-*.md ||
	fail "recorded decision missing outcome section"
[[ -f memory/decisions/DEC-0001-pick-storage-backend.md ]] ||
	fail "recorded decision not mirrored into repo memory"

# Recorded decisions cannot be recorded twice.
if ./bin/palari decide record DEC-0001 --choice 1 --by founder >/dev/null 2>&1; then
	fail "an already-decided decision should not be recordable again"
fi

# Snapshot no longer lists it as open.
./bin/palari snapshot --json >"$TMP_ROOT/snapshot2.json"
grep -Fq '"open_decisions":[]' "$TMP_ROOT/snapshot2.json" ||
	fail "snapshot should show no open decisions after recording"

printf 'decisions: ok\n'
