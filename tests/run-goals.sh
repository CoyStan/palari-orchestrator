#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'goals: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* goals decisions
mkdir -p goals/active goals/proposed goals/closed decisions/open decisions/decided

git init -b main >/dev/null
git config user.email "goals@example.invalid"
git config user.name "Goals Test"
git add .
git commit -m "goals baseline" >/dev/null

# Create and inspect a goal.
./bin/palari goal create GOAL-0001 "Ship the demo" \
	--owner founder --success "Demo command passes" --due 2099-01-01 >"$TMP_ROOT/create.out"
grep -Fq "goal create: goals/active/GOAL-0001-ship-the-demo.md" "$TMP_ROOT/create.out" ||
	fail "goal create did not write the active goal file"

./bin/palari goal list >"$TMP_ROOT/list.out"
grep -Fq "GOAL-0001" "$TMP_ROOT/list.out" || fail "goal list missing GOAL-0001"

# Goal id validation and duplicates fail.
if ./bin/palari goal create BAD-1 "x" --success "y" >/dev/null 2>&1; then
	fail "invalid goal id should be rejected"
fi
if ./bin/palari goal create GOAL-0001 "Duplicate" --success "y" >/dev/null 2>&1; then
	fail "duplicate goal id should be rejected"
fi

# Goal without success criteria fails.
if ./bin/palari goal create GOAL-0002 "No criteria" >/dev/null 2>&1; then
	fail "goal without --success should be rejected"
fi

# Ticket linking: valid goal links, unknown goal rejected.
./bin/palari ticket create GLT-0001 "Linked work" --goal GOAL-0001 \
	--allowed "README.md" --verify "test -f README.md" >/dev/null
grep -Fq "serves_goal: GOAL-0001" tickets/open/GLT-0001-*.md ||
	fail "ticket frontmatter missing serves_goal"
if ./bin/palari ticket create GLT-0002 "Bad link" --goal GOAL-9999 \
	--allowed "README.md" --verify "true" >/dev/null 2>&1; then
	fail "ticket create should reject an unknown goal"
fi

# goal show lists the serving ticket.
./bin/palari goal show GOAL-0001 >"$TMP_ROOT/show.out"
grep -Fq "GLT-0001" "$TMP_ROOT/show.out" || fail "goal show missing serving ticket"

# goal lint passes, then catches an orphan reference.
./bin/palari goal lint >/dev/null || fail "goal lint should pass"
sed -i 's/^serves_goal: GOAL-0001$/serves_goal: GOAL-7777/' tickets/open/GLT-0001-*.md
if ./bin/palari goal lint >/dev/null 2>&1; then
	fail "goal lint should fail on an orphan serves_goal reference"
fi
sed -i 's/^serves_goal: GOAL-7777$/serves_goal: GOAL-0001/' tickets/open/GLT-0001-*.md

# Proposed goal requires human adoption; achieve requires --by.
./bin/palari goal create GOAL-0003 "Future bet" --success "Signed off" --proposed >/dev/null
[[ -f goals/proposed/GOAL-0003-future-bet.md ]] || fail "proposed goal not in goals/proposed"
if ./bin/palari ticket create GLT-0003 "Premature" --goal GOAL-0003 \
	--allowed "README.md" --verify "true" >/dev/null 2>&1; then
	fail "tickets must not link to non-active goals"
fi
./bin/palari goal adopt GOAL-0003 --by founder >/dev/null
[[ -f goals/active/GOAL-0003-future-bet.md ]] || fail "adopted goal not in goals/active"

if ./bin/palari goal achieve GOAL-0003 >/dev/null 2>&1; then
	fail "goal achieve without --by should be rejected"
fi
./bin/palari goal achieve GOAL-0003 --by founder >/dev/null
[[ -f goals/closed/GOAL-0003-future-bet.md ]] || fail "achieved goal not in goals/closed"
grep -Fq "closed_as: achieved" goals/closed/GOAL-0003-future-bet.md ||
	fail "achieved goal missing closed_as"

# Strict mode refuses unlinked tickets.
sed -i 's/^require_serves_goal: warn$/require_serves_goal: strict/' palari.config.yaml
if ./bin/palari ticket create GLT-0004 "Unlinked" \
	--allowed "README.md" --verify "true" >/dev/null 2>&1; then
	fail "strict mode should refuse a ticket without --goal"
fi

printf 'goals: ok\n'
