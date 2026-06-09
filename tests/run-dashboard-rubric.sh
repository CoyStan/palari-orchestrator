#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HTML="$ROOT/adapters/web/static/index.html"
CSS="$ROOT/adapters/web/static/app-shell.css"
JS="$ROOT/adapters/web/static/app.js"
SERVER="$ROOT/adapters/web/server.py"
README="$ROOT/adapters/web/README.md"
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

check_contains "$HTML" 'class="skip-link"' "keyboard skip link"
check_contains "$HTML" 'id="main-content"' "main workspace target"
check_contains "$HTML" 'role="status" aria-live="polite"' "assistive status updates"
check_contains "$HTML" 'class="workbench"' "split queue/review workbench"
check_contains "$HTML" 'class="queue-column"' "queue workbench column"
check_contains "$HTML" 'class="review-column"' "review workbench column"
check_contains "$HTML" 'class="rail-guide"' "non-clicking console flow guide"
check_contains "$HTML" 'id="healthActionsList"' "health action surface"
check_contains "$HTML" 'Repository-governed agent work' "five-second purpose signal"
check_contains "$HTML" 'Operator Console' "operator console title"
check_contains "$HTML" 'id="queueList"' "operator queue surface"
check_contains "$HTML" 'id="ticketSearch"' "ticket search control"
check_contains "$HTML" 'class="ticket-table"' "accessible ticket table"
check_contains "$HTML" 'id="ticketFocus"' "selected ticket review focus"
check_contains "$HTML" 'id="themeButton"' "theme toggle control"
check_contains "$HTML" 'id="roleList"' "role authority surface"
check_contains "$HTML" 'id="humanSummary"' "human decision surface"

check_contains "$CSS" 'grid-template-columns: 252px minmax(0, 1fr)' "status rail plus workbench shell"
check_contains "$CSS" 'overflow-x: hidden;' "320px horizontal overflow guard"
check_contains "$CSS" 'min-width: 0;' "grid item min-width guard"
check_contains "$CSS" 'width: min(1280px, 100%)' "bounded workbench width"
check_contains "$CSS" 'padding-bottom: 22px;' "ticket-to-command breathing room"
check_contains "$CSS" '@media (max-width: 1360px)' "danger-zone desktop breakpoint"
check_contains "$CSS" '@media (max-width: 1180px)' "narrow desktop workbench breakpoint"
check_contains "$CSS" '.workbench {' "queue/review split layout"
check_contains "$CSS" '.support-grid {' "supporting proof panel grid"
check_contains "$CSS" '.rail-guide {' "rail guide styling"
check_contains "$CSS" '.view-title {' "non-clicking view label"
check_contains "$CSS" '--focus: #5145cd;' "opaque focus token"
check_contains "$CSS" 'body[data-health="watch"]' "semantic watch health state"
check_contains "$CSS" 'body[data-health="blocked"]' "semantic blocked health state"
check_contains "$CSS" '@media (max-width: 840px)' "responsive tablet/mobile breakpoint"
check_contains "$CSS" '@media (prefers-reduced-motion: reduce)' "reduced-motion support"
check_contains "$CSS" '.command-dock {' "command surface block"
check_contains "$CSS" 'position: relative;' "non-overlapping command surface"
check_contains "$CSS" '.topbar {' "top control bar"
check_contains "$CSS" '.command-dock {' "command dock"
check_contains "$CSS" '.operator-strip {' "operator summary strip"
check_contains "$CSS" '.queue-controls {' "queue search/filter controls"
check_contains "$CSS" '.ticket-focus {' "selected ticket focus styling"
check_contains "$CSS" '.readiness-grid {' "review readiness grid"
check_contains "$CSS" '.timeline {' "ticket lifecycle timeline"
check_contains "$CSS" 'body[data-theme="dark"]' "dark theme support"
check_contains "$CSS" '.ticket-table {' "ticket table styling"
check_contains "$CSS" '.ticket-link {' "ticket table selection control"
check_contains "$CSS" '.ticket-table td::before' "mobile ticket card labels"
check_contains "$CSS" '.mono-panel .pill' "repository branch pill wrapping"
check_contains "$CSS" '.progress-rail {' "ticket progress rail"
check_contains "$CSS" '.role-row,' "role authority rows"
check_contains "$CSS" '.human-summary {' "human decision styling"
check_contains "$CSS" 'max-height: min(420px, 58vh);' "mobile command dock height guard"
check_contains "$CSS" 'white-space: nowrap;' "timestamp nowrap/truncation guard"
check_contains "$JS" 'function formatTimestamp' "compact timestamp formatting"

if grep -Eq '^(nav|nav a|nav a::before)([[:space:]{,:]|$)' "$CSS"; then
	printf 'dashboard-rubric: broad nav selector found in app-shell.css\n' >&2
	exit 1
fi

python3 - "$CSS" <<'PY'
import re
import sys

css = open(sys.argv[1], encoding="utf-8").read()

for selector in (".topbar", ".command-dock"):
    match = re.search(rf"{re.escape(selector)}\s*\{{(?P<body>.*?)\n\}}", css, re.S)
    if not match:
        raise SystemExit(f"dashboard-rubric: missing {selector} block")
    body = match.group("body")
    if "position: sticky" in body or "position: fixed" in body:
        raise SystemExit(f"dashboard-rubric: {selector} must not be an overlay")
