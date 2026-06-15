#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'cd /; rm -rf "$TMP_ROOT" || true' EXIT

fail() {
	printf 'openrouter: %s\n' "$*" >&2
	exit 1
}

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"
(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari scripts/palari
rm -f tickets/open/*.md tickets/closed/*.md reports/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/* goals decisions
mkdir -p goals/active decisions/open decisions/decided tickets/closed

git init -b main >/dev/null
git config user.email "or@example.invalid"
git config user.name "OpenRouter Test"
git add .
git commit -m "openrouter baseline" >/dev/null

# Enable openrouter and map classes to models.
python3 - <<'PY'
text = open('palari.config.yaml', encoding='utf-8').read()
text = text.replace('openrouter_enabled: false', 'openrouter_enabled: true')
text = text.replace('# model_fast_openrouter: deepseek/deepseek-chat', 'model_fast_openrouter: deepseek/deepseek-chat')
text = text.replace('# openrouter_advisor_model: anthropic/claude-fable-5', 'openrouter_advisor_model: anthropic/claude-fable-5')
open('palari.config.yaml', 'w', encoding='utf-8').write(text)
PY

./bin/palari ticket create ORT-0001 "Draft release notes" --risk R1 \
	--allowed "docs/**" --verify "true" >/dev/null
git add -A >/dev/null && git commit -qm tickets >/dev/null
./bin/palari ticket claim ORT-0001 tester >/dev/null
git add -A >/dev/null && git commit -qm claim >/dev/null
./bin/palari worktree ORT-0001 >/dev/null

# Routing resolves R1 -> fast -> the openrouter mapping.
./bin/palari model show ORT-0001 --executor openrouter >"$TMP_ROOT/show.out"
grep -Fq "resolved model: deepseek/deepseek-chat" "$TMP_ROOT/show.out" ||
	fail "routing did not resolve the openrouter fast model"

# OpenRouter is model supply only; Palari keeps authority and routing governance.
grep -Fq "OpenRouter remains model supply, not governance." contracts/adapters.md ||
	fail "OpenRouter must remain model supply, not governance"
grep -Fq "but it must not own" contracts/adapters.md ||
	fail "OpenRouter must not own Palari routing authority"
grep -Fq "Palari's routing authority" contracts/adapters.md ||
	fail "OpenRouter contract must name Palari routing authority"
grep -Fq "side-effecting model integration" contracts/adapters.md ||
	fail "contract must not add side-effecting model integration"

# Dry-run prints executor, routed model, and redacted command; no network.
./bin/palari agent run ORT-0001 --executor openrouter --dry-run >"$TMP_ROOT/dry.out"
grep -Fq "executor: openrouter" "$TMP_ROOT/dry.out" || fail "dry-run missing executor"
grep -Fq "deepseek/deepseek-chat (routed)" "$TMP_ROOT/dry.out" || fail "dry-run missing routed model"
grep -Fq "never edits files" "$TMP_ROOT/dry.out" || fail "dry-run missing text-artifact note"

# Adapter dry-run payload includes deterministic settings and the advisor tool.
python3 -B adapters/openrouter/run.py --root . --ticket ORT-0001 \
	--model deepseek/deepseek-chat --dry-run >"$TMP_ROOT/payload.json"
python3 - "$TMP_ROOT/payload.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
payload = data["payload"]
assert payload["model"] == "deepseek/deepseek-chat"
assert payload["temperature"] == 0.0
assert payload["seed"] == 7
tools = payload.get("tools") or []
assert tools and tools[0]["type"] == "openrouter:advisor", tools
assert tools[0]["parameters"]["model"] == "anthropic/claude-fable-5"
PY

# Allowlist is fail-closed: a model outside the list is refused.
if python3 -B adapters/openrouter/run.py --root . --ticket ORT-0001 \
	--model vendor/unlisted-model --dry-run >/dev/null 2>"$TMP_ROOT/refuse.err"; then
	fail "unlisted model should be refused"
fi
grep -Fq "not in openrouter_allowed_models" "$TMP_ROOT/refuse.err" ||
	fail "refusal message missing allowlist reason"

# Missing API key fails closed with the env var name (no key in repo).
if PALARI_OPENROUTER_TRANSPORT="" OPENROUTER_API_KEY="" python3 -B adapters/openrouter/run.py \
	--root . --model deepseek/deepseek-chat >/dev/null 2>"$TMP_ROOT/key.err"; then
	fail "missing key should fail closed"
fi
grep -Fq "OPENROUTER_API_KEY" "$TMP_ROOT/key.err" || fail "missing-key message should name the env var"

git add -A >/dev/null && git commit -qm "pre-run state" >/dev/null || true

# Full executor run against the offline fake transport writes evidence.
cat >"$TMP_ROOT/fake-response.json" <<'JSON'
{
  "choices": [{"message": {"role": "assistant", "content": "Release notes draft: governed work, instant snapshots."}}],
  "usage": {"prompt_tokens": 1200, "completion_tokens": 180, "total_tokens": 1380}
}
JSON
wt="$(dirname "$WORK")/palari-orchestrator-worktrees/ORT-0001"
git -C "$wt" status --porcelain >"$TMP_ROOT/wt.status" || true
git -C "$wt" add -A >/dev/null 2>&1 && git -C "$wt" commit -qm "worktree pre-run" >/dev/null 2>&1 || true
PALARI_OPENROUTER_TRANSPORT="file:$TMP_ROOT/fake-response.json" \
	./bin/palari agent run ORT-0001 --executor openrouter --no-gates >"$TMP_ROOT/run.out" 2>&1 ||
	fail "executor run with fake transport failed: $(cat "$TMP_ROOT/run.out") | wt: $(cat "$TMP_ROOT/wt.status")"

worktree="$(dirname "$WORK")/$(basename "$WORK")"
evdir="$(find "$TMP_ROOT" -path "*reports/evidence/ORT-0001/executor/openrouter" -type d | head -1)"
[[ -n "$evdir" ]] || evdir="$(find / -maxdepth 6 -path "*worktrees*/ORT-0001/reports/evidence/ORT-0001/executor/openrouter" -type d 2>/dev/null | head -1)"
[[ -n "$evdir" ]] || fail "executor evidence directory not found"
grep -Fq "Release notes draft" "$evdir/run.stdout" || fail "run.stdout missing model output"
[[ -f "$evdir/request.json" ]] || fail "request.json missing from evidence"
grep -rq "Bearer" "$evdir" && fail "API key material leaked into evidence"
python3 - "$evdir/usage.json" <<'PY'
import json, sys
usage = json.load(open(sys.argv[1]))
assert usage["model"] == "deepseek/deepseek-chat"
assert usage["usage"]["total_tokens"] == 1380
PY
grep -Fq "model: deepseek/deepseek-chat" "$evdir/model.txt" || fail "model.txt missing routed model"

printf 'openrouter: ok\n'
