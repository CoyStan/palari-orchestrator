#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'policy-simulation: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-policy-simulation.sh
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* .palari policies/proposed/*.md policies/active/*.md policies/revoked/*.md decisions/open/*.md decisions/decided/*.md

git init -b main >/dev/null
git config user.email "policy@example.invalid"
git config user.name "Policy Test"
git add .
git commit -m "policy baseline" >/dev/null

./bin/palari init >"$TMP_ROOT/init.out"
test -f policies/proposed/.gitkeep || fail "init should create policies/proposed"
test -f policies/active/.gitkeep || fail "init should create policies/active"
test -f policies/revoked/.gitkeep || fail "init should create policies/revoked"
git add .
git commit -m "init policy directories" >/dev/null

./bin/palari policy create POL-DOCS-R1-AUTO "R1 docs simulation" \
	--risk-max R1 \
	--mode simulation >"$TMP_ROOT/policy-create.out"
grep -Fq "policy create: policies/proposed/POL-DOCS-R1-AUTO-r1-docs-simulation.md" "$TMP_ROOT/policy-create.out" ||
	fail "policy create path missing"
grep -Fq "mode is simulation-only" "$TMP_ROOT/policy-create.out" ||
	fail "simulation-only create note missing"

./bin/palari policy list >"$TMP_ROOT/policy-list.out"
grep -Fq "proposed POL-DOCS-R1-AUTO" "$TMP_ROOT/policy-list.out" ||
	fail "policy list missing proposed policy"

./bin/palari policy show POL-DOCS-R1-AUTO >"$TMP_ROOT/policy-show.out"
grep -Fq "Policy: POL-DOCS-R1-AUTO - R1 docs simulation" "$TMP_ROOT/policy-show.out" ||
	fail "policy show missing title"
grep -Fq "risk<=R1" "$TMP_ROOT/policy-show.out" ||
	fail "policy show missing conditions"

./bin/palari policy lint >"$TMP_ROOT/policy-lint.out"
grep -Fq "policy lint: ok" "$TMP_ROOT/policy-lint.out" ||
	fail "policy lint should pass"
git add policies/proposed/POL-DOCS-R1-AUTO-r1-docs-simulation.md
git commit -m "add simulation policy fixture" >/dev/null

if ./bin/palari policy create POL-BAD "Bad authority" --risk-max R5 --mode simulation >"$TMP_ROOT/policy-r5.out" 2>&1; then
	fail "R5 policy risk max should be refused"
fi
grep -Fq "R5 is never policy-eligible" "$TMP_ROOT/policy-r5.out" ||
	fail "R5 policy diagnostic missing"

./bin/palari ticket create SIM-0001 "Low risk docs" \
	--risk R1 \
	--priority P2 \
	--allowed README.md \
	--allowed tickets/open/SIM-0001-*.md \
	--allowed tickets/closed/SIM-0001-*.md \
	--allowed reports/SIM-0001-technical-report.md \
	--allowed reports/evidence/SIM-0001/** \
	--verify "test -f README.md" >/dev/null
./bin/palari ticket claim SIM-0001 tester --allow-overlap >/dev/null
cat >reports/SIM-0001-technical-report.md <<'DOC'
# SIM-0001 Technical Report

## Files Changed

- `README.md`

## Verification

- `test -f README.md`

## CI Evidence

- Filled by `palari ci`.

## Risks / Follow-Ups

- None.
DOC

./bin/palari ci SIM-0001 >/dev/null
git_before="$(git status --porcelain | sort)"
./bin/palari policy simulate SIM-0001 >"$TMP_ROOT/simulate-ok.out"
git_after="$(git status --porcelain | sort)"
[[ "$git_before" == "$git_after" ]] ||
	fail "policy simulate mutated repository state"
grep -Fq "Result: would_accept" "$TMP_ROOT/simulate-ok.out" ||
	fail "low-risk ticket should simulate would_accept"
grep -Fq "Mode: simulation only; no ticket state was changed." "$TMP_ROOT/simulate-ok.out" ||
	fail "simulation-only text missing"

./bin/palari policy simulate SIM-0001 --json >"$TMP_ROOT/simulate-ok.json"
python3 - "$TMP_ROOT/simulate-ok.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["ticket"] == "SIM-0001"
assert data["result"] == "would_accept"
assert data["simulation_only"] is True
assert data["state_changed"] is False
assert data["would_accept_by"] == ["POL-DOCS-R1-AUTO"]
assert data["evidence_score"] >= 95
PY

./bin/palari ticket create SIM-0002 "Higher risk work" \
	--risk R3 \
	--priority P2 \
	--allowed README.md \
	--allowed tickets/open/SIM-0002-*.md \
	--allowed tickets/closed/SIM-0002-*.md \
	--allowed reports/SIM-0002-technical-report.md \
	--allowed reports/SIM-0002-reviewer-note.md \
	--allowed reports/human/SIM-0002-human-report.md \
	--allowed reports/evidence/SIM-0002/** \
	--verify "test -f README.md" \
	--review \
	--human >/dev/null
./bin/palari ticket claim SIM-0002 tester --allow-overlap >/dev/null
./bin/palari policy simulate SIM-0002 >"$TMP_ROOT/simulate-r3.out"
grep -Fq "Result: would_not_accept" "$TMP_ROOT/simulate-r3.out" ||
	fail "R3 ticket should not pass R1 policy"
grep -Fq "ticket risk R3 exceeds policy risk_max R1" "$TMP_ROOT/simulate-r3.out" ||
	fail "R3 refusal reason missing"

./bin/palari ticket create SIM-0003 "Governance change" \
	--risk R5 \
	--priority P2 \
	--allowed README.md \
	--allowed tickets/open/SIM-0003-*.md \
	--allowed tickets/closed/SIM-0003-*.md \
	--allowed reports/SIM-0003-technical-report.md \
	--allowed reports/SIM-0003-reviewer-note.md \
	--allowed reports/human/SIM-0003-human-report.md \
	--allowed reports/evidence/SIM-0003/** \
	--verify "test -f README.md" \
	--review \
	--human >/dev/null
./bin/palari ticket claim SIM-0003 tester --allow-overlap >/dev/null
./bin/palari policy simulate SIM-0003 >"$TMP_ROOT/simulate-r5.out"
grep -Fq "R5 tickets are never eligible for policy acceptance" "$TMP_ROOT/simulate-r5.out" ||
	fail "R5 refusal reason missing"

cat >policies/proposed/POL-UNKNOWN-unknown.md <<'DOC'
---
id: POL-UNKNOWN
title: Unknown condition simulation
status: proposed
mode: simulation
risk_max: R1
conditions:
  - future_signal_ready
created: 2026-01-01
updated: 2026-01-01
---

# POL-UNKNOWN Unknown condition simulation
DOC
./bin/palari policy lint POL-UNKNOWN >"$TMP_ROOT/unknown-lint.out"
grep -Fq "policy lint: ok for POL-UNKNOWN" "$TMP_ROOT/unknown-lint.out" ||
	fail "unknown conditions should be lintable for future drafting"
./bin/palari policy simulate SIM-0001 >"$TMP_ROOT/unknown-sim.out"
grep -Fq "unknown condition: future_signal_ready" "$TMP_ROOT/unknown-sim.out" ||
	fail "unknown condition should fail closed in simulation"

if ./bin/palari accept SIM-0001 --by-policy POL-DOCS-R1-AUTO >"$TMP_ROOT/no-by-policy.out" 2>&1; then
	fail "accept by policy must not exist yet"
fi
grep -Eq "accept requires --by NAME|unknown" "$TMP_ROOT/no-by-policy.out" ||
	fail "policy acceptance should remain unsupported"

printf 'policy-simulation: ok\n'