PY

check_contains "$JS" 'function healthIssues' "issue-to-action model"
check_contains "$JS" 'function renderOperatorSummary' "operator summary renderer"
check_contains "$JS" 'function renderTicketRows' "ticket table renderer"
check_contains "$JS" 'function ticketSearchText' "ticket search model"
check_contains "$JS" 'function renderTicketFocus' "selected ticket review renderer"
check_contains "$JS" 'function preferredTheme' "theme preference model"
check_contains "$JS" 'Refreshing repository snapshot.' "visible refresh feedback"
check_contains "$JS" 'Viewing' "plain selected-ticket action language"
check_contains "$JS" 'function renderRoles' "role renderer"
check_contains "$JS" 'snapshot.health.missing_evidence' "missing evidence visibility"
check_contains "$JS" 'snapshot.roles' "role snapshot consumption"
check_contains "$JS" 'ticket.next_action' "structured next action consumption"
check_contains "$JS" 'ticket.created_by_role' "ticket creator role visibility"
check_contains "$JS" 'ticket.delegated_to_role' "ticket delegated role visibility"
check_contains "$JS" 'ticket.accepted_by' "ticket acceptance actor visibility"
check_contains "$JS" 'ticket.evidence.has_manifest' "manifest evidence visibility"
check_contains "$JS" 'function makeCopyButton' "copy command control"
check_contains "$JS" 'setAttribute("aria-busy", "true")' "loading busy state"
check_contains "$JS" 'document.body.dataset.health' "stateful health semantics"
check_contains "$JS" 'issue.severity === "blocked"' "blocked severity grading"
check_contains "$JS" '?fresh=1' "manual refresh cache bypass"
check_contains "$JS" 'issues.forEach((issue)' "all health warnings get action rows"
check_contains "$JS" 'Dashboard refreshed. Health' "meaningful live refresh announcement"

check_contains "$SERVER" 'SNAPSHOT_CACHE_TTL' "short-lived snapshot cache"
check_contains "$SERVER" 'query.get("fresh") == ["1"]' "fresh snapshot query bypass"
check_contains "$SERVER" 'target.relative_to(static_root)' "path containment uses Path.relative_to"
check_contains "$SERVER" 'not is_loopback_host(args.host) and not args.unsafe_bind' "non-loopback bind refusal"
check_contains "$SERVER" '"--unsafe-bind"' "explicit unsafe bind override"
check_contains "$SERVER" '"snapshot", "--json"' "server delegates state to palari snapshot"
check_contains "$README" 'split queue/review workbench' "documented dashboard style"
check_contains "$README" 'operator queue with the next allowed action' "documented operator queue"

if grep -Eq 'tickets/open|tickets/closed|frontmatter|palari.config' "$SERVER"; then
	printf 'dashboard-rubric: web server must not parse ticket/config state directly\n' >&2
	exit 1
fi

python3 - "$CSS" <<'PY'
import re
import sys

css_path = sys.argv[1]
css = open(css_path, encoding="utf-8").read()
tokens = dict(re.findall(r"--([a-z-]+):\s*(#[0-9a-fA-F]{6});", css))

def channel(value: int) -> float:
    normalized = value / 255
    if normalized <= 0.03928:
        return normalized / 12.92
    return ((normalized + 0.055) / 1.055) ** 2.4

def luminance(hex_color: str) -> float:
    raw = hex_color.lstrip("#")
    red, green, blue = (int(raw[index:index + 2], 16) for index in (0, 2, 4))
    return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)

def contrast(foreground: str, background: str) -> float:
    first = luminance(foreground)
    second = luminance(background)
    light, dark = max(first, second), min(first, second)
    return (light + 0.05) / (dark + 0.05)

checks = [
    ("ink text", "ink", "surface", 4.5),
    ("muted text", "muted", "surface", 4.5),
    ("subtle text", "subtle", "surface", 4.5),
    ("focus ring", "focus", "surface", 3.0),
    ("green status", "green", "surface", 4.5),
    ("amber status", "amber", "surface", 4.5),
    ("violet status", "violet", "surface", 4.5),
    ("blue status", "blue", "surface", 4.5),
    ("red status", "red", "surface", 4.5),
]

for label, foreground, background, minimum in checks:
    ratio = contrast(tokens[foreground], tokens[background])
    if ratio < minimum:
        raise SystemExit(
            f"dashboard-rubric: {label} contrast {ratio:.2f}:1 is below {minimum}:1"
        )
PY

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
assert "operator" in snapshot
assert "next_action" in snapshot["operator"]
assert "roles" in snapshot
assert "items" in snapshot["roles"]
assert "lint" in snapshot["roles"]
active_tickets = [ticket for ticket in snapshot["tickets"] if ticket["status"] != "accepted"]
assert snapshot["health"]["stale_claims"] <= len(active_tickets)
for ticket in snapshot["tickets"]:
    assert "next_action" in ticket
    assert "created_by_role" in ticket
    assert "delegated_to_role" in ticket
    assert "accepted_by" in ticket
PY

printf 'dashboard-rubric: ok (static layout checks + contrast)\n'
