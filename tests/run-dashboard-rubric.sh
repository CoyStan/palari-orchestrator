#!/usr/bin/env bash
# Encodes the operator console quality floor as checks that fail CI:
# structure and accessibility, the chain-of-custody surface, three ticket
# surfaces, keyboard and auto-refresh affordances, responsive and motion
# guards, AA contrast computed for both themes, and the snapshot contract
# the console renders from, including the gate section.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HTML="$ROOT/adapters/web/static/index.html"
CSS="$ROOT/adapters/web/static/app-shell.css"
BASE_CSS="$ROOT/adapters/web/static/styles.css"
JS="$ROOT/adapters/web/static/app.js"
SERVER="$ROOT/adapters/web/server.py"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

check_contains() {
	local file="$1"
	local needle="$2"
	local label="$3"
	if ! grep -Fq -- "$needle" "$file"; then
		printf 'dashboard-rubric: missing %s\n' "$label" >&2
		printf '  file: %s\n' "$file" >&2
		printf '  expected: %s\n' "$needle" >&2
		exit 1
	fi
}

# --- Structure and accessibility -------------------------------------------
check_contains "$HTML" 'class="skip-link"' "keyboard skip link"
check_contains "$HTML" 'id="main-content"' "main workspace target"
check_contains "$HTML" 'role="status" aria-live="polite"' "assistive status updates"
check_contains "$HTML" 'Repository-governed agent work' "five-second purpose signal"
check_contains "$HTML" 'Operator Console' "operator console title"
check_contains "$HTML" 'class="workbench"' "split surfaces/dossier workbench"
check_contains "$HTML" 'class="queue-column"' "surfaces workbench column"
check_contains "$HTML" 'class="review-column"' "dossier workbench column"
check_contains "$HTML" 'class="rail-guide"' "console flow guide"
check_contains "$HTML" 'class="keymap"' "keyboard shortcut legend"
check_contains "$HTML" 'id="healthActionsList"' "health action surface"
check_contains "$HTML" 'id="founderInboxList"' "founder inbox surface"
check_contains "$HTML" 'Founder Inbox' "founder decision inbox label"

# --- Three surfaces over one snapshot ----------------------------------------
check_contains "$HTML" 'class="surface-tabs" role="tablist"' "surface tabs"
check_contains "$HTML" 'data-surface="queue"' "queue surface tab"
check_contains "$HTML" 'data-surface="board"' "board surface tab"
check_contains "$HTML" 'data-surface="ledger"' "ledger surface tab"
check_contains "$HTML" 'id="queueList"' "operator queue surface"
check_contains "$HTML" 'id="boardLanes"' "pipeline board lanes"
check_contains "$HTML" 'id="ticketSearch"' "ticket search control"
check_contains "$HTML" 'class="ticket-table"' "accessible ticket table"
check_contains "$HTML" 'id="ticketFocus"' "selected ticket dossier"

# --- Cryptographic truth surfaces --------------------------------------------
check_contains "$HTML" 'id="custody"' "chain of custody surface"
check_contains "$HTML" 'id="rootFingerprint"' "root key plaque"
check_contains "$HTML" 'id="gateChip"' "gate posture chip"
check_contains "$HTML" 'id="gatePosture"' "signed acceptance summary"
check_contains "$JS" 'custody-chain' "custody chain renderer"
check_contains "$JS" 'verdict-stamp' "verdict stamp renderer"
check_contains "$JS" 'verdict.reasons' "verbatim refusal reasons"
check_contains "$JS" 'Honor-system' "honest gate-off state"
check_contains "$JS" 'sealState' "evidence seal derivation"
check_contains "$JS" 'gate verify' "verify command affordance"

# --- Operator speed -----------------------------------------------------------
check_contains "$HTML" 'id="themeButton"' "theme toggle control"
check_contains "$HTML" 'id="autoButton"' "auto refresh toggle"
check_contains "$HTML" 'id="roleList"' "role authority surface"
check_contains "$HTML" 'id="humanSummary"' "human decision surface"
check_contains "$HTML" 'id="companyGovernance"' "company governance surface"
check_contains "$HTML" 'id="companyGovernanceSummary"' "company governance metrics"
check_contains "$HTML" 'id="companyWorkflowList"' "company workflow list"
check_contains "$JS" 'function formatTimestamp' "compact timestamp formatting"
check_contains "$JS" 'function formatCountdown' "lease countdown formatting"
check_contains "$JS" 'function renderCompanyGovernance' "company governance renderer"
check_contains "$JS" 'snapshot.company_os' "company OS snapshot read"
check_contains "$JS" 'lease-tick' "live lease ticking"
check_contains "$JS" 'document.hidden' "auto refresh pauses when hidden"
check_contains "$JS" 'fresh=1' "manual refresh bypasses cache"
check_contains "$JS" 'event.key === "/"' "search focus shortcut"
check_contains "$JS" 'moveSelection' "j/k selection movement"
check_contains "$JS" 'prefers-color-scheme: dark' "system theme respected on first load"

