#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC="$ROOT/docs/autonomy/queue-runner-dry-run.md"

fail() {
	printf 'autonomy-spec: %s\n' "$*" >&2
	exit 1
}

[[ -s "$SPEC" ]] || fail "missing queue runner dry-run spec"

require_text() {
	local text="$1"
	grep -Fq "$text" "$SPEC" || fail "spec missing: $text"
}

require_text 'palari run --dry-run --until blocked'
require_text 'Dry-run mode is intentionally read-only'
require_text 'does not claim'
require_text 'spawn agents'
require_text 'accept work'
require_text 'commit, push, merge'
require_text 'human acceptance'
require_text 'credentials, secrets'
require_text 'production access or deploy'
require_text 'unclear authority, scope, ownership, or risk'
require_text 'tickets skipped and why'
require_text 'human-readable and machine-readable'
require_text 'claim and isolate one ticket at a time'
require_text 'move tickets to review only after evidence passes'
require_text 'bypass ForgeGate or evidence checks'

printf 'autonomy-spec: ok\n'
