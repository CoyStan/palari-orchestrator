#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

new_repo() {
	local name="$1"
	local work="$TMP_ROOT/$name"
	mkdir -p "$work"
	(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$work" && tar -xf -)
	cd "$work"
	chmod +x bin/palari scripts/palari tests/run-github-ci.sh
	rm -f tickets/open/*.md tickets/open/*.markdown tickets/proposed/*.md tickets/proposed/*.markdown tickets/closed/*.md tickets/closed/*.markdown
	rm -f reports/*.md reports/*.markdown reports/planning/*.md reports/planning/*.markdown reports/human/*.md reports/human/*.markdown handoffs/*.md handoffs/*.markdown
	rm -rf reports/evidence/*
	git init -b main >/dev/null
	git config user.email "github-ci@example.invalid"
	git config user.name "GitHub CI Test"
	./bin/palari init >/dev/null
	git add .
	git commit -m "baseline" >/dev/null
	printf '%s\n' "$work"
}

create_doc_ticket() {
	local ticket="$1"
	./bin/palari ticket create "$ticket" "GitHub CI $ticket" \
		--stream test \
		--risk R1 \
		--allowed "docs/$ticket.md" \
		--allowed "tickets/**" \
		--allowed "reports/**" \
		--verify "test -f docs/$ticket.md" >/dev/null
	mkdir -p docs
	printf '%s\n' "$ticket" >"docs/$ticket.md"
}

commit_case() {
	git add .
	git commit -m "$1" >/dev/null
}

run_no_ticket_case() {
	local work
	work="$(new_repo no-ticket)"
	cd "$work"
	if ./bin/palari github ci --base main >"$TMP_ROOT/no-ticket.out" 2>&1; then
		printf 'github-ci: expected no-ticket PR to fail closed\n' >&2
		exit 1
	fi
	grep -Fq "github ci could not find a Palari ticket" "$TMP_ROOT/no-ticket.out"
	grep -Fq "name the branch ticket/TICKET-ID" "$TMP_ROOT/no-ticket.out"
	grep -Fq "palari github ci --repo-only" "$TMP_ROOT/no-ticket.out"
	./bin/palari github ci --base main --repo-only >"$TMP_ROOT/repo-only.out"
	grep -Fq "ci: ok for repo" "$TMP_ROOT/repo-only.out"
}

run_env_case() {
	local work
	work="$(new_repo env-ticket)"
	cd "$work"
	git switch -c feature/env-ticket >/dev/null
	create_doc_ticket LAB-0301
	commit_case "env ticket"
	PALARI_TICKET_ID=LAB-0301 ./bin/palari github ci --base main >"$TMP_ROOT/env-ticket.out"
	grep -Fq "github ci: tickets: LAB-0301" "$TMP_ROOT/env-ticket.out"
	grep -Fq "ci: ok for LAB-0301" "$TMP_ROOT/env-ticket.out"
}

run_branch_case() {
	local work
	work="$(new_repo branch-ticket)"
	cd "$work"
	git switch -c feature/branch-ticket >/dev/null
	create_doc_ticket LAB-0302
	commit_case "branch ticket"
	GITHUB_HEAD_REF=ticket/LAB-0302 ./bin/palari github ci --base main >"$TMP_ROOT/branch-ticket.out"
	grep -Fq "github ci: tickets: LAB-0302" "$TMP_ROOT/branch-ticket.out"
	grep -Fq "ci: ok for LAB-0302" "$TMP_ROOT/branch-ticket.out"
}

run_changed_open_case() {
	local work
	work="$(new_repo changed-open)"
	cd "$work"
	git switch -c feature/changed-open >/dev/null
	create_doc_ticket LAB-0303
	commit_case "changed open ticket"
	./bin/palari github ci --base main >"$TMP_ROOT/changed-open.out"
	grep -Fq "github ci: tickets: LAB-0303" "$TMP_ROOT/changed-open.out"
	grep -Fq "ci: ok for LAB-0303" "$TMP_ROOT/changed-open.out"
}

run_changed_closed_case() {
	local work ticket_file
	work="$(new_repo changed-closed)"
	cd "$work"
	git switch -c feature/changed-closed >/dev/null
	create_doc_ticket LAB-0304
	ticket_file="$(find tickets/open -maxdepth 1 -name 'LAB-0304-*.md' | head -n 1)"
	sed -i 's/^status: open$/status: accepted/' "$ticket_file"
	mkdir -p tickets/closed
	mv "$ticket_file" tickets/closed/
	commit_case "changed closed ticket"
	./bin/palari github ci --base main >"$TMP_ROOT/changed-closed.out"
	grep -Fq "github ci: tickets: LAB-0304" "$TMP_ROOT/changed-closed.out"
	grep -Fq "ci: ok for LAB-0304" "$TMP_ROOT/changed-closed.out"
}

run_multi_ticket_case() {
	local work
	work="$(new_repo multi-ticket)"
	cd "$work"
	git switch -c feature/multi-ticket >/dev/null
	create_doc_ticket LAB-0305
	create_doc_ticket LAB-0306
	commit_case "multiple changed tickets"
	./bin/palari github ci --base main >"$TMP_ROOT/multi-ticket.out"
	grep -Fq "github ci: tickets: LAB-0305 LAB-0306" "$TMP_ROOT/multi-ticket.out"
	grep -Fq "ci: ok for LAB-0305+LAB-0306" "$TMP_ROOT/multi-ticket.out"
}

run_accepted_evidence_and_future_open_case() {
	local work ticket_file aggregate_log
	work="$(new_repo accepted-evidence)"
	cd "$work"
	git switch -c feature/accepted-evidence >/dev/null
	./bin/palari ticket create LAB-0307 "Accepted evidence reuse" \
		--stream test \
		--risk R1 \
		--allowed "docs/transient.md" \
		--allowed "tickets/**" \
		--allowed "reports/**" \
		--verify "test -f docs/transient.md" >/dev/null
	mkdir -p docs
	printf 'transient\n' >docs/transient.md
	./bin/palari ci LAB-0307 >/dev/null
	rm -f docs/transient.md
	ticket_file="$(find tickets/open -maxdepth 1 -name 'LAB-0307-*.md' | head -n 1)"
	sed -i 's/^status: open$/status: accepted/' "$ticket_file"
	mkdir -p tickets/closed
	mv "$ticket_file" tickets/closed/
	./bin/palari ticket create LAB-0308 "Future open ticket" \
		--stream test \
		--risk R1 \
		--allowed "docs/future.md" \
		--allowed "tickets/**" \
		--allowed "reports/**" \
		--verify "test -f docs/future.md" >/dev/null
	commit_case "accepted evidence and future open ticket"
	./bin/palari github ci --base main >"$TMP_ROOT/accepted-evidence.out"
	grep -Fq "github ci: tickets: LAB-0307" "$TMP_ROOT/accepted-evidence.out"
	if grep -Fq "LAB-0308" "$TMP_ROOT/accepted-evidence.out"; then
		printf 'github-ci: future open ticket should not run as completed work\n' >&2
		exit 1
	fi
	grep -Fq "ci: ok for LAB-0307" "$TMP_ROOT/accepted-evidence.out"
	aggregate_log="reports/evidence/LAB-0307/verification.log"
	grep -Fq "stored evidence LAB-0307" "$aggregate_log"
}

run_no_ticket_case
run_env_case
run_branch_case
run_changed_open_case
run_changed_closed_case
run_multi_ticket_case
run_accepted_evidence_and_future_open_case

printf 'github-ci: ok\n'
