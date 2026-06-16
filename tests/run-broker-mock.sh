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

./bin/palari ticket create BRK-0101 "Broker check fixture" \
	--risk R3 \
	--priority P2 \
	--allowed 'adapters/broker/**' \
	--allowed reports/evidence/BRK-0101/** \
	--verify "broker check fixture" >/dev/null

if ./bin/palari broker run BRK-0100 -- printf hello >"$TMP_ROOT/no-mock.out" 2>&1; then
	fail "broker run should require --mock"
fi
grep -Fq "mock/sandbox only" "$TMP_ROOT/no-mock.out" ||
	fail "missing mock/sandbox diagnostic"

if ./bin/palari broker run MISSING-0001 --mock -- printf hello >"$TMP_ROOT/missing-ticket.out" 2>&1; then
	fail "broker run should require an existing ticket"
fi
grep -Fq "ticket not found" "$TMP_ROOT/missing-ticket.out" ||
	fail "missing ticket diagnostic"

./bin/palari broker status >"$TMP_ROOT/status.out"
grep -Fq "real_side_effects_enabled: false" "$TMP_ROOT/status.out" ||
	fail "broker status must show side effects disabled"
grep -Fq "network_isolation_enforced: false" "$TMP_ROOT/status.out" ||
	fail "broker status must not claim network isolation"

./bin/palari broker check BRK-0101 --tool filesystem --action write --resource adapters/broker/example.py --json >"$TMP_ROOT/check-allowed.json"
python3 - "$TMP_ROOT/check-allowed.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["allowed"] is True
assert data["reasons"] == ["resource is within ticket allowed paths"]
assert data["risk"] == "R3"
assert data["requires_human"] is True
assert data["requires_policy"] is False
assert data["side_effects_enabled"] is False
assert data["would_execute"] is False
assert data["tool"] == "filesystem"
assert data["action"] == "write"
assert data["resource"] == "adapters/broker/example.py"
assert data["boundary_type"] == "permission_check_only"
PY
./bin/palari broker check BRK-0101 --tool filesystem --action write --resource .env --json >"$TMP_ROOT/check-forbidden.json"
python3 - "$TMP_ROOT/check-forbidden.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["allowed"] is False
assert data["reasons"] == ["resource matches ticket forbidden paths"]
assert data["would_execute"] is False
PY
./bin/palari broker check BRK-0101 --tool filesystem --action write --resource README.md >"$TMP_ROOT/check-outside.out"
grep -Fq "allowed: false" "$TMP_ROOT/check-outside.out" ||
	fail "broker check should deny outside-scope resources"
grep -Fq "resource is outside ticket allowed paths" "$TMP_ROOT/check-outside.out" ||
	fail "broker check outside-scope reason missing"
./bin/palari broker check BRK-0101 --tool filesystem --action write --resource 'adapters/broker/../deploy/foo' --json >"$TMP_ROOT/check-traversal.json"
python3 - "$TMP_ROOT/check-traversal.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["allowed"] is False
assert data["normalized_resource"] == "adapters/deploy/foo"
assert data["reasons"] == ["resource is outside ticket allowed paths"]
assert data["would_execute"] is False
PY
test ! -d reports/evidence/BRK-0101/broker ||
	fail "broker check must not create broker evidence"

python3 - "$REPO_ROOT/schemas/broker-action-request.schema.json" "$REPO_ROOT/schemas/broker-result.schema.json" <<'PY'
import json
import sys

request_schema = json.load(open(sys.argv[1]))
result_schema = json.load(open(sys.argv[2]))
assert request_schema["properties"]["schema_version"]["const"] == "broker-action-request-v1"
assert "repo_file_write" in request_schema["properties"]["side_effect_class"]["enum"]
assert "credential_access" in request_schema["properties"]["side_effect_class"]["enum"]
assert "network_access" in request_schema["properties"]["side_effect_class"]["enum"]
assert result_schema["properties"]["schema_version"]["const"] == "broker-result-v1"
assert result_schema["properties"]["status"]["enum"] == ["allowed", "denied", "observed", "failed"]
assert result_schema["properties"]["side_effects_enabled"]["const"] is False
PY

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
assert data["schema_version"] == "broker-observation-v1"
assert data["ticket"] == "BRK-0100"
assert data["run_id"].startswith("RUN-")
assert data["broker_mode"] == "mock"
assert data["mode"] == "mock"
assert data["boundary_type"] == "observed_only"
assert data["side_effects_enabled"] is False
assert data["credentials_available_to_agents"] is False
assert data["network_or_hosted_api_access"] is False
assert data["working_directory"]
assert data["started_at"]
assert data["ended_at"]
assert data["executed"] is True
assert data["refused"] is False
assert data["exit_code"] == 0
assert data["command"] == ["printf", "hello broker"]
assert data["request_id"].startswith("BRK-REQ-RUN-")
assert data["status"] == "observed"
assert data["decision"] == "observed"
assert data["decision_reason"] == "mock_broker_observed_command"
assert data["changed_resources"] == data["changed_paths"]
assert data["forbidden_path_changes"] == []
assert data["signed_by"] == "broker-mock"
assert len(data["input_hash"]) == 64
assert len(data["output_hash"]) == 64
request = data["action_request"]
assert request["schema_version"] == "broker-action-request-v1"
assert request["ticket"] == "BRK-0100"
assert request["risk"] == "R2"
assert request["tool"] == "printf"
assert request["action"] == "execute_command"
assert request["side_effect_class"] == "local_process_observation"
assert request["requires_human"] is False
assert request["requires_policy"] is False
assert "mock_only_observation" in request["allowed_by"]
assert "credential_required" in request["forbidden_if"]
result = data["broker_result"]
assert result["schema_version"] == "broker-result-v1"
assert result["request_id"] == request["request_id"]
assert result["status"] == "observed"
assert result["side_effects_enabled"] is False
assert result["signed_by"] == "broker-mock"
assert len(data["stdout_sha256"]) == 64
assert len(data["stderr_sha256"]) == 64
PY
grep -Fq "hello broker" "$(dirname "$summary")/stdout.txt" ||
	fail "broker stdout artifact missing command output"
test -f "$(dirname "$summary")/request.json" ||
	fail "broker request artifact missing"
test -f "$(dirname "$summary")/result.json" ||
	fail "broker result artifact missing"

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
assert data["items"][0]["schema_version"] == "broker-observation-v1"
assert data["items"][0]["boundary_type"] == "observed_only"
assert data["items"][0]["status"] == "observed"
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
assert refused[0]["status"] == "denied"
assert refused[0]["decision"] == "denied"
assert refused[0]["decision_reason"] == "dangerous_command_refused"
assert refused[0]["broker_result"]["status"] == "denied"
assert "rm -rf" in refused[0]["refusal_reason"]
PY

./bin/palari broker run BRK-0100 --sandbox -- sh -c 'printf "\nsandbox allowed\n" >> README.md' >"$TMP_ROOT/sandbox-allowed.out"
grep -Fq "decision: observed_allowed" "$TMP_ROOT/sandbox-allowed.out" ||
	fail "sandbox allowed decision missing"
grep -Fq "boundary_type: local_sandbox_repo_copy" "$TMP_ROOT/sandbox-allowed.out" ||
	fail "sandbox boundary diagnostic missing"
if grep -Fq "sandbox allowed" README.md; then
	fail "sandbox broker copied changes back to the real repo"
fi
sandbox_summary="$(find reports/evidence/BRK-0100/broker -name summary.json | sort | tail -n 1)"
python3 - "$sandbox_summary" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["schema_version"] == "broker-observation-v1"
assert data["broker_mode"] == "sandbox"
assert data["mode"] == "sandbox"
assert data["boundary_type"] == "local_sandbox_repo_copy"
assert data["side_effects_enabled"] is False
assert data["credentials_available_to_agents"] is False
assert data["network_or_hosted_api_access"] is False
assert data["network_isolation_enforced"] is False
assert data["sandbox_command_policy"] == "simple_printf_redirect_only"
assert data["decision"] == "observed_allowed"
assert data["broker_exit_code"] == 0
assert data["changed_paths"] == ["README.md"]
assert data["forbidden_path_changes"] == []
assert data["sandbox_real_repo_mutated"] is False
assert data["sandbox_retained"] is False
assert data["broker_result"]["signed_by"] == "broker-sandbox"
assert data["artifacts"]["patch"] == "patch.diff"
PY
grep -Fq "sandbox allowed" "$(dirname "$sandbox_summary")/patch.diff" ||
	fail "sandbox patch artifact missing allowed change"

host_escape="$TMP_ROOT/host-escape"
if ./bin/palari broker sandbox BRK-0100 -- sh -c "printf \"host escape\n\" > $host_escape" >"$TMP_ROOT/sandbox-host-escape.out" 2>&1; then
	fail "sandbox broker should refuse absolute host path writes"
fi
test ! -e "$host_escape" ||
	fail "sandbox broker wrote to an absolute host path"
grep -Fq "decision: denied" "$TMP_ROOT/sandbox-host-escape.out" ||
	fail "sandbox host escape denial missing"
grep -Fq "resource path must be relative" "$TMP_ROOT/sandbox-host-escape.out" ||
	fail "sandbox host escape diagnostic missing"
host_escape_summary="$(find reports/evidence/BRK-0100/broker -name summary.json | sort | tail -n 1)"
python3 - "$host_escape_summary" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["broker_mode"] == "sandbox"
assert data["executed"] is False
assert data["decision"] == "denied"
assert data["decision_reason"] == "sandbox_command_refused"
assert data["sandbox_command_policy"] == "simple_printf_redirect_only"
assert data["broker_exit_code"] == 126
PY

readme_before_sha="$(sha256sum README.md | awk '{print $1}')"
if ./bin/palari broker sandbox BRK-0100 -- sh -c 'printf "traversal\n" > tests/../README.md' >"$TMP_ROOT/sandbox-traversal.out" 2>&1; then
	fail "sandbox broker should refuse traversal paths before execution"
fi
readme_after_sha="$(sha256sum README.md | awk '{print $1}')"
[[ "$readme_before_sha" == "$readme_after_sha" ]] ||
	fail "sandbox traversal command changed an otherwise allowed path"
grep -Fq "decision: denied" "$TMP_ROOT/sandbox-traversal.out" ||
	fail "sandbox traversal denial missing"
grep -Fq "path traversal segments are not supported" "$TMP_ROOT/sandbox-traversal.out" ||
	fail "sandbox traversal diagnostic missing"
traversal_summary="$(find reports/evidence/BRK-0100/broker -name summary.json | sort | tail -n 1)"
python3 - "$traversal_summary" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["broker_mode"] == "sandbox"
assert data["executed"] is False
assert data["decision"] == "denied"
assert data["decision_reason"] == "sandbox_command_refused"
assert data["sandbox_command_policy"] == "simple_printf_redirect_only"
assert data["broker_exit_code"] == 126
assert "path traversal segments" in data["refusal_reason"]
assert data["changed_paths"] == []
PY

if ./bin/palari broker sandbox BRK-0100 -- sh -c 'printf "secret\n" > .env' >"$TMP_ROOT/sandbox-forbidden.out" 2>&1; then
	fail "sandbox broker should return nonzero for forbidden path changes"
fi
grep -Fq "decision: denied_or_violation" "$TMP_ROOT/sandbox-forbidden.out" ||
	fail "sandbox violation decision missing"
if test -f .env; then
	fail "sandbox broker copied forbidden .env back to the real repo"
fi
violation_summary="$(find reports/evidence/BRK-0100/broker -name summary.json | sort | tail -n 1)"
python3 - "$violation_summary" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["broker_mode"] == "sandbox"
assert data["decision"] == "denied_or_violation"
assert data["status"] == "denied"
assert data["decision_reason"] == "sandbox_scope_violation"
assert data["broker_exit_code"] != 0
assert data["changed_paths"] == [".env"]
assert data["forbidden_path_changes"] == [".env"]
assert data["outside_scope_changes"] == []
assert data["sandbox_real_repo_mutated"] is False
PY

printf 'broker-mock: ok\n'