# --- Layout, responsiveness, motion -------------------------------------------
check_contains "$CSS" 'grid-template-columns: 252px minmax(0, 1fr)' "status rail plus workbench shell"
check_contains "$BASE_CSS" 'overflow-x: hidden;' "320px horizontal overflow guard"
check_contains "$BASE_CSS" 'min-width: 320px;' "minimum viewport support"
check_contains "$CSS" 'min-width: 0;' "grid item min-width guard"
check_contains "$CSS" 'width: min(1280px, 100%)' "bounded workbench width"
check_contains "$CSS" '@media (max-width: 1360px)' "wide desktop breakpoint"
check_contains "$CSS" '@media (max-width: 1180px)' "narrow desktop workbench breakpoint"
check_contains "$CSS" '@media (max-width: 840px)' "tablet/mobile breakpoint"
check_contains "$CSS" '@media (prefers-reduced-motion: reduce)' "reduced-motion support"
check_contains "$CSS" '.workbench {' "surfaces/dossier split layout"
check_contains "$CSS" '.support-grid {' "supporting proof panel grid"
check_contains "$CSS" '.board-lanes {' "pipeline board lanes styling"
check_contains "$CSS" '.custody-chain {' "custody chain styling"
check_contains "$CSS" '.seal-disc {' "seal disc styling"
check_contains "$CSS" '.verdict-stamp {' "verdict stamp styling"
check_contains "$CSS" '.command-dock {' "command surface block"
check_contains "$CSS" 'position: relative;' "non-overlapping command surface"
check_contains "$CSS" 'max-height: min(420px, 58vh);' "command dock height guard"
check_contains "$CSS" '.operator-strip {' "operator summary strip"
check_contains "$CSS" '.company-governance-summary {' "company governance metrics styling"
check_contains "$CSS" '.company-workflow-row {' "company workflow row styling"
check_contains "$CSS" '.founder-inbox {' "founder inbox styling"
check_contains "$CSS" '.inbox-item {' "founder inbox item styling"
check_contains "$CSS" '.queue-controls {' "queue search/filter controls"
check_contains "$CSS" '.readiness-grid {' "review readiness grid"
check_contains "$CSS" '.ticket-table {' "ticket table styling"
check_contains "$CSS" '.ticket-link {' "ticket table selection control"
check_contains "$CSS" '.ticket-table td::before' "mobile ticket card labels"
check_contains "$CSS" 'body[data-theme="dark"]' "dark theme support"
check_contains "$CSS" 'body[data-health="watch"]' "semantic watch health state"
check_contains "$CSS" 'body[data-health="blocked"]' "semantic blocked health state"
check_contains "$CSS" ':focus-visible' "visible keyboard focus"
check_contains "$CSS" 'white-space: nowrap;' "timestamp nowrap/truncation guard"
check_contains "$CSS" '--seal:' "reserved cryptographic truth color"

# The seal color must stay reserved: state pills never reuse it.
if grep -E '^\.status\.[a-z-]+' "$CSS" | grep -q 'seal'; then
	printf 'dashboard-rubric: the seal color leaked into generic status pills\n' >&2
	exit 1
fi

# --- AA contrast, computed for both themes ------------------------------------
python3 - "$CSS" <<'PY'
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()

def block_tokens(block: str) -> dict:
    return dict(re.findall(r"--([a-z-]+):\s*(#[0-9a-fA-F]{6})", block))

root_match = re.search(r":root\s*{(.*?)}", text, re.S)
dark_match = re.search(r'body\[data-theme="dark"\]\s*{(.*?)}', text, re.S)
if not root_match or not dark_match:
    raise SystemExit("dashboard-rubric: could not locate token blocks")

light = block_tokens(root_match.group(1))
dark = {**light, **block_tokens(dark_match.group(1))}

