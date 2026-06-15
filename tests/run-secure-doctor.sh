#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'secure-doctor: %s\n' "$*" >&2
	exit 1
}

expect_contains() {
	local file="$1" text="$2"
	grep -Fq -- "$text" "$file" || {
		cat "$file" >&2
		fail "expected output to contain: $text"
	}
}

expect_not_contains() {
	local file="$1" text="$2"
	if grep -Fq -- "$text" "$file"; then
		cat "$file" >&2
		fail "expected output not to contain: $text"
	fi
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari
rm -rf reports/evidence/*

./bin/palari doctor secure >"$TMP_ROOT/weak.out"
expect_contains "$TMP_ROOT/weak.out" "Governance posture: weak"
expect_contains "$TMP_ROOT/weak.out" "- ForgeGate disabled"
expect_contains "$TMP_ROOT/weak.out" "- broker side effects disabled/mock only"
expect_contains "$TMP_ROOT/weak.out" "- broker observations not found"
expect_contains "$TMP_ROOT/weak.out" "- policy acceptance simulation only"
expect_contains "$TMP_ROOT/weak.out" "- branch protection not verified locally"
expect_contains "$TMP_ROOT/weak.out" "- R5 requires human approval"
expect_not_contains "$TMP_ROOT/weak.out" "branch protection active"

./bin/palari doctor governance >"$TMP_ROOT/governance.out"
expect_contains "$TMP_ROOT/governance.out" "Governance posture: weak"
expect_contains "$TMP_ROOT/governance.out" "- branch protection not verified locally"

python3 - <<'PY'
from pathlib import Path
path = Path("palari.config.yaml")
text = path.read_text(encoding="utf-8")
text = text.replace("  enabled: false", "  enabled: true", 1)
path.write_text(text, encoding="utf-8")
PY
mkdir -p reports/evidence/SEC-TEST/broker/RUN-1
printf '{"mode":"mock-only"}\n' >reports/evidence/SEC-TEST/broker/RUN-1/summary.json

./bin/palari doctor secure >"$TMP_ROOT/stronger.out"
if python3 -c 'import cryptography' >/dev/null 2>&1; then
	expect_contains "$TMP_ROOT/stronger.out" "Governance posture: stronger"
	expect_contains "$TMP_ROOT/stronger.out" "- ForgeGate enabled for R2+"
else
	expect_contains "$TMP_ROOT/stronger.out" "Governance posture: weak"
	expect_contains "$TMP_ROOT/stronger.out" "- ForgeGate enabled but unavailable; acceptance fails closed"
fi
expect_contains "$TMP_ROOT/stronger.out" "- broker observations available"
expect_contains "$TMP_ROOT/stronger.out" "- broker side effects disabled/mock only"
expect_contains "$TMP_ROOT/stronger.out" "- policy acceptance simulation only"
expect_contains "$TMP_ROOT/stronger.out" "- branch protection not verified locally"
expect_contains "$TMP_ROOT/stronger.out" "- R5 requires human approval"
expect_not_contains "$TMP_ROOT/stronger.out" "branch protection active"

python3 - <<'PY'
from pathlib import Path
path = Path("palari.config.yaml")
text = path.read_text(encoding="utf-8")
text = text.replace("  r5_requires_dual_human: true", "  r5_requires_dual_human: false", 1)
path.write_text(text, encoding="utf-8")
PY
./bin/palari doctor secure >"$TMP_ROOT/r5-missing.out"
expect_contains "$TMP_ROOT/r5-missing.out" "Governance posture: weak"
expect_contains "$TMP_ROOT/r5-missing.out" "- R5 dual approval not configured"

printf 'secure-doctor: ok\n'
