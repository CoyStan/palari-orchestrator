#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'company-os-schemas: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari tests/run-company-os-schemas.sh
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* .palari workflows/proposed/*.md workflows/active/*.md workflows/closed/*.md humans/proposed/*.md humans/active/*.md humans/revoked/*.md outcomes/open/*.md outcomes/recorded/*.md policies/proposed/*.md policies/active/*.md policies/revoked/*.md

git init -b main >/dev/null
git config user.email "schemas@example.invalid"
git config user.name "Schema Test"
git add .
git commit -m "schema baseline" >/dev/null

./bin/palari human create HUMAN-SCHEMA "Schema Reviewer" \
	--skill product_strategy:L5 \
	--skill technical_governance:L4 \
	--role product_governor \
	--capacity-hgl 40 \
	--authority-max-risk R5 \
	--may-approve-policy-changes >/dev/null
./bin/palari human adopt HUMAN-SCHEMA --by founder >/dev/null

./bin/palari workflow create WF-9900 "Schema workflow" \
	--goal GOAL-0100 \
	--owner founder \
	--risk-ceiling R4 >/dev/null
python3 - <<'PY'
from pathlib import Path

path = Path("workflows/proposed/WF-9900-schema-workflow.md")
text = path.read_text(encoding="utf-8")
text = text.replace(
    "work_units:\n",
    "work_units:\n"
    "  - WU-0001|analysis|R2|Review schema shape\n"
    "  - WU-0002|rollout|R4|Approve typed contract rollout\n",
)
text = text.replace(
    "expected_decisions:\n",
    "expected_decisions:\n"
    "  - R4|approve|technical_governance:L4|Approve typed schema contract|evidence=normal\n",
)
path.write_text(text, encoding="utf-8")
PY
./bin/palari workflow adopt WF-9900 --by founder >/dev/null

./bin/palari policy create POL-SCHEMA "Schema low-risk docs policy" \
	--risk-max R2 \
	--mode simulation \
	--condition 'risk<=R2' \
	--condition 'evidence_score>=95' >/dev/null

./bin/palari outcome create OUT-SCHEMA \
	--workflow WF-9900 \
	--status observed \
	--title "Schema outcome" >/dev/null
python3 - <<'PY'
from pathlib import Path

path = Path("outcomes/open/OUT-SCHEMA-schema-outcome.md")
text = path.read_text(encoding="utf-8")
for old, new in [
    ("metric_name:\n", "metric_name: activation_rate\n"),
    ("metric_before:\n", "metric_before: 0.10\n"),
    ("metric_after:\n", "metric_after: 0.14\n"),
    ("metric_delta:\n", "metric_delta: 0.04\n"),
    ("risk_predicted:\n", "risk_predicted: R2\n"),
    ("risk_actual:\n", "risk_actual: R1\n"),
    ("hgl_predicted:\n", "hgl_predicted: 8\n"),
    ("hgl_actual:\n", "hgl_actual: 3\n"),
    ("human_decisions_predicted:\n", "human_decisions_predicted: 1\n"),
    ("human_decisions_actual:\n", "human_decisions_actual: 1\n"),
    ("review_outcome:\n", "review_outcome: passed\n"),
    ("rollback_used:\n", "rollback_used: false\n"),
    ("policy_candidate:\n", "policy_candidate: true\n"),
]:
    text = text.replace(old, new)
path.write_text(text, encoding="utf-8")
PY

./bin/palari ticket create BRK-9900 "Schema broker fixture" \
	--risk R1 \
	--priority P2 \
	--allowed README.md \
	--allowed reports/evidence/BRK-9900/** \
	--verify "test -f README.md" >/dev/null
./bin/palari broker run BRK-9900 --mock -- printf "schema broker" >/dev/null

./bin/palari workflow lint >/dev/null
./bin/palari human lint >/dev/null
./bin/palari policy lint >/dev/null
./bin/palari outcome lint >/dev/null
./bin/palari snapshot --json >"$TMP_ROOT/snapshot.json"

summary="$(find reports/evidence/BRK-9900/broker -name summary.json | sort | tail -n 1)"
[[ -n "$summary" ]] || fail "broker summary missing"

python3 - "$TMP_ROOT/snapshot.json" "$summary" <<'PY'
import json
import re
import sys
from pathlib import Path

snapshot_path = Path(sys.argv[1])
broker_summary_path = Path(sys.argv[2])

ROOT = Path(".")
SCHEMA_ROOT = ROOT / "schemas"
LIST_KEYS = {
    "allowed_modes",
    "conditions",
    "constraints",
    "expected_decisions",
    "forbidden_modes",
    "roles",
    "skills",
    "work_units",
}


def coerce(value):
    value = value.strip()
    if value == "":
        return ""
    if value == "true":
        return True
    if value == "false":
        return False
    if re.fullmatch(r"-?[0-9]+", value):
        return int(value)
    if re.fullmatch(r"-?[0-9]+\.[0-9]+", value):
        return float(value)
    return value


def parse_frontmatter(path):
    lines = path.read_text(encoding="utf-8").splitlines()
    assert lines and lines[0] == "---", path
    data = {}
    current = None
    for line in lines[1:]:
        if line == "---":
            break
        if line.startswith("  - ") and current:
            data.setdefault(current, []).append(coerce(line[4:]))
            continue
        match = re.match(r"^([A-Za-z0-9_]+):\s*(.*)$", line)
        if not match:
            continue
        key, raw = match.groups()
        if raw == "":
            if key in LIST_KEYS:
                data[key] = []
                current = key
            else:
                current = None
        else:
            data[key] = coerce(raw)
            current = None
    return data


def validate(schema, value, where="$"):
    expected = schema.get("type")
    if expected:
        checks = {
            "object": lambda item: isinstance(item, dict),
            "array": lambda item: isinstance(item, list),
            "string": lambda item: isinstance(item, str),
            "boolean": lambda item: isinstance(item, bool),
            "integer": lambda item: isinstance(item, int) and not isinstance(item, bool),
            "number": lambda item: (isinstance(item, int) or isinstance(item, float)) and not isinstance(item, bool),
        }
        if not checks[expected](value):
            raise AssertionError(f"{where}: expected {expected}, got {type(value).__name__}")
    if "const" in schema and value != schema["const"]:
        raise AssertionError(f"{where}: expected const {schema['const']!r}, got {value!r}")
    if "enum" in schema and value not in schema["enum"]:
        raise AssertionError(f"{where}: {value!r} not in {schema['enum']!r}")
    if isinstance(value, str):
        if schema.get("minLength", 0) and len(value) < schema["minLength"]:
            raise AssertionError(f"{where}: string too short")
        if "pattern" in schema and not re.search(schema["pattern"], value):
            raise AssertionError(f"{where}: {value!r} does not match {schema['pattern']!r}")
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        if "minimum" in schema and value < schema["minimum"]:
            raise AssertionError(f"{where}: {value!r} below minimum {schema['minimum']}")
    if isinstance(value, dict):
        for key in schema.get("required", []):
            if key not in value:
                raise AssertionError(f"{where}: missing required {key}")
        for key, child_schema in schema.get("properties", {}).items():
            if key in value:
                validate(child_schema, value[key], f"{where}.{key}")
    if isinstance(value, list) and "items" in schema:
        for index, item in enumerate(value):
            validate(schema["items"], item, f"{where}[{index}]")


def load_schema(name):
    schema = json.loads((SCHEMA_ROOT / name).read_text(encoding="utf-8"))
    assert schema["$schema"] == "https://json-schema.org/draft/2020-12/schema"
    assert schema["$id"].endswith(f"/schemas/{name}")
    return schema


schemas = {
    "workflow": load_schema("workflow.schema.json"),
    "human": load_schema("human.schema.json"),
    "policy": load_schema("policy.schema.json"),
    "outcome": load_schema("outcome.schema.json"),
    "broker": load_schema("broker-observation.schema.json"),
    "snapshot": load_schema("company-os-snapshot.schema.json"),
}

fixtures = {
    "workflow": parse_frontmatter(Path("workflows/active/WF-9900-schema-workflow.md")),
    "human": parse_frontmatter(Path("humans/active/HUMAN-SCHEMA-schema-reviewer.md")),
    "policy": parse_frontmatter(Path("policies/proposed/POL-SCHEMA-schema-low-risk-docs-policy.md")),
    "outcome": parse_frontmatter(Path("outcomes/open/OUT-SCHEMA-schema-outcome.md")),
    "broker": json.loads(broker_summary_path.read_text(encoding="utf-8")),
    "snapshot": json.loads(snapshot_path.read_text(encoding="utf-8"))["company_os"],
}

for name, fixture in fixtures.items():
    validate(schemas[name], fixture, name)

try:
    import jsonschema  # type: ignore
except Exception:
    print("company-os-schemas: jsonschema unavailable; stdlib validator covered representative fixtures")
else:
    for name, fixture in fixtures.items():
        jsonschema.validate(fixture, schemas[name])
    print("company-os-schemas: jsonschema validation also passed")

assert schemas["policy"]["properties"]["mode"]["const"] == "simulation"
assert schemas["policy"]["properties"]["risk_max"]["enum"] == ["R0", "R1", "R2"]
assert schemas["broker"]["properties"]["side_effects_enabled"]["const"] is False
assert schemas["snapshot"]["properties"]["policy"]["properties"]["simulation_only"]["const"] is True
assert schemas["snapshot"]["properties"]["broker"]["properties"]["real_side_effects_enabled"]["const"] is False
PY

printf 'company-os-schemas: ok\n'
