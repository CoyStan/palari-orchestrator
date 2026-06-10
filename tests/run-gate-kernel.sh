#!/usr/bin/env bash
# Runs the vendored forgegate kernel's adversarial test suite in place.
# The kernel is the trusted computing base of signed acceptance; its suite
# is one honest path that must be accepted and a battery of attacks that
# must each be refused for the right reason.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! python3 -c 'import cryptography' >/dev/null 2>&1; then
	printf 'run-gate-kernel: skipped (python3 cryptography unavailable)\n'
	exit 0
fi

cd "$ROOT/gate"
python3 -m unittest discover tests
printf 'run-gate-kernel: ok\n'
