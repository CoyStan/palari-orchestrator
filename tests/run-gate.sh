#!/usr/bin/env bash
# End-to-end test of the forge-proof accept gate integration.
#
# Covers: init, ticket setup, the honest implement -> test -> review chain,
# acceptance through the gate, and the refusals that define the boundary:
# forged step authority, tampered evidence, same-key review, gate-enabled
# acceptance blocking, and fail-closed behavior with the gate disabled
# remaining backward compatible.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! python3 -c 'import cryptography' >/dev/null 2>&1; then
	printf 'run-gate: skipped (python3 cryptography unavailable)\n'
	exit 0
fi

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude '.palari' -cf - .) | (cd "$WORK" && tar -xf -)
cd "$WORK"
chmod +x bin/palari scripts/palari
git init -b main >/dev/null
git config user.email "gate@example.invalid"
git config user.name "Gate Test"
./bin/palari init >/dev/null
git add .
git commit -qm "initial"

fail() {
	printf 'run-gate: FAIL %s\n' "$1" >&2
	exit 1
}

expect_fail() {
	local label="$1"
	shift
	if "$@" >"$TMP_ROOT/out" 2>&1; then
		cat "$TMP_ROOT/out" >&2
		fail "$label (command unexpectedly succeeded)"
	fi
}

expect_ok() {
	local label="$1"
	shift
	if ! "$@" >"$TMP_ROOT/out" 2>&1; then
		cat "$TMP_ROOT/out" >&2
		fail "$label"
	fi
}

out_contains() {
	grep -Fq -- "$1" "$TMP_ROOT/out" || {
		cat "$TMP_ROOT/out" >&2
		fail "expected output to contain: $1"
	}
}

# --- 1. Backward compatibility: gate disabled changes nothing -------------
expect_ok "snapshot carries a gate section while disabled" ./bin/palari snapshot --json
out_contains '"gate"'
out_contains '"enabled": false'

# --- 2. Enable the gate and initialize keys --------------------------------
python3 - <<'PY'
import re
text = open('palari.config.yaml', encoding='utf-8').read()
text = re.sub(r'(?m)^(gate:\n(?:.*\n)*?  enabled:) false', r'\1 true', text)
open('palari.config.yaml', 'w', encoding='utf-8').write(text)
PY
grep -Eq '^  enabled: true' palari.config.yaml || fail "could not enable gate in config"
git add palari.config.yaml
git commit -qm "enable forge-proof gate"

expect_ok "gate init creates keys" ./bin/palari gate init
out_contains 'root key created'
[[ -f .palari/gate/root.pub ]] || fail "root public key missing"
[[ -f .palari/gate/keys/root.key ]] || fail "root private key missing"
git check-ignore -q .palari/gate/keys/root.key || fail "private keys are not gitignored"

# --- 3. Fail closed: accept refuses without attestations -------------------
expect_ok "ticket create" ./bin/palari ticket create GTE-0001 "Gate happy path" \
	--stream docs --risk R1 \
	--allowed "docs/**" --allowed "tickets/**" --allowed "reports/**" \
	--verify "manual gate flow check"
expect_ok "claim" ./bin/palari ticket claim GTE-0001 implementer --allow-overlap
expect_ok "ci evidence" ./bin/palari ci GTE-0001
out_contains 'no ci token for GTE-0001'
expect_ok "ready" ./bin/palari ticket ready GTE-0001
expect_fail "accept refused without signed chain" ./bin/palari accept GTE-0001 --by founder
out_contains 'forge-proof gate refused'

# --- 4. Honest chain --------------------------------------------------------
expect_ok "setup-ticket grants three tokens" ./bin/palari gate setup-ticket GTE-0001
out_contains "implementer may attest 'implement'"
out_contains "ci may attest 'test'"
out_contains "reviewer may attest 'review'"

mkdir -p docs && printf 'governed change\n' >docs/gate-demo.md
git add docs/gate-demo.md
git commit -qm "GTE-0001 governed change"

expect_ok "attest implement" ./bin/palari gate attest-implement GTE-0001
expect_ok "ci auto-attests test" ./bin/palari ci GTE-0001
out_contains 'gate attest: test on GTE-0001 signed by ci'
expect_fail "verify refused before review" ./bin/palari gate verify GTE-0001
out_contains 'review: required step has no attestation'
expect_ok "attest review" ./bin/palari gate attest-review GTE-0001
expect_ok "verify accepts the honest chain" ./bin/palari gate verify GTE-0001
out_contains 'ACCEPTED'

# --- 5. The canonical forgery: implementer cannot pass the test step -------
# Fail fast at the adapter: the implementer token is implement-scoped.
expect_fail "adapter refuses an out-of-scope attest" ./bin/palari gate attest \
	--ticket GTE-0001 --step test --key implementer \
	--consumes implement \
	--output "manifest=reports/evidence/GTE-0001/manifest.json"
out_contains 'does not authorize'

# The real boundary: forge the attestation directly (an attacker holding the
# implementer key does not use the adapter), and the gate refuses it.
ATT_DIR="reports/evidence/GTE-0001/gate/attestations"
HONEST_TEST="$(grep -l '"step": "test"' "$ATT_DIR"/*.json | head -1)"
[[ -n "$HONEST_TEST" ]] || fail "could not locate the honest test attestation"
cp "$HONEST_TEST" "$TMP_ROOT/honest-test.json"
python3 - "$ATT_DIR" "$HONEST_TEST" <<'PY'
import json, sys
sys.path.insert(0, 'gate')
from forgegate import attest as att_mod
from forgegate.keys import Key
from forgegate.attest import att_id