def luminance(value: str) -> float:
    channels = [int(value[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [
        channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4
        for channel in channels
    ]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]

def contrast(foreground: str, background: str) -> float:
    first = luminance(foreground)
    second = luminance(background)
    lighter, darker = max(first, second), min(first, second)
    return (lighter + 0.05) / (darker + 0.05)

checks = [
    ("ink text", "ink", "surface", 4.5),
    ("muted text", "muted", "surface", 4.5),
    ("seal truth", "seal", "surface", 4.5),
    ("green status", "green", "surface", 4.5),
    ("amber status", "amber", "surface", 4.5),
    ("red status", "red", "surface", 4.5),
    ("blue status", "blue", "surface", 4.5),
    ("focus ring", "focus", "surface", 3.0),
    ("seal on its wash", "seal", "seal-wash", 4.5),
    ("red on its wash", "red", "red-wash", 4.5),
    ("amber on its wash", "amber", "amber-wash", 4.5),
    ("green on its wash", "green", "green-wash", 4.5),
]

for theme_name, tokens in (("light", light), ("dark", dark)):
    for label, foreground, background, minimum in checks:
        ratio = contrast(tokens[foreground], tokens[background])
        if ratio < minimum:
            raise SystemExit(
                f"dashboard-rubric: {theme_name} {label} contrast "
                f"{ratio:.2f}:1 is below {minimum}:1"
            )
PY

# --- Server and snapshot contract ----------------------------------------------
python3 - "$SERVER" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
compile(path.read_text(encoding="utf-8"), str(path), "exec")
PY

(cd "$ROOT" && ./bin/palari web --check >"$TMP")
grep -Fq '"project": "Palari Orchestrator"' "$TMP"
python3 - "$TMP" <<'PY'
import json
import sys

snapshot = json.load(open(sys.argv[1], encoding="utf-8"))
assert snapshot["snapshot_mode"] == "fast"
assert "operator" in snapshot
assert "next_action" in snapshot["operator"]
assert "inbox" in snapshot["operator"]
assert "inbox_counts" in snapshot["operator"]
for key in ("human_gate", "blocked", "review_needed", "evidence_needed", "can_continue"):
    assert key in snapshot["operator"]["inbox_counts"], f"inbox_counts missing {key}"
for item in snapshot["operator"]["inbox"]:
    for key in ("ticket_id", "title", "category", "severity", "actor", "detail", "command"):
        assert key in item, f"inbox item missing {key}"
assert "roles" in snapshot
assert "items" in snapshot["roles"]
assert "lint" in snapshot["roles"]
assert snapshot["roles"]["lint"]["mode"] == "shallow"
assert "company_os" in snapshot
company = snapshot["company_os"]
assert "workflows" in company
assert "human_governance" in company
assert "autonomy" in company
assert company["policy"]["simulation_only"] is True
assert company["broker"]["real_side_effects_enabled"] is False
gate = snapshot["gate"]
for key in ("enabled", "available", "initialized", "root_fingerprint", "layout", "tickets"):
    assert key in gate, f"gate section missing {key}"
active_tickets = [ticket for ticket in snapshot["tickets"] if ticket["status"] != "accepted"]
assert snapshot["health"]["stale_claims"] <= len(active_tickets)
for ticket in snapshot["tickets"]:
    assert ticket["status"] != "accepted"
    assert "next_action" in ticket
    assert "created_by_role" in ticket
    assert "delegated_to_role" in ticket
    assert "accepted_by" in ticket
    assert "lease" in ticket
PY

(cd "$ROOT" && ./bin/palari snapshot --json --full >"$TMP")
python3 - "$TMP" "$ROOT" <<'PY'
import json
import sys
from pathlib import Path

snapshot = json.load(open(sys.argv[1], encoding="utf-8"))
root = Path(sys.argv[2])
assert snapshot["snapshot_mode"] == "full"
assert snapshot["roles"]["lint"].get("mode") != "shallow"
# Accepted tickets only appear in full mode when the repo actually has
# closed tickets on disk; release archives intentionally ship none.
closed = [p for p in (root / "tickets" / "closed").glob("*.md") if p.name != "README.md"]
if closed:
    assert any(ticket["status"] == "accepted" for ticket in snapshot["tickets"])
PY

printf 'dashboard-rubric: ok (structure, custody surface, contrast both themes, snapshot contract)\n'
