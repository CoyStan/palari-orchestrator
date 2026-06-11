#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"

(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari
rm -rf .palari
rm -f tickets/open/*.md tickets/proposed/*.md tickets/closed/*.md
rm -f reports/*.md reports/planning/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/*

git init -b main >/dev/null
git config user.email "sandbox@example.invalid"
git config user.name "Sandbox Test"

./bin/palari init >/dev/null

./bin/palari ticket create LAB-0001 "Sandbox lifecycle smoke" \
	--stream process \
	--risk R1 \
	--allowed "docs/**" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--verify "sandbox lifecycle check" >/dev/null

git add .
git commit -m "sandbox test baseline" >/dev/null

run_create_writes_metadata() {
	./bin/palari sandbox create LAB-0001 >"$TMP_ROOT/create.out"
	grep -Fq "sandbox create: ok" "$TMP_ROOT/create.out"
	SANDBOX="$(sed -n 's/^Sandbox repo: //p' "$TMP_ROOT/create.out")"
	test -f "$SANDBOX/.palari-sandbox"
	test -f "$SANDBOX/.palari/sandbox.json"
	grep -Fq '"ticket": "LAB-0001"' "$SANDBOX/.palari/sandbox.json"
	grep -Fq '"mode": "local"' "$SANDBOX/.palari/sandbox.json"
	grep -Fq "\"source_commit\": \"$(git rev-parse HEAD)\"" "$SANDBOX/.palari/sandbox.json"
}

run_list_shows_sandbox() {
	./bin/palari sandbox list >"$TMP_ROOT/list.out"
	grep -Fq "LAB-0001	$SANDBOX	0 changed path(s)" "$TMP_ROOT/list.out"
	grep -Fq "sandbox list: 1 sandbox(es)" "$TMP_ROOT/list.out"
}

run_inspect_reports_state() {
	./bin/palari sandbox inspect LAB-0001 >"$TMP_ROOT/inspect-clean.out"
	grep -Fq "sandbox inspect: LAB-0001" "$TMP_ROOT/inspect-clean.out"
	grep -Fq "mode: local" "$TMP_ROOT/inspect-clean.out"
	grep -Fq "Changed paths: 0" "$TMP_ROOT/inspect-clean.out"

	printf 'sandbox dirt\n' >>"$SANDBOX/README.md"
	./bin/palari sandbox inspect LAB-0001 >"$TMP_ROOT/inspect-dirty.out"
	grep -Fq "Changed paths: 1" "$TMP_ROOT/inspect-dirty.out"
	grep -Eq "^  .M README.md" "$TMP_ROOT/inspect-dirty.out"
}

run_inspect_by_path() {
	./bin/palari sandbox inspect --path "$SANDBOX" >"$TMP_ROOT/inspect-path.out"
	grep -Fq "sandbox inspect: LAB-0001" "$TMP_ROOT/inspect-path.out"
}

run_destroy_refuses_non_sandbox() {
	mkdir -p "$TMP_ROOT/not-a-sandbox"
	if ./bin/palari sandbox destroy --path "$TMP_ROOT/not-a-sandbox" >"$TMP_ROOT/destroy-refuse.out" 2>"$TMP_ROOT/destroy-refuse.err"; then
		echo "sandbox destroy should refuse a non-sandbox path" >&2
		exit 1
	fi
	grep -Fq "refusing to remove non-Palari sandbox path" "$TMP_ROOT/destroy-refuse.err"
	test -d "$TMP_ROOT/not-a-sandbox"
}

run_destroy_removes_sandbox() {
	./bin/palari sandbox destroy LAB-0001 >"$TMP_ROOT/destroy.out"
	grep -Fq "sandbox destroy: removed $SANDBOX" "$TMP_ROOT/destroy.out"
	test ! -e "$SANDBOX"
	./bin/palari sandbox list >"$TMP_ROOT/list-after.out"
	grep -Fq "sandbox list: 0 sandbox(es)" "$TMP_ROOT/list-after.out"
}

run_create_writes_metadata
run_list_shows_sandbox
run_inspect_reports_state
run_inspect_by_path
run_destroy_refuses_non_sandbox
run_destroy_removes_sandbox

printf 'sandbox: ok\n'