att_dir, honest_path = sys.argv[1], sys.argv[2]
honest = json.load(open(honest_path, encoding='utf-8'))
key = Key.from_hex(open('.palari/gate/keys/implementer.key', encoding='utf-8').read().strip())
token = json.load(open('.palari/gate/keys/implementer-GTE-0001.token.json', encoding='utf-8'))
forged = att_mod.create(
    key, token, 'test', honest['ticket'], honest['branch'],
    dict(honest['inputs']), dict(honest['outputs']), honest['commit'],
)
import os
os.remove(honest_path)
out = f"{att_dir}/{att_id(forged)}.json"
json.dump(forged, open(out, 'w', encoding='utf-8'), indent=1, sort_keys=True)
print(out)
PY
expect_fail "forged test step refused by the gate" ./bin/palari gate verify GTE-0001
out_contains 'token scope does not authorize this step'
rm -f "$ATT_DIR"/*.json
cp "$TMP_ROOT/honest-test.json" "$ATT_DIR/restore-test.json"
# Rebuild the rest of the honest chain around the restored test attestation.
expect_ok "re-attest implement after forgery cleanup" ./bin/palari gate attest-implement GTE-0001
expect_ok "re-attest review after forgery cleanup" ./bin/palari gate attest-review GTE-0001
expect_ok "honest chain verifies after forgery cleanup" ./bin/palari gate verify GTE-0001

# Delegation can narrow authority, never widen it: attenuating the
# implement-scoped token to a test scope must be refused by the kernel.
python3 - <<'PY'
import json, sys
sys.path.insert(0, 'gate')
from forgegate import token as tok
from forgegate.keys import Key

key = Key.from_hex(open('.palari/gate/keys/implementer.key', encoding='utf-8').read().strip())
token = json.load(open('.palari/gate/keys/implementer-GTE-0001.token.json', encoding='utf-8'))
target = Key.generate()
widened = tok.scope('GTE-0001', token[-1]['scope']['branch'], ['test'],
                    token[-1]['scope']['not_after'])
try:
    tok.attenuate(token, key, target.public_hex, widened)
except ValueError as exc:
    assert 'never widen' in str(exc), exc
    print('widening refused:', exc)
else:
    raise SystemExit('widening was not refused')
PY

# --- 6. Tampering invalidates signatures ------------------------------------
ATT_DIR="reports/evidence/GTE-0001/gate/attestations"
TAMPER_TARGET="$(grep -l '"step": "test"' "$ATT_DIR"/*.json | head -1)"
[[ -n "$TAMPER_TARGET" ]] || fail "could not locate the test attestation"
cp "$TAMPER_TARGET" "$TMP_ROOT/test-att.json"
python3 - "$TAMPER_TARGET" <<'PY'
import json, sys
path = sys.argv[1]
att = json.load(open(path, encoding='utf-8'))
att['outputs']['manifest.json'] = '0' * 64
json.dump(att, open(path, 'w', encoding='utf-8'), indent=1, sort_keys=True)
PY
expect_fail "tampered attestation refused" ./bin/palari gate verify GTE-0001
out_contains 'signature invalid'
cp "$TMP_ROOT/test-att.json" "$TAMPER_TARGET"
expect_ok "restored chain verifies again" ./bin/palari gate verify GTE-0001

# --- 7. Dual control: review by the implementer key is refused -------------
expect_ok "grant implementer key a review token" ./bin/palari gate grant \
	--ticket GTE-0001 --holder implementer --steps review
expect_ok "implementer signs review (supersedes honest review)" \
	./bin/palari gate attest-review GTE-0001 --key implementer
expect_fail "same-key review refused" ./bin/palari gate verify GTE-0001
out_contains "must be signed by a different key"
expect_ok "fresh reviewer key restores the chain" ./bin/palari gate attest-review GTE-0001

# --- 8. Acceptance through the gate ----------------------------------------
expect_ok "accept succeeds on a verified chain" ./bin/palari accept GTE-0001 --by founder
out_contains 'ACCEPTED by the forge-proof gate'
out_contains 'accept: GTE-0001 accepted by founder'

# --- 9. Snapshot carries the verdict ----------------------------------------
expect_ok "snapshot includes gate verdict" ./bin/palari snapshot --json
python3 - "$TMP_ROOT/out" <<'PY'
import json, sys
snapshot = json.load(open(sys.argv[1], encoding='utf-8'))
gate = snapshot["gate"]
assert gate["enabled"] is True, gate
assert gate["available"] is True, gate
assert gate["initialized"] is True, gate
assert gate["root_fingerprint"], gate
ticket = gate["tickets"]["GTE-0001"]
assert ticket["verdict"]["accepted"] is True, ticket
steps = ticket["steps"]
assert steps["implement"]["attested"] and steps["test"]["attested"] and steps["review"]["attested"], steps
assert steps["review"]["signer"] != steps["implement"]["signer"], steps
PY

# --- 10. Fail closed when the kernel disappears -----------------------------
expect_ok "second ticket" ./bin/palari ticket create GTE-0003 "Fail closed" \
	--stream docs --risk R1 --allowed "tickets/**" --allowed "reports/**" \
	--verify "manual fail closed check"
expect_ok "claim second" ./bin/palari ticket claim GTE-0003 implementer --allow-overlap
expect_ok "ci second" ./bin/palari ci GTE-0003
expect_ok "ready second" ./bin/palari ticket ready GTE-0003
mv gate/forgegate "$TMP_ROOT/forgegate-hidden"
expect_fail "accept fails closed without the kernel" ./bin/palari accept GTE-0003 --by founder
out_contains 'fails closed'
mv "$TMP_ROOT/forgegate-hidden" gate/forgegate

printf 'run-gate: ok (honest chain accepted; forgery, tamper, same-key review, and missing-kernel acceptance refused)\n'
