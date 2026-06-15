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
expect_contains "$TMP_ROOT/weak.out" "R5 dual-human approval configured: true"
expect_contains "$TMP_ROOT/weak.out" "R5 dual-human approval enforced by accept: false"
expect_contains "$TMP_ROOT/weak.out" "Policy acceptance real mode enabled: false"
expect_contains "$TMP_ROOT/weak.out" "Policy acceptance simulation-only: true"
expect_contains "$TMP_ROOT/weak.out" "Broker real side effects enabled: false"
expect_contains "$TMP_ROOT/weak.out" "Broker is a security boundary: false"
expect_contains "$TMP_ROOT/weak.out" "Broker observations available: false"
expect_contains "$TMP_ROOT/weak.out" "ForgeGate enabled: false"
expect_contains "$TMP_ROOT/weak.out" "ForgeGate enforcement available: false"
expect_contains "$TMP_ROOT/weak.out" "Branch protection verified locally: false"
expect_contains "$TMP_ROOT/weak.out" "Posture: weak"
expect_not_contains "$TMP_ROOT/weak.out" "R5 requires human approval"
expect_not_contains "$TMP_ROOT/weak.out" "branch protection active"

./bin/palari doctor governance >"$TMP_ROOT/governance.out"
expect_contains "$TMP_ROOT/governance.out" "Posture: weak"
expect_contains "$TMP_ROOT/governance.out" "Branch protection verified locally: false"

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
	expect_contains "$TMP_ROOT/stronger.out" "ForgeGate enforcement available: true"
else
	expect_contains "$TMP_ROOT/stronger.out" "ForgeGate enforcement available: false"
fi
expect_contains "$TMP_ROOT/stronger.out" "Posture: weak"
expect_contains "$TMP_ROOT/stronger.out" "ForgeGate enabled: true"
expect_contains "$TMP_ROOT/stronger.out" "Broker observations available: true"
expect_contains "$TMP_ROOT/stronger.out" "Broker real side effects enabled: false"
expect_contains "$TMP_ROOT/stronger.out" "Policy acceptance simulation-only: true"
expect_contains "$TMP_ROOT/stronger.out" "R5 dual-human approval configured: true"
expect_contains "$TMP_ROOT/stronger.out" "R5 dual-human approval enforced by accept: false"
expect_contains "$TMP_ROOT/stronger.out" "Branch protection verified locally: false"
expect_not_contains "$TMP_ROOT/stronger.out" "R5 requires human approval"
expect_not_contains "$TMP_ROOT/stronger.out" "branch protection active"

python3 - <<'PY'
from pathlib import Path
path = Path("palari.config.yaml")
text = path.read_text(encoding="utf-8")
text = text.replace("  r5_requires_dual_human: true", "  r5_requires_dual_human: false", 1)
path.write_text(text, encoding="utf-8")
PY
./bin/palari doctor secure >"$TMP_ROOT/r5-missing.out"
expect_contains "$TMP_ROOT/r5-missing.out" "R5 dual-human approval configured: false"
expect_contains "$TMP_ROOT/r5-missing.out" "R5 dual-human approval enforced by accept: false"
expect_contains "$TMP_ROOT/r5-missing.out" "Posture: weak"
expect_not_contains "$TMP_ROOT/r5-missing.out" "R5 requires human approval"

printf 'secure-doctor: ok\n'
