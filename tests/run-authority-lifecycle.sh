#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() {
	printf 'authority-lifecycle: %s\n' "$*" >&2
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
git config user.email "authority@example.invalid"
git config user.name "Authority Test"
git add .
git commit -m "fixture" >/dev/null

./bin/palari authority >"$TMP_ROOT/authority.out"
grep -Fq "profile: team-safe" "$TMP_ROOT/authority.out"
grep -Fq "agent_can_merge_main: false" "$TMP_ROOT/authority.out"
grep -Fq "agent_can_accept: false" "$TMP_ROOT/authority.out"
./bin/palari authority check commit >"$TMP_ROOT/commit-check.out"
if ./bin/palari authority check merge-main >"$TMP_ROOT/merge-check.out" 2>&1; then
	fail "team-safe should refuse merge-main"
fi
grep -Fq "authority: refused for merge-main under team-safe" "$TMP_ROOT/merge-check.out"

perl -0pi -e 's/authority_profile: team-safe/authority_profile: solo-founder/' palari.config.yaml
./bin/palari authority >"$TMP_ROOT/solo.out"
grep -Fq "profile: solo-founder" "$TMP_ROOT/solo.out"
./bin/palari authority check merge-main >"$TMP_ROOT/solo-merge.out"
if ./bin/palari authority check accept >"$TMP_ROOT/solo-accept.out" 2>&1; then
	fail "solo-founder accept should require explicit user instruction"
fi
grep -Fq "requires --user-explicit" "$TMP_ROOT/solo-accept.out"
./bin/palari authority check accept --user-explicit >"$TMP_ROOT/solo-explicit.out"
grep -Fq "explicit user instruction" "$TMP_ROOT/solo-explicit.out"

perl -0pi -e 's/authority_profile: solo-founder/authority_profile: strict/' palari.config.yaml
if ./bin/palari authority check commit >"$TMP_ROOT/strict-commit.out" 2>&1; then
	fail "strict should refuse commit"
fi
grep -Fq "authority: refused for commit under strict" "$TMP_ROOT/strict-commit.out"
perl -0pi -e 's/authority_profile: strict/authority_profile: team-safe/' palari.config.yaml

./bin/palari ticket create POS-0200 "Lifecycle sample" \
	--stream docs \
	--risk R1 \
	--allowed "docs/**" \
	--allowed "tickets/**" \
	--allowed "reports/**" \
	--verify "manual lifecycle check" >/dev/null

./bin/palari status --next >"$TMP_ROOT/status-open.out"
grep -Fq "Next required action" "$TMP_ROOT/status-open.out"
grep -Fq "POS-0200 [open]" "$TMP_ROOT/status-open.out"
grep -Fq "palari ticket claim POS-0200" "$TMP_ROOT/status-open.out"

./bin/palari ticket claim POS-0200 tester >/dev/null
./bin/palari ticket audit >"$TMP_ROOT/audit-claimed.out"
grep -Fq "POS-0200 [claimed]" "$TMP_ROOT/audit-claimed.out"
grep -Fq "palari ci POS-0200 --base main" "$TMP_ROOT/audit-claimed.out"

./bin/palari ticket ready POS-0200 >/dev/null
./bin/palari doctor lifecycle >"$TMP_ROOT/audit-review.out"
grep -Fq "POS-0200 [in-review]" "$TMP_ROOT/audit-review.out"
grep -Fq "create evidence: palari ci POS-0200 --base main" "$TMP_ROOT/audit-review.out"

./bin/palari snapshot --json >"$TMP_ROOT/snapshot.out"
grep -Fq '"authority_profile":"team-safe"' "$TMP_ROOT/snapshot.out"
grep -Fq '"agent_can_merge_main":"false"' "$TMP_ROOT/snapshot.out"
grep -Fq '"status_next":"./bin/palari status --next"' "$TMP_ROOT/snapshot.out"

printf 'authority-lifecycle: ok\n'
