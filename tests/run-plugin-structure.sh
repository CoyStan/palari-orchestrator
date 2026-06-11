#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
	printf 'plugin-structure: %s\n' "$*" >&2
	exit 1
}

# Marketplace manifest: valid JSON with required fields, plugin source exists.
MARKET="$ROOT/.claude-plugin/marketplace.json"
[[ -f "$MARKET" ]] || fail "missing .claude-plugin/marketplace.json"
python3 - "$ROOT" <<'PYEOF'
import json, os, sys
root = sys.argv[1]
m = json.load(open(os.path.join(root, ".claude-plugin/marketplace.json")))
assert m.get("name"), "marketplace name missing"
assert m.get("owner", {}).get("name"), "marketplace owner missing"
plugins = m.get("plugins")
assert isinstance(plugins, list) and plugins, "marketplace plugins list missing"
for p in plugins:
    assert p.get("name") and p.get("source") and p.get("description"), f"incomplete plugin entry: {p}"
    src = os.path.join(root, p["source"])
    assert os.path.isdir(src), f"plugin source missing: {p['source']}"
    manifest = os.path.join(src, ".claude-plugin/plugin.json")
    pm = json.load(open(manifest))
    assert pm.get("name") == p["name"], "plugin.json name mismatch with marketplace entry"
    assert pm.get("description") and pm.get("version"), "plugin.json missing description/version"
print("manifests ok")
PYEOF

PLUGIN="$ROOT/plugin"

# Skill: frontmatter with name and description.
SKILL="$PLUGIN/skills/palari-orchestrator/SKILL.md"
[[ -f "$SKILL" ]] || fail "missing plugin skill"
head -1 "$SKILL" | grep -qx -- '---' || fail "skill missing frontmatter"
grep -q '^name: palari-orchestrator$' "$SKILL" || fail "skill frontmatter missing name"
grep -q '^description: ' "$SKILL" || fail "skill frontmatter missing description"

# Commands: each has a description frontmatter and references bin/palari.
count=0
for cmd in "$PLUGIN"/commands/*.md; do
	[[ -f "$cmd" ]] || fail "no command files"
	head -1 "$cmd" | grep -qx -- '---' || fail "$(basename "$cmd") missing frontmatter"
	grep -q '^description: ' "$cmd" || fail "$(basename "$cmd") missing description"
	grep -Fq 'bin/palari' "$cmd" || fail "$(basename "$cmd") does not reference the palari CLI"
	count=$((count + 1))
done
((count >= 6)) || fail "expected at least 6 commands, found $count"

# Agents: frontmatter name/description; reviewer never accepts, specialist never reviews itself.
for agent in palari-reviewer palari-specialist; do
	file="$PLUGIN/agents/$agent.md"
	[[ -f "$file" ]] || fail "missing agent $agent"
	grep -q "^name: $agent$" "$file" || fail "$agent missing frontmatter name"
	grep -q '^description: ' "$file" || fail "$agent missing frontmatter description"
done
grep -Fqi "never run accept" "$PLUGIN/commands/review.md" || fail "review command must forbid accept"
grep -Fqi 'never review your own work' "$PLUGIN/agents/palari-specialist.md" ||
	fail "specialist must forbid self-review"
grep -Fqi 'do not accept' "$PLUGIN/agents/palari-reviewer.md" || fail "reviewer must forbid accept"

# Codex adapter present and syntactically valid.
[[ -x "$ROOT/adapters/codex/install.sh" ]] || fail "codex install.sh missing or not executable"
bash -n "$ROOT/adapters/codex/install.sh"
for p in palari-next palari-ticket palari-review palari-decide; do
	[[ -s "$ROOT/adapters/codex/prompts/$p.md" ]] || fail "codex prompt missing: $p"
done

printf 'plugin-structure: ok\n'
