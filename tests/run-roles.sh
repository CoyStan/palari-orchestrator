#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() {
	printf 'roles: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git -cf - .) | (cd "$WORK" && tar -xf -)
cd "$WORK"
chmod +x bin/palari scripts/palari

rm -f tickets/open/*.md tickets/open/*.markdown tickets/proposed/*.md tickets/proposed/*.markdown tickets/closed/*.md tickets/closed/*.markdown
rm -f reports/*.md reports/*.markdown reports/planning/*.md reports/planning/*.markdown reports/human/*.md reports/human/*.markdown handoffs/*.md handoffs/*.markdown
rm -rf reports/evidence/*

git init -b main >/dev/null
git config user.email "roles@example.invalid"
git config user.name "Roles Test"
git add .
git commit -m "fixture" >/dev/null

./bin/palari role lint >"$TMP_ROOT/role-lint.out"
grep -Fq "role lint: ok" "$TMP_ROOT/role-lint.out"
./bin/palari role list >"$TMP_ROOT/role-list.out"
grep -Fq "ROLE-ENGINEERING-LEAD" "$TMP_ROOT/role-list.out"
./bin/palari role graph >"$TMP_ROOT/role-graph.out"
grep -Fq "ROLE-ROOT -> ROLE-ENGINEERING-LEAD" "$TMP_ROOT/role-graph.out"
./bin/palari role packet ROLE-ENGINEERING-LEAD >"$TMP_ROOT/role-packet.out"
grep -Fq "Agents execute roles; they do not create authority." "$TMP_ROOT/role-packet.out"

cp roles/active/ROLE-SPECIALIST.md roles/active/ROLE-SPECIALIST-copy.md
if ./bin/palari role lint >"$TMP_ROOT/duplicate-role.out" 2>&1; then
	fail "duplicate role id should fail lint"
fi
grep -Fq "duplicate role id: ROLE-SPECIALIST" "$TMP_ROOT/duplicate-role.out"
rm -f roles/active/ROLE-SPECIALIST-copy.md

cp roles/active/ROLE-ENGINEERING-LEAD.md roles/active/ROLE-UNKNOWN-DELEGATE.md
perl -0pi -e 's/id: ROLE-ENGINEERING-LEAD/id: ROLE-UNKNOWN-DELEGATE/; s/title: Engineering Lead/title: Unknown Delegate/; s/  - ROLE-SPECIALIST\n  - ROLE-REVIEWER/  - ROLE-NOPE/' roles/active/ROLE-UNKNOWN-DELEGATE.md
if ./bin/palari role lint >"$TMP_ROOT/unknown-delegate.out" 2>&1; then
	fail "unknown delegate should fail lint"
fi
grep -Fq "unknown delegate: ROLE-NOPE" "$TMP_ROOT/unknown-delegate.out"
rm -f roles/active/ROLE-UNKNOWN-DELEGATE.md

cp roles/active/ROLE-SPECIALIST.md roles/active/ROLE-CYCLE-A.md
cp roles/active/ROLE-REVIEWER.md roles/active/ROLE-CYCLE-B.md
perl -0pi -e 's/id: ROLE-SPECIALIST/id: ROLE-CYCLE-A/; s/title: Specialist/title: Cycle A/; s/parent_role: ROLE-ENGINEERING-LEAD/parent_role: ROLE-CYCLE-B/' roles/active/ROLE-CYCLE-A.md
perl -0pi -e 's/id: ROLE-REVIEWER/id: ROLE-CYCLE-B/; s/title: Reviewer/title: Cycle B/; s/parent_role: ROLE-ENGINEERING-LEAD/parent_role: ROLE-CYCLE-A/' roles/active/ROLE-CYCLE-B.md
if ./bin/palari role lint >"$TMP_ROOT/cycle.out" 2>&1; then
	fail "delegation cycle should fail lint"
fi
grep -Fq "delegation cycle includes" "$TMP_ROOT/cycle.out"
rm -f roles/active/ROLE-CYCLE-A.md roles/active/ROLE-CYCLE-B.md

cp roles/active/ROLE-SPECIALIST.md roles/active/ROLE-WIDE-CHILD.md
perl -0pi -e 's/id: ROLE-SPECIALIST/id: ROLE-WIDE-CHILD/; s/title: Specialist/title: Wide Child/; s/allowed_paths:\n(?:  - .+\n)+forbidden_paths:/allowed_paths:\n  - adapters\/**\nforbidden_paths:/s' roles/active/ROLE-WIDE-CHILD.md
if ./bin/palari role lint >"$TMP_ROOT/wide-child.out" 2>&1; then
	fail "child wider than parent should fail lint"
fi
grep -Fq "authority check failed: reject:path outside parent authority: adapters/**" "$TMP_ROOT/wide-child.out"
rm -f roles/active/ROLE-WIDE-CHILD.md

cp roles/active/ROLE-SPECIALIST.md roles/active/ROLE-HIGH-RISK.md
perl -0pi -e 's/id: ROLE-SPECIALIST/id: ROLE-HIGH-RISK/; s/title: Specialist/title: High Risk/; s/max_risk: R1/max_risk: R3/' roles/active/ROLE-HIGH-RISK.md
if ./bin/palari role lint >"$TMP_ROOT/high-risk-role.out" 2>&1; then
	fail "child role above parent risk should fail lint"
fi
grep -Fq "authority check failed: escalate:child risk exceeds parent max_risk" "$TMP_ROOT/high-risk-role.out"
rm -f roles/active/ROLE-HIGH-RISK.md

cp roles/active/ROLE-SPECIALIST.md roles/active/ROLE-MISSING-AUTH.md
perl -0pi -e 's/id: ROLE-SPECIALIST/id: ROLE-MISSING-AUTH/; s/title: Specialist/title: Missing Authority/; s/accepted_by: founder/accepted_by:/' roles/active/ROLE-MISSING-AUTH.md
if ./bin/palari role lint >"$TMP_ROOT/missing-auth.out" 2>&1; then
	fail "active role missing acceptance provenance should fail lint"
fi
grep -Fq "active role missing accepted_by" "$TMP_ROOT/missing-auth.out"
rm -f roles/active/ROLE-MISSING-AUTH.md

cp roles/active/ROLE-ENGINEERING-LEAD.md roles/active/ROLE-AUTHORITY-TESTER.md
perl -0pi -e 's/id: ROLE-ENGINEERING-LEAD/id: ROLE-AUTHORITY-TESTER/; s/title: Engineering Lead/title: Authority Tester/; s/allowed_paths:\n(?:  - .+\n)+forbidden_paths:/allowed_paths:\n  - roles\/active\/**\n  - lib\/palari\/**\n  - docs\/**\n  - tickets\/**\n  - reports\/**\nforbidden_paths:/s' roles/active/ROLE-AUTHORITY-TESTER.md
./bin/palari role lint >"$TMP_ROOT/authority-tester-lint.out"

./bin/palari ticket create POS-0300 "Role governed docs" \
	--stream docs \
	--risk R1 \
	--allowed "docs/**" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--verify "manual role check" \
	--by-role ROLE-ENGINEERING-LEAD \
	--delegate-to-role ROLE-SPECIALIST >"$TMP_ROOT/good-ticket.out"
grep -Fq "ticket create:" "$TMP_ROOT/good-ticket.out"
grep -Fq "created_by_role: ROLE-ENGINEERING-LEAD" tickets/open/POS-0300-role-governed-docs.md
grep -Fq "delegated_to_role: ROLE-SPECIALIST" tickets/open/POS-0300-role-governed-docs.md
./bin/palari lint POS-0300 >"$TMP_ROOT/good-lint.out"
git add roles/active/ROLE-AUTHORITY-TESTER.md tickets/open/POS-0300-role-governed-docs.md
git commit -m "add role governed ticket" >/dev/null
./bin/palari worktree POS-0300 >"$TMP_ROOT/worktree.out"
./bin/palari packet POS-0300 specialist >"$TMP_ROOT/packet.out"
grep -Fq "Created by role: ROLE-ENGINEERING-LEAD" "$TMP_ROOT/packet.out"
grep -Fq "Delegated to role: ROLE-SPECIALIST" "$TMP_ROOT/packet.out"
grep -Fq "Parent/delegator authority: ROLE-ENGINEERING-LEAD may only grant authority it already holds." "$TMP_ROOT/packet.out"
grep -Fq "Do not expand authority" "$TMP_ROOT/packet.out"

./bin/palari ticket create POS-0308 "No role flow" \
	--stream docs \
	--risk R1 \
	--allowed "docs/**" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--verify "manual no-role check" >"$TMP_ROOT/no-role.out"
grep -Fq "ticket create:" "$TMP_ROOT/no-role.out"
if grep -Fq "created_by_role:" tickets/open/POS-0308-no-role-flow.md; then
	fail "no-role ticket should not record role metadata"
fi

if ./bin/palari ticket create POS-0309 "Role active path" \
	--stream governance \
	--risk R1 \
	--allowed "roles/active/**" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--verify "manual authority path check" \
	--by-role ROLE-AUTHORITY-TESTER >"$TMP_ROOT/active-path.out" 2>&1; then
	fail "ordinary role ticket touching roles/active should fail"
fi
grep -Fq "ticket create rejected by role authority: ordinary role cannot create ticket touching authority path: roles/active/**" "$TMP_ROOT/active-path.out"
test ! -e tickets/open/POS-0309-role-active-path.md

if ./bin/palari ticket create POS-0310 "Role lib path" \
	--stream governance \
	--risk R1 \
	--allowed "lib/palari/**" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--verify "manual authority path check" \
	--by-role ROLE-AUTHORITY-TESTER >"$TMP_ROOT/lib-path.out" 2>&1; then
	fail "ordinary role ticket touching lib/palari should fail"
fi
grep -Fq "ticket create rejected by role authority: ordinary role cannot create ticket touching authority path: lib/palari/**" "$TMP_ROOT/lib-path.out"
test ! -e tickets/open/POS-0310-role-lib-path.md

if ./bin/palari ticket create POS-0301 "Role outside path" \
	--stream docs \
	--risk R1 \
	--allowed "adapters/**" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--verify "manual role check" \
	--by-role ROLE-ENGINEERING-LEAD >"$TMP_ROOT/outside.out" 2>&1; then
	fail "outside path role ticket should fail"
fi
grep -Fq "ticket create rejected by role authority: path outside parent authority: adapters/**" "$TMP_ROOT/outside.out"
test ! -e tickets/open/POS-0301-role-outside-path.md

if ./bin/palari ticket create POS-0302 "Role high risk" \
	--stream docs \
	--risk R3 \
	--allowed "docs/**" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--verify "manual role check" \
	--by-role ROLE-ENGINEERING-LEAD >"$TMP_ROOT/high-risk.out" 2>&1; then
	fail "high risk role ticket should escalate"
fi
grep -Fq "ticket create escalated: child risk exceeds parent max_risk" "$TMP_ROOT/high-risk.out"
test -f reports/planning/POS-0302-role-escalation.md
test ! -e tickets/open/POS-0302-role-high-risk.md

if ./bin/palari ticket create POS-0303 "Role bad delegate" \
	--stream docs \
	--risk R1 \
	--allowed "docs/**" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--verify "manual role check" \
	--by-role ROLE-ENGINEERING-LEAD \
	--delegate-to-role ROLE-ROOT >"$TMP_ROOT/bad-delegate.out" 2>&1; then
	fail "bad delegate role ticket should fail"
fi
grep -Fq "ticket create rejected by role authority: ticket delegates outside parent authority: ROLE-ROOT" "$TMP_ROOT/bad-delegate.out"

if ./bin/palari ticket create POS-0304 "Role unknown glob" \
	--stream docs \
	--risk R1 \
	--allowed "docs/*/deep/**" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--verify "manual role check" \
	--by-role ROLE-ENGINEERING-LEAD >"$TMP_ROOT/unknown-glob.out" 2>&1; then
	fail "unknown glob role ticket should escalate"
fi
grep -Fq "ticket create escalated: path containment cannot be proven: docs/*/deep/**" "$TMP_ROOT/unknown-glob.out"
test -f reports/planning/POS-0304-role-escalation.md
test ! -e tickets/open/POS-0304-role-unknown-glob.md

if ./bin/palari ticket create POS-0305 "Delegate without issuer" \
	--stream docs \
	--risk R1 \
	--allowed "docs/**" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--verify "manual role check" \
	--delegate-to-role ROLE-SPECIALIST >"$TMP_ROOT/delegate-no-issuer.out" 2>&1; then
	fail "delegate-to-role without by-role should fail"
fi
grep -Fq -- "--delegate-to-role requires --by-role" "$TMP_ROOT/delegate-no-issuer.out"

./bin/palari role propose ROLE-DOCS-LEAD "Docs Lead" --by-role ROLE-ROOT >"$TMP_ROOT/propose.out"
grep -Fq "role propose: roles/proposed/ROLE-DOCS-LEAD-docs-lead.md" "$TMP_ROOT/propose.out"
perl -0pi -e 's/allowed_paths:\n/allowed_paths:\n  - docs\/**\n  - tickets\/**\n  - reports\/**\n/' roles/proposed/ROLE-DOCS-LEAD-docs-lead.md
perl -0pi -e 's/may_create_tickets: false/may_create_tickets: true/' roles/proposed/ROLE-DOCS-LEAD-docs-lead.md
if ./bin/palari ticket create POS-0311 "Proposed role cannot act" \
	--stream docs \
	--risk R1 \
	--allowed "docs/**" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--verify "manual proposed role check" \
	--by-role ROLE-DOCS-LEAD >"$TMP_ROOT/proposed-role-ticket.out" 2>&1; then
	fail "proposed role should not create tickets"
fi
grep -Fq "active role not found: ROLE-DOCS-LEAD" "$TMP_ROOT/proposed-role-ticket.out"
./bin/palari role adopt ROLE-DOCS-LEAD --by founder >"$TMP_ROOT/adopt.out"
grep -Fq "role adopt: roles/active/ROLE-DOCS-LEAD-docs-lead.md" "$TMP_ROOT/adopt.out"
test -f roles/active/ROLE-DOCS-LEAD-docs-lead.md
./bin/palari role revoke ROLE-DOCS-LEAD --by founder >"$TMP_ROOT/revoke.out"
grep -Fq "role revoke: roles/revoked/ROLE-DOCS-LEAD-docs-lead.md" "$TMP_ROOT/revoke.out"
test -f roles/revoked/ROLE-DOCS-LEAD-docs-lead.md
if ./bin/palari ticket create POS-0312 "Revoked role cannot act" \
	--stream docs \
	--risk R1 \
	--allowed "docs/**" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--verify "manual revoked role check" \
	--by-role ROLE-DOCS-LEAD >"$TMP_ROOT/revoked-role-ticket.out" 2>&1; then
	fail "revoked role should not create tickets"
fi
grep -Fq "active role not found: ROLE-DOCS-LEAD" "$TMP_ROOT/revoked-role-ticket.out"

./bin/palari role lint >"$TMP_ROOT/final-role-lint.out"
grep -Fq "role lint: ok" "$TMP_ROOT/final-role-lint.out"

printf 'roles: ok\n'
