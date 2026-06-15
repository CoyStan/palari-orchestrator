#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
	printf 'performance: %s\n' "$*" >&2
	exit 1
}

contains_literal() {
	local haystack="$1"
	local needle="$2"
	[[ "$haystack" == *"$needle"* ]]
}

command -v python3 >/dev/null 2>&1 || {
	printf 'performance: skipped (python3 unavailable; fast engine cannot run)\n'
	exit 0
}

# The fast engine must actually be the one answering. Capture to variables
# and check them in-process; piping into grep -q under pipefail can surface
# SIGPIPE from the producer as a false failure on large JSON.
fast_out="$(./bin/palari snapshot --json)"
contains_literal "$fast_out" '"snapshot_engine": "python-fast"' ||
	fail "snapshot --json is not served by the fast engine"
legacy_out="$(PALARI_SNAPSHOT_ENGINE=bash ./bin/palari snapshot --json)"
contains_literal "$legacy_out" '"snapshot_mode":' ||
	fail "legacy bash snapshot fallback is broken"
web_out="$(./bin/palari web --check)"
contains_literal "$web_out" '"snapshot_engine": "python-fast"' ||
	fail "web --check is not served by the fast engine"

# Gate-enabled repos must keep the instant path (shallow gate state).
GATE_TMP="$(mktemp -d)"
trap 'rm -rf "$GATE_TMP"' EXIT
(cd "$ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$GATE_TMP" && tar -xf -)
python3 - "$GATE_TMP/palari.config.yaml" <<'PY'
import re, sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
text = re.sub(r"(gate:\n(?:[ \t]+.*\n)*?[ \t]+enabled:)[ \t]*\w+", r"\1 true", text, count=1)
open(path, "w", encoding="utf-8").write(text)
PY
gate_out="$(cd "$GATE_TMP" && chmod +x bin/palari && ./bin/palari snapshot --json)"
contains_literal "$gate_out" '"snapshot_engine": "python-fast"' ||
	fail "gate-enabled repo lost the fast path"
contains_literal "$gate_out" '"enabled": true' ||
	fail "gate-enabled fast snapshot missing gate state"
web_out="$(./bin/palari web --check)"
contains_literal "$web_out" '"snapshot_engine": "python-fast"' ||
	fail "web --check is not served by the fast engine"

python3 - <<'PY'
import json
import os
import subprocess
import sys
import time

# Warning thresholds by default; PALARI_PERF_STRICT=1 turns them into failures.
THRESHOLDS_MS = {
    "snapshot-json": 800,
    "web-check": 800,
    "status": 500,
    "status-next": 500,
}
strict = os.environ.get("PALARI_PERF_STRICT") == "1"
failures = []

def measure(label, cmd, parse_json=False):
    # Best of three to reduce CI noise.
    best = None
    out = ""
    for _ in range(3):
        start = time.perf_counter()
        result = subprocess.run(cmd, capture_output=True, text=True)
        elapsed = (time.perf_counter() - start) * 1000
        if result.returncode != 0:
            print(result.stderr, file=sys.stderr)
            raise SystemExit(f"performance: {label} exited {result.returncode}")
        out = result.stdout
        best = elapsed if best is None else min(best, elapsed)
    limit = THRESHOLDS_MS[label]
    verdict = "ok" if best <= limit else "SLOW"
    print(f"performance: {label}: {best:.0f} ms (budget {limit} ms) {verdict}")
    if best > limit:
        failures.append(label)
    if parse_json:
        json.loads(out)

measure("snapshot-json", ["./bin/palari", "snapshot", "--json"], parse_json=True)
measure("web-check", ["./bin/palari", "web", "--check"], parse_json=True)
measure("status", ["./bin/palari", "status"])
measure("status-next", ["./bin/palari", "status", "--next"])
THRESHOLDS_MS["web-check"] = 800
measure("web-check", ["./bin/palari", "web", "--check"], parse_json=True)

if failures and strict:
    raise SystemExit(f"performance: over budget: {', '.join(failures)}")
if failures:
    print("performance: warning only; set PALARI_PERF_STRICT=1 to enforce budgets")
PY

printf 'performance: ok\n'
