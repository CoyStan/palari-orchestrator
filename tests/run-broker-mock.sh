#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'broker-mock: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-broker-mock.sh
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* .palari

git init -b main >/dev/null
git config user.email "broker@example.invalid"
git config user.name "Broker Test"
git add .
git commit -m "broker baseline" >/dev/null

./bin/palari ticket create BRK-0100 "Broker fixture" \
	--risk R2 \
	--priority P2 \
	--allowed README.md \
	--allowed reports/evidence/BRK-0100/** \
	--verify "test -f README.md" >/dev/null

if ./bin/palari broker run BRK-0100 -- printf hello >"$TMP_ROOT/no-mock.out" 2>&1; then
	fail "broker run should require --mock"
fi
grep -Fq "mock-only" "$TMP_ROOT/no-mock.out" ||
	fail "missing mock-only diagnostic"

if ./bin/palari broker run MISSING-0001 --mock -- printf hello >"$TMP_ROOT/missing-ticket.out" 2>&1; then
	fail "broker run should require an existing ticket"
fi
grep -Fq "ticket not found" "$TMP_ROOT/missing-ticket.out" ||
	fail "missing ticket diagnostic"

./bin/palari broker status >"$TMP_ROOT/status.out"
grep -Fq "real_side_effects_enabled: false" "$TMP_ROOT/status.out" ||
	fail "broker status must show side effects disabled"

./bin/palari broker run BRK-0100 --mock -- printf "hello broker" >"$TMP_ROOT/run.out"
grep -Fq "side_effects_enabled: false" "$TMP_ROOT/run.out" ||
	fail "broker run should print side-effect posture"
grep -Fq "evidence: reports/evidence/BRK-0100/broker/RUN-" "$TMP_ROOT/run.out" ||
	fail "broker run should print evidence path"

summary="$(find reports/evidence/BRK-0100/broker -name summary.json | sort | tail -n 1)"
[[ -n "$summary" ]] || fail "broker summary missing"
python3 - "$summary" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["ticket"] == "BRK-0100"
assert data["side_effects_enabled"] is False
assert data["credentials_available_to_agents"] is False
assert data["network_or_hosted_api_access"] is False
assert data["executed"] is True
assert data["refused"] is False
assert data["exit_code"] == 0
assert data["command"] == ["printf", "hello broker"]
assert len(data["stdout_sha256"]) == 64
assert len(data["stderr_sha256"]) == 64
PY
grep -Fq "hello broker" "$(dirname "$summary")/stdout.txt" ||
	fail "broker stdout artifact missing command output"

./bin/palari broker evidence BRK-0100 >"$TMP_ROOT/evidence.out"
grep -Fq "Broker evidence for BRK-0100" "$TMP_ROOT/evidence.out" ||
	fail "broker evidence text missing"
grep -Fq "real_side_effects_enabled: false" "$TMP_ROOT/evidence.out" ||
	fail "broker evidence posture missing"

./bin/palari broker evidence BRK-0100 --json >"$TMP_ROOT/evidence.json"
python3 - "$TMP_ROOT/evidence.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["ticket"] == "BRK-0100"
assert data["real_side_effects_enabled"] is False
assert data["count"] == 1
assert data["items"][0]["exit_code"] == 0
PY

if ./bin/palari broker run BRK-0100 --mock -- rm -rf /tmp/palari-broker-should-not-run >"$TMP_ROOT/refused.out" 2>&1; then
	fail "dangerous broker command should be refused"
fi
grep -Fq "refused dangerous command pattern" "$TMP_ROOT/refused.out" ||
	fail "dangerous refusal diagnostic missing"
./bin/palari broker evidence BRK-0100 --json >"$TMP_ROOT/evidence-refused.json"
python3 - "$TMP_ROOT/evidence-refused.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["count"] == 2
refused = [item for item in data["items"] if item["refused"]]
assert len(refused) == 1
assert refused[0]["executed"] is False
assert refused[0]["exit_code"] == 126
assert "rm -rf" in refused[0]["refusal_reason"]
PY

printf 'broker-mock: ok\n'
