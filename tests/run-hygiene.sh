#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'hygiene: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"

(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-hygiene.sh
rm -f tickets/open/*.md tickets/open/*.markdown tickets/proposed/*.md tickets/proposed/*.markdown tickets/closed/*.md tickets/closed/*.markdown
rm -f reports/*.md reports/*.markdown reports/planning/*.md reports/planning/*.markdown reports/human/*.md reports/human/*.markdown handoffs/*.md handoffs/*.markdown
rm -rf reports/evidence/*
git init -b main >/dev/null
git config user.email "hygiene@example.invalid"
git config user.name "Hygiene Test"

./bin/palari init >"$TMP_ROOT/init.out"
grep -Fq "init: ok" "$TMP_ROOT/init.out"
grep -Fxq ".palari/" .gitignore
grep -Fxq "__pycache__/" .gitignore
grep -Fxq "*.pyc" .gitignore
grep -Fxq ".expo/" .gitignore
grep -Fxq ".metro/" .gitignore
grep -Fxq "node_modules/" .gitignore

mkdir -p gate/forgegate/__pycache__
printf 'old bytecode\n' >gate/forgegate/__pycache__/tracked.pyc
git add -f gate/forgegate/__pycache__/tracked.pyc
git add .
git commit -m "hygiene baseline" >/dev/null

printf 'new bytecode\n' >gate/forgegate/__pycache__/tracked.pyc
./bin/palari hygiene --strict >"$TMP_ROOT/generated-only.out"
grep -Fq "git: 1 dirty path(s) (1 generated, 0 source)" "$TMP_ROOT/generated-only.out"
grep -Fq "generated dirty paths:" "$TMP_ROOT/generated-only.out"
grep -Fq "gate/forgegate/__pycache__/tracked.pyc" "$TMP_ROOT/generated-only.out"
grep -Fq "summary: clean enough for the next autonomous ticket" "$TMP_ROOT/generated-only.out"

printf 'source drift\n' >source-change.txt
if ./bin/palari hygiene --strict >"$TMP_ROOT/source-dirty.out" 2>&1; then
	fail "strict hygiene should fail when source changes are present"
fi
grep -Fq "git: 2 dirty path(s) (1 generated, 1 source)" "$TMP_ROOT/source-dirty.out"
grep -Fq "source dirty paths:" "$TMP_ROOT/source-dirty.out"
grep -Fq "source-change.txt" "$TMP_ROOT/source-dirty.out"
grep -Fq "summary: action needed" "$TMP_ROOT/source-dirty.out"

printf 'hygiene: ok\n'
