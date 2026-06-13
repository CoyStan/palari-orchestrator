#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
cd "$ROOT"

fail() {
	printf 'state: %s\n' "$*" >&2
	exit 1
}

[[ -f STATE.md ]] || fail "missing STATE.md"

./bin/palari state --path >"$TMP_ROOT/path.out"
grep -Fxq "$ROOT/STATE.md" "$TMP_ROOT/path.out" || fail "state --path did not print STATE.md"

./bin/palari state >"$TMP_ROOT/state.out"
grep -Fq "## Shipped" "$TMP_ROOT/state.out" || fail "state output missing shipped section"
grep -Fq "## Experimental / Opt-In" "$TMP_ROOT/state.out" || fail "state output missing experimental section"
grep -Fq "## Intentionally Not Supported" "$TMP_ROOT/state.out" || fail "state output missing not-supported section"
grep -Fq "OpenRouter" "$TMP_ROOT/state.out" || fail "state output missing OpenRouter"
grep -Fq "does not prove safety" "$TMP_ROOT/state.out" || fail "state output missing claim boundary"

./bin/palari --help >"$TMP_ROOT/help.out"
grep -Fq "state [--path]" "$TMP_ROOT/help.out" || fail "help missing state command"

printf 'state: ok\n'
