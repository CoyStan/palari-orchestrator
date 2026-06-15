#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'human-governance: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-human-governance.sh
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* .palari humans/proposed/*.md humans/active/*.md humans/revoked/*.md

git init -b main >/dev/null
git config user.email "humans@example.invalid"
git config user.name "Humans Test"
git add .
git commit -m "humans baseline" >/dev/null

./bin/palari init >"$TMP_ROOT/init.out"
test -f humans/proposed/.gitkeep || fail "init should create humans/proposed"
test -f humans/active/.gitkeep || fail "init should create humans/active"
test -f humans/revoked/.gitkeep || fail "init should create humans/revoked"

./bin/palari human create HUMAN-ALICE Alice \
	--skill product_strategy:L5 \
	--skill analytics:L3 \
	--role product_governor \
	--capacity-hgl 60 \
	--authority-max-risk R5 \
	--may-approve-policy-changes \
	--constraint cannot_self_review_own_work >"$TMP_ROOT/create.out"

grep -Fq "human create: humans/proposed/HUMAN-ALICE-alice.md" "$TMP_ROOT/create.out" ||
	fail "human create path missing"
test -f humans/proposed/HUMAN-ALICE-alice.md || fail "proposed human profile missing"
grep -Fq "weekly_hgl_budget: 60" humans/proposed/HUMAN-ALICE-alice.md ||
	fail "human create should write weekly_hgl_budget"
grep -Fq "max_concurrent_r5: 1" humans/proposed/HUMAN-ALICE-alice.md ||
	fail "human create should write risk capacity fields"

./bin/palari human list >"$TMP_ROOT/list-proposed.out"
grep -Fq "proposed HUMAN-ALICE" "$TMP_ROOT/list-proposed.out" ||
	fail "human list missing proposed profile"

./bin/palari human show HUMAN-ALICE >"$TMP_ROOT/show.out"
grep -Fq "Human: HUMAN-ALICE - Alice" "$TMP_ROOT/show.out" ||
	fail "human show missing title"
grep -Fq "authority_max_risk: R5" "$TMP_ROOT/show.out" ||
	fail "human show missing risk"

./bin/palari human lint >"$TMP_ROOT/lint-proposed.out"
grep -Fq "human lint: ok" "$TMP_ROOT/lint-proposed.out" ||
	fail "human lint should pass for proposed profile"

./bin/palari human adopt HUMAN-ALICE --by founder >"$TMP_ROOT/adopt.out"
grep -Fq "human adopt: HUMAN-ALICE -> humans/active/HUMAN-ALICE-alice.md" "$TMP_ROOT/adopt.out" ||
	fail "human adopt output missing"
test -f humans/active/HUMAN-ALICE-alice.md || fail "active human profile missing"
grep -Fq "status: active" humans/active/HUMAN-ALICE-alice.md ||
	fail "adopt should set status active"

./bin/palari human lint HUMAN-ALICE >"$TMP_ROOT/lint-one.out"
grep -Fq "human lint: ok for HUMAN-ALICE" "$TMP_ROOT/lint-one.out" ||
	fail "human lint one should pass"

./bin/palari human revoke HUMAN-ALICE --by founder >"$TMP_ROOT/revoke.out"
grep -Fq "human revoke: HUMAN-ALICE -> humans/revoked/HUMAN-ALICE-alice.md" "$TMP_ROOT/revoke.out" ||
	fail "human revoke output missing"
test -f humans/revoked/HUMAN-ALICE-alice.md || fail "revoked human profile missing"
grep -Fq "status: revoked" humans/revoked/HUMAN-ALICE-alice.md ||
	fail "revoke should set status revoked"

if ./bin/palari human create HUMAN-BOB Bob \
	--skill product_strategy:6 \
	--role product_governor \
	--capacity-hgl 10 >"$TMP_ROOT/bad-skill-create.out" 2>&1; then
	fail "invalid skill level should fail create"
fi
grep -Fq "invalid skill level" "$TMP_ROOT/bad-skill-create.out" ||
	fail "invalid skill diagnostic missing"

cat >humans/active/HUMAN-CAROL-carol.md <<'DOC'
---
id: HUMAN-CAROL
name: Carol
status: active
roles:
  - security_governor
skills:
  - security_engineering:L5
authority_max_risk: R5
may_approve_policy_changes: false
capacity_weekly_hgl: 20
capacity_open_r3: 2
capacity_open_r4: 1
capacity_open_r5: 1
constraints:
---

# HUMAN-CAROL Carol
DOC

if ./bin/palari human lint HUMAN-CAROL >"$TMP_ROOT/r5-no-policy.out" 2>&1; then
	fail "R5 authority without policy approval flag should fail"
fi
grep -Fq "R5 authority requires may_approve_policy_changes: true" "$TMP_ROOT/r5-no-policy.out" ||
	fail "R5 policy flag diagnostic missing"
rm -f humans/active/HUMAN-CAROL-carol.md

cat >humans/active/HUMAN-DANA-dana.md <<'DOC'
---
id: HUMAN-DANA
name: Dana
status: active
roles:
  - product_governor
skills:
  - product_strategy:L4
authority_max_risk: R4
may_approve_policy_changes: false
capacity_weekly_hgl: many
capacity_open_r3: 2
capacity_open_r4: 1
capacity_open_r5: 0
constraints:
---

# HUMAN-DANA Dana
DOC

if ./bin/palari human lint HUMAN-DANA >"$TMP_ROOT/bad-capacity.out" 2>&1; then
	fail "non-integer capacity should fail"
fi
grep -Fq "capacity_weekly_hgl must be a non-negative integer" "$TMP_ROOT/bad-capacity.out" ||
	fail "capacity diagnostic missing"
rm -f humans/active/HUMAN-DANA-dana.md

cat >humans/active/HUMAN-ERIN-erin.md <<'DOC'
---
id: HUMAN-ERIN
name: Erin
status: active
roles:
  - product_governor
skills:
  - product_strategy:L4
authority_max_risk: R4
may_approve_policy_changes: false
weekly_hgl_budget: 10
current_weekly_hgl: 11
max_concurrent_r3: 2
current_open_r3: 0
max_concurrent_r4: 1
current_open_r4: 0
max_concurrent_r5: 0
current_open_r5: 0
constraints:
---

# HUMAN-ERIN Erin
DOC

if ./bin/palari human lint HUMAN-ERIN >"$TMP_ROOT/over-weekly.out" 2>&1; then
	fail "current weekly HGL over budget should fail"
fi
grep -Fq "current_weekly_hgl exceeds weekly_hgl_budget" "$TMP_ROOT/over-weekly.out" ||
	fail "weekly capacity diagnostic missing"
rm -f humans/active/HUMAN-ERIN-erin.md

cat >humans/active/HUMAN-FRANK-frank.md <<'DOC'
---
id: HUMAN-FRANK
name: Frank
status: active
roles:
  - privacy_governor
skills:
  - privacy:L5
authority_max_risk: R5
may_approve_policy_changes: true
weekly_hgl_budget: 40
current_weekly_hgl: 0
max_concurrent_r3: 2
current_open_r3: 0
max_concurrent_r4: 1
current_open_r4: 0
max_concurrent_r5: 1
current_open_r5: 2
constraints:
---

# HUMAN-FRANK Frank
DOC

if ./bin/palari human lint HUMAN-FRANK >"$TMP_ROOT/over-risk.out" 2>&1; then
	fail "current open risk count over max should fail"
fi
grep -Fq "current_open_r5 exceeds max_concurrent_r5" "$TMP_ROOT/over-risk.out" ||
	fail "risk capacity diagnostic missing"
rm -f humans/active/HUMAN-FRANK-frank.md

./bin/palari human lint >"$TMP_ROOT/final-lint.out"
grep -Fq "human lint: ok" "$TMP_ROOT/final-lint.out" ||
	fail "final human lint should pass"

printf 'human-governance: ok\n'
