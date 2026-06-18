#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"

(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari
rm -f tickets/open/*.md tickets/open/*.markdown tickets/proposed/*.md tickets/proposed/*.markdown tickets/closed/*.md tickets/closed/*.markdown
rm -f reports/*.md reports/*.markdown reports/planning/*.md reports/planning/*.markdown reports/human/*.md reports/human/*.markdown handoffs/*.md handoffs/*.markdown
rm -rf reports/evidence/*

git init -b main >/dev/null
git config user.email "evidence-refresh@example.invalid"
git config user.name "Evidence Refresh Test"

./bin/palari init --ci --hooks >/dev/null
git add .
git commit -m "initial evidence refresh fixture" >/dev/null

create_ticket() {
	local ticket="$1"
	local title="$2"
	./bin/palari ticket create "$ticket" "$title" \
		--stream process \
		--risk R1 \
		--allowed "docs/evidence-refresh/$ticket.md" \
		--allowed "tickets/open/$ticket-*" \
		--allowed "tickets/closed/$ticket-*" \
		--allowed "reports/$ticket-*" \
		--allowed "reports/human/$ticket-*" \
		--allowed "reports/evidence/$ticket/**" \
		--verify "test -f docs/evidence-refresh/$ticket.md" >/dev/null
	git add "tickets/open/$ticket-"*.md
	git commit -m "route $ticket" >/dev/null
}

prepare_worktree() {
	local ticket="$1"
	./bin/palari worktree "$ticket" >"$TMP_ROOT/$ticket-worktree.out"
	awk -F': cd ' '/^Worker cd:/ { print $2 }' "$TMP_ROOT/$ticket-worktree.out"
}

add_report() {
	local ticket="$1"
	cat >"reports/$ticket-technical-report.md" <<DOC
# $ticket Technical Report

## Files Changed

- \`docs/evidence-refresh/$ticket.md\`

## Verification

- \`./bin/palari evidence refresh $ticket --base main\`

## CI Evidence

- \`reports/evidence/$ticket/manifest.json\`

## Risks / Follow-Ups

- Test fixture only.
DOC
}

# Bookkeeping-only commits after evidence do not make acceptance stale.
create_ticket ERF-0001 "Evidence refresh bookkeeping"
ERF1_WORKTREE="$(prepare_worktree ERF-0001)"
cd "$ERF1_WORKTREE"
./bin/palari ticket claim ERF-0001 evidence-tester --allow-overlap >/dev/null
mkdir -p docs/evidence-refresh
printf 'bookkeeping evidence fixture\n' >docs/evidence-refresh/ERF-0001.md
git add docs/evidence-refresh/ERF-0001.md tickets/open/ERF-0001-*.md
git commit -m "implement ERF-0001" >/dev/null

./bin/palari evidence refresh ERF-0001 --base main >"$TMP_ROOT/refresh-0001.out"
grep -Fq "evidence refresh: ok for ERF-0001" "$TMP_ROOT/refresh-0001.out"
grep -Fq "human acceptance remains separate:" "$TMP_ROOT/refresh-0001.out"
git add reports/evidence/ERF-0001
git commit -m "ERF-0001: refresh CI evidence" >/dev/null

add_report ERF-0001
git add reports/ERF-0001-technical-report.md
git commit -m "record ERF-0001 report" >/dev/null
./bin/palari ticket ready ERF-0001 >/dev/null
git add tickets/open/ERF-0001-*.md
git commit -m "move ERF-0001 to review" >/dev/null

./bin/palari evidence score ERF-0001 --strict >"$TMP_ROOT/score-0001.out"
grep -Fq "manifest integrity and freshness" "$TMP_ROOT/score-0001.out"
./bin/palari accept ERF-0001 --by reviewer >"$TMP_ROOT/accept-0001.out"
grep -Fq "accept: ERF-0001 accepted by reviewer" "$TMP_ROOT/accept-0001.out"

# Source commits after evidence are not bookkeeping and must fail acceptance.
cd "$WORK"
create_ticket ERF-0002 "Evidence refresh source drift"
ERF2_WORKTREE="$(prepare_worktree ERF-0002)"
cd "$ERF2_WORKTREE"
./bin/palari ticket claim ERF-0002 evidence-tester --allow-overlap >/dev/null
mkdir -p docs/evidence-refresh
printf 'source drift fixture\n' >docs/evidence-refresh/ERF-0002.md
git add docs/evidence-refresh/ERF-0002.md tickets/open/ERF-0002-*.md
git commit -m "implement ERF-0002" >/dev/null
./bin/palari evidence refresh ERF-0002 --base main >/dev/null
git add reports/evidence/ERF-0002
git commit -m "ERF-0002: refresh CI evidence" >/dev/null
printf 'source drift after evidence\n' >>docs/evidence-refresh/ERF-0002.md
git add docs/evidence-refresh/ERF-0002.md
git commit -m "change source after evidence" >/dev/null
add_report ERF-0002
git add reports/ERF-0002-technical-report.md
git commit -m "record ERF-0002 report" >/dev/null
./bin/palari ticket ready ERF-0002 >/dev/null
git add tickets/open/ERF-0002-*.md
git commit -m "move ERF-0002 to review" >/dev/null
if ./bin/palari accept ERF-0002 --by reviewer >"$TMP_ROOT/accept-0002.out" 2>&1; then
	printf 'evidence-refresh: expected source drift acceptance to fail\n' >&2
	exit 1
fi
grep -Fq "non-bookkeeping changes exist after evidence" "$TMP_ROOT/accept-0002.out"
grep -Fq "first non-bookkeeping path: docs/evidence-refresh/ERF-0002.md" "$TMP_ROOT/accept-0002.out"

# Dirty worktrees fail closed before evidence is rewritten.
cd "$WORK"
create_ticket ERF-0003 "Evidence refresh dirty source"
ERF3_WORKTREE="$(prepare_worktree ERF-0003)"
cd "$ERF3_WORKTREE"
./bin/palari ticket claim ERF-0003 evidence-tester --allow-overlap >/dev/null
mkdir -p docs/evidence-refresh
printf 'dirty source fixture\n' >docs/evidence-refresh/ERF-0003.md
git add docs/evidence-refresh/ERF-0003.md tickets/open/ERF-0003-*.md
git commit -m "implement ERF-0003" >/dev/null
printf 'uncommitted source drift\n' >>docs/evidence-refresh/ERF-0003.md
if ./bin/palari evidence refresh ERF-0003 --base main >"$TMP_ROOT/refresh-0003.out" 2>&1; then
	printf 'evidence-refresh: expected dirty worktree refresh to fail\n' >&2
	exit 1
fi
grep -Fq "refusing to rewrite evidence for ERF-0003 from a dirty worktree" "$TMP_ROOT/refresh-0003.out"

# Invalid existing manifests are not silently overwritten as if they were only stale by head_sha.
cd "$WORK"
create_ticket ERF-0004 "Evidence refresh invalid manifest"
ERF4_WORKTREE="$(prepare_worktree ERF-0004)"
cd "$ERF4_WORKTREE"
./bin/palari ticket claim ERF-0004 evidence-tester --allow-overlap >/dev/null
mkdir -p docs/evidence-refresh
printf 'invalid manifest fixture\n' >docs/evidence-refresh/ERF-0004.md
git add docs/evidence-refresh/ERF-0004.md tickets/open/ERF-0004-*.md
git commit -m "implement ERF-0004" >/dev/null
./bin/palari evidence refresh ERF-0004 --base main >/dev/null
python3 - <<'PY'
import json
from pathlib import Path

path = Path("reports/evidence/ERF-0004/manifest.json")
data = json.loads(path.read_text(encoding="utf-8"))
data["status"] = "failed"
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
git add reports/evidence/ERF-0004
git commit -m "corrupt ERF-0004 evidence" >/dev/null
if ./bin/palari evidence refresh ERF-0004 --base main >"$TMP_ROOT/refresh-0004.out" 2>&1; then
	printf 'evidence-refresh: expected invalid existing evidence to fail\n' >&2
	exit 1
fi
grep -Fq "existing evidence for ERF-0004 is invalid before refresh" "$TMP_ROOT/refresh-0004.out"
grep -Fq "not a head_sha-only stale evidence state" "$TMP_ROOT/refresh-0004.out"

printf 'evidence-refresh: ok\n'
