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

awk '
  { print }
  $0 == "hygiene_generated_paths:" { print "  - generated-local/**" }
' palari.config.yaml >"$TMP_ROOT/palari.config.yaml"
mv "$TMP_ROOT/palari.config.yaml" palari.config.yaml

mkdir -p gate/forgegate/__pycache__
printf 'old bytecode\n' >gate/forgegate/__pycache__/tracked.pyc
git add -f gate/forgegate/__pycache__/tracked.pyc
git add .
git commit -m "hygiene baseline" >/dev/null

mkdir -p node_modules/palari-cache dist
printf 'local cache\n' >node_modules/palari-cache/cache.txt
printf 'bundle\n' >dist/generated.js
mkdir -p generated-local
printf 'local generated dirt\n' >generated-local/cache.txt
./bin/palari ticket create HYG-0001 "Generated artifact scope" \
	--stream process \
	--risk R1 \
	--allowed "docs/**" \
	--allowed "tickets/open/HYG-0001-*" \
	--verify "true" >/dev/null
git add tickets/open/HYG-0001-*.md
git commit -m "route HYG-0001" >/dev/null
./bin/palari scope-check HYG-0001 >"$TMP_ROOT/generated-scope.out"
grep -Fq "scope-check: ok for HYG-0001" "$TMP_ROOT/generated-scope.out"
rm -rf generated-local

./bin/palari ticket create HYG-0002 "Generated artifact lint" \
	--stream process \
	--risk R1 \
	--allowed "node_modules/**" \
	--allowed "tickets/open/HYG-0002-*" \
	--verify "true" >/dev/null
if ./bin/palari lint HYG-0002 >"$TMP_ROOT/generated-allowed.out" 2>&1; then
	fail "ticket lint should reject generated allowed_paths"
fi
grep -Fq "allowed_paths must not include generated artifact path: node_modules/**" "$TMP_ROOT/generated-allowed.out"
git checkout -- tickets/open/HYG-0002-*.md 2>/dev/null || true
rm -f tickets/open/HYG-0002-*.md

printf 'new bytecode\n' >gate/forgegate/__pycache__/tracked.pyc
if ./bin/palari hygiene --strict >"$TMP_ROOT/tracked-generated.out" 2>&1; then
	fail "strict hygiene should fail when tracked generated files are modified"
fi
grep -Fq "git: 1 dirty path(s) (1 generated, 0 source, 1 tracked generated)" "$TMP_ROOT/tracked-generated.out"
grep -Fq "tracked generated paths:" "$TMP_ROOT/tracked-generated.out"
grep -Fq "gate/forgegate/__pycache__/tracked.pyc" "$TMP_ROOT/tracked-generated.out"
grep -Fq "summary: action needed" "$TMP_ROOT/tracked-generated.out"

git checkout -- gate/forgegate/__pycache__/tracked.pyc
mkdir -p generated-local
printf 'unignored cache\n' >generated-local/cache.txt
./bin/palari hygiene --strict >"$TMP_ROOT/generated-only.out"
grep -Fq "git: 1 dirty path(s) (1 generated, 0 source, 0 tracked generated)" "$TMP_ROOT/generated-only.out"
grep -Fq "generated dirty paths:" "$TMP_ROOT/generated-only.out"
grep -Fq "generated-local/" "$TMP_ROOT/generated-only.out"
grep -Fq "summary: clean enough for the next autonomous ticket" "$TMP_ROOT/generated-only.out"
rm -rf generated-local

printf 'new bytecode\n' >gate/forgegate/__pycache__/tracked.pyc
printf 'source drift\n' >source-change.txt
if ./bin/palari hygiene --strict >"$TMP_ROOT/source-dirty.out" 2>&1; then
	fail "strict hygiene should fail when source changes are present"
fi
grep -Fq "git: 2 dirty path(s) (1 generated, 1 source, 1 tracked generated)" "$TMP_ROOT/source-dirty.out"
grep -Fq "source dirty paths:" "$TMP_ROOT/source-dirty.out"
grep -Fq "source-change.txt" "$TMP_ROOT/source-dirty.out"
grep -Fq "summary: action needed" "$TMP_ROOT/source-dirty.out"

printf 'hygiene: ok\n'
