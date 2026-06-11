#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"

(cd "$REPO_ROOT" && tar --exclude .git -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari
rm -f tickets/open/*.md tickets/open/*.markdown tickets/proposed/*.md tickets/proposed/*.markdown tickets/closed/*.md tickets/closed/*.markdown
rm -f reports/*.md reports/*.markdown reports/planning/*.md reports/planning/*.markdown reports/human/*.md reports/human/*.markdown handoffs/*.md handoffs/*.markdown
rm -rf reports/evidence/*
git init -b main >/dev/null
git config user.email "prompt@example.invalid"
git config user.name "Prompt Test"

./bin/palari init >/dev/null

if ./bin/palari prompt long-run >"$TMP_ROOT/no-goal.out" 2>&1; then
	printf 'prompt: expected long-run without --goal to fail\n' >&2
	exit 1
fi
grep -Fq "prompt long-run requires --goal TEXT" "$TMP_ROOT/no-goal.out"

./bin/palari prompt next >"$TMP_ROOT/no-active.out"
grep -Fq "There are no active Palari tickets" "$TMP_ROOT/no-active.out"
grep -Fq "Do not commit, push, merge, deploy, or accept" "$TMP_ROOT/no-active.out"

./bin/palari ticket create PRM-0001 "Prompt sample" \
	--stream cli \
	--risk R1 \
	--allowed "src/**" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--verify "echo prompt-ok" \
	--review >/dev/null

./bin/palari prompt next >"$TMP_ROOT/next.out"
grep -Fq "You are working in" "$TMP_ROOT/next.out"
grep -Fq "Ticket: PRM-0001 - Prompt sample" "$TMP_ROOT/next.out"
grep -Fq "claim and isolate" "$TMP_ROOT/next.out"
grep -Fq "Do not self-accept" "$TMP_ROOT/next.out"

./bin/palari prompt ticket PRM-0001 >"$TMP_ROOT/ticket.out"
grep -Fq "Work on PRM-0001 only" "$TMP_ROOT/ticket.out"
grep -Fq "Allowed paths:" "$TMP_ROOT/ticket.out"
grep -Fq "src/**" "$TMP_ROOT/ticket.out"
grep -Fq "Forbidden paths:" "$TMP_ROOT/ticket.out"
grep -Fq "Verification commands:" "$TMP_ROOT/ticket.out"
grep -Fq "echo prompt-ok" "$TMP_ROOT/ticket.out"
grep -Fq "Move the ticket to review" "$TMP_ROOT/ticket.out"

./bin/palari prompt long-run --goal "Build a polished operator console" --ticket PRM-0001 >"$TMP_ROOT/long-run.out"
grep -Fq "Long-running goal:" "$TMP_ROOT/long-run.out"
grep -Fq "Build a polished operator console" "$TMP_ROOT/long-run.out"
grep -Fq "Do not stop after one small ticket" "$TMP_ROOT/long-run.out"
grep -Fq "Start with ticket: PRM-0001" "$TMP_ROOT/long-run.out"
grep -Fq "Product Manager" "$TMP_ROOT/long-run.out"
grep -Fq "UX/UI Lead" "$TMP_ROOT/long-run.out"
grep -Fq "Stopping rules:" "$TMP_ROOT/long-run.out"
grep -Fq "exact next Palari action" "$TMP_ROOT/long-run.out"

./bin/palari prompt help >"$TMP_ROOT/help.out"
grep -Fq "prompt next" "$TMP_ROOT/help.out"
grep -Fq "prompt ticket ID" "$TMP_ROOT/help.out"
grep -Fq "prompt long-run --goal TEXT" "$TMP_ROOT/help.out"

if ./bin/palari prompt unknown >"$TMP_ROOT/unknown.out" 2>&1; then
	printf 'prompt: expected unknown subcommand to fail\n' >&2
	exit 1
fi
grep -Fq "unknown prompt command" "$TMP_ROOT/unknown.out"

printf 'prompt: ok\n'
