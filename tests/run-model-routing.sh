#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'model-routing: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* .palari

git init -b main >/dev/null
git config user.email "models@example.invalid"
git config user.name "Models Test"
git add .
git commit -m "models baseline" >/dev/null

# Configure concrete class -> model mappings for the test.
cat >>palari.config.yaml <<'CFG'
model_fast_opencode: anthropic/test-fast
model_balanced_opencode: anthropic/test-balanced
model_frontier_opencode: anthropic/test-frontier
CFG

# Routing table renders.
./bin/palari model routes >"$TMP_ROOT/routes.out"
grep -Fq "R1  -> fast" "$TMP_ROOT/routes.out" || fail "routes missing R1 mapping"
grep -Fq "R5  -> frontier" "$TMP_ROOT/routes.out" || fail "routes missing R5 mapping"
grep -Fq "anthropic/test-frontier" "$TMP_ROOT/routes.out" || fail "routes missing executor mapping"

# Risk tier resolution: R1 -> fast, R3/R5 -> frontier.
./bin/palari ticket create MRT-0001 "Low risk chore" --risk R1 \
	--allowed "README.md" --verify "test -f README.md" >/dev/null
./bin/palari ticket create MRT-0002 "High risk change" --risk R3 \
	--allowed "CHANGELOG.md" --verify "true" >/dev/null
./bin/palari ticket create MRT-0005 "Governance risk change" --risk R5 \
	--allowed "contracts/**" --verify "true" >/dev/null

./bin/palari model show MRT-0001 --executor opencode >"$TMP_ROOT/show1.out"
grep -Fq "class: fast" "$TMP_ROOT/show1.out" || fail "R1 should route to fast"
grep -Fq "resolved model: anthropic/test-fast" "$TMP_ROOT/show1.out" || fail "fast mapping not resolved"

./bin/palari model show MRT-0002 --executor opencode >"$TMP_ROOT/show2.out"
grep -Fq "class: frontier" "$TMP_ROOT/show2.out" || fail "R3 should route to frontier"
./bin/palari model show MRT-0005 --executor opencode >"$TMP_ROOT/show-r5.out"
grep -Fq "class: frontier" "$TMP_ROOT/show-r5.out" || fail "R5 should route to frontier"

# model_hint overrides: class hint and exact-model hint.
./bin/palari ticket create MRT-0003 "Hinted class" --risk R3 --model-hint fast \
	--allowed "docs/**" --verify "true" >/dev/null
./bin/palari model show MRT-0003 --executor opencode >"$TMP_ROOT/show3.out"
grep -Fq "resolved model: anthropic/test-fast" "$TMP_ROOT/show3.out" || fail "class hint should override risk"

./bin/palari ticket create MRT-0004 "Hinted exact" --risk R1 --model-hint vendor/custom-model \
	--allowed "docs/**" --verify "true" >/dev/null
./bin/palari model show MRT-0004 --executor opencode >"$TMP_ROOT/show4.out"
grep -Fq "resolved model: vendor/custom-model" "$TMP_ROOT/show4.out" || fail "exact hint should pass through"

# Packet prints the suggested class.
git add -A >/dev/null && git commit -qm "tickets and config" >/dev/null
./bin/palari ticket claim MRT-0001 tester >/dev/null
git add -A >/dev/null && git commit -qm "claim state" >/dev/null
./bin/palari worktree MRT-0001 >/dev/null
./bin/palari packet MRT-0001 specialist >"$TMP_ROOT/packet.out"
grep -Fq "Model class: fast" "$TMP_ROOT/packet.out" || fail "packet missing model class"

# Queue dry-run annotates plannable steps with the class.
./bin/palari run --dry-run >"$TMP_ROOT/plan.out"
grep -Fq "[model class:" "$TMP_ROOT/plan.out" || fail "dry-run missing model class annotation"

# agent run (mock, dry-run) reports the routed model without executing.
./bin/palari agent run MRT-0001 --executor mock --dry-run >"$TMP_ROOT/agent.out" 2>&1 || true
grep -Eq "model: .+ \((routed|executor-default)\)" "$TMP_ROOT/agent.out" ||
	fail "agent dry-run missing routed model line"

# Disabling routing falls back to executor default.
sed -i 's/^model_routing_enabled: true$/model_routing_enabled: false/' palari.config.yaml
./bin/palari model show MRT-0002 --executor opencode >"$TMP_ROOT/show5.out"
grep -Fq "resolved model: (executor default)" "$TMP_ROOT/show5.out" ||
	fail "disabled routing should resolve to executor default"

printf 'model-routing: ok\n'
