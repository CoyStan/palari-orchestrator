#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

SOURCE="$TMP_ROOT/source"
TARGET="$TMP_ROOT/target"
SESSION_TARGET="$TMP_ROOT/session-target"
DRY_TARGET="$TMP_ROOT/dry-target"
mkdir -p "$SOURCE" "$TARGET" "$SESSION_TARGET" "$DRY_TARGET"

(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$SOURCE" && tar -xf -)

chmod +x "$SOURCE/bin/palari" "$SOURCE/scripts/palari" "$SOURCE/tests/run-adoption.sh"
grep -Fq -- "--governance-only" "$SOURCE/plugin/commands/adopt.md"
grep -Fq "governance session" "$SOURCE/plugin/commands/adopt.md"
grep -Fq -- "--governance-only" "$SOURCE/skills/adoption/SKILL.md"

cd "$TARGET"
git init -b main >/dev/null
git config user.email "adoption@example.invalid"
git config user.name "Adoption Test"
cat >README.md <<'DOC'
# Target Repo
DOC
cat >AGENTS.md <<'DOC'
# Existing Agent Contract

Keep this file.
DOC
git add README.md AGENTS.md
git commit -m "target baseline" >/dev/null

cd "$SESSION_TARGET"
git init -b main >/dev/null
git config user.email "session@example.invalid"
git config user.name "Session Test"
cat >README.md <<'DOC'
# Session Target Repo
DOC
cat >AGENTS.md <<'DOC'
# Existing Session Agent Contract

Keep this file too.
DOC
git add README.md AGENTS.md
git commit -m "session target baseline" >/dev/null

(cd "$SOURCE" && ./bin/palari adopt "$DRY_TARGET" --dry-run) >"$TMP_ROOT/dry-run.out" 2>"$TMP_ROOT/dry-run.err" || true
grep -Fq "adopt target must be an existing git repository" "$TMP_ROOT/dry-run.err"
test ! -e "$DRY_TARGET/bin"

(cd "$TARGET" && "$SOURCE/bin/palari" adopt "$TARGET" --dry-run) >"$TMP_ROOT/external-from-target.out"
grep -Fq "adopt: source $SOURCE" "$TMP_ROOT/external-from-target.out"
grep -Fq "adopt: target $TARGET" "$TMP_ROOT/external-from-target.out"
grep -Fq "adopt: dry-run complete" "$TMP_ROOT/external-from-target.out"

(cd "$TMP_ROOT" && "$SOURCE/bin/palari" adopt "$TARGET" --dry-run) >"$TMP_ROOT/external-from-tmp.out"
grep -Fq "adopt: source $SOURCE" "$TMP_ROOT/external-from-tmp.out"
grep -Fq "adopt: target $TARGET" "$TMP_ROOT/external-from-tmp.out"
grep -Fq "adopt: dry-run complete" "$TMP_ROOT/external-from-tmp.out"

(cd "$TARGET" && "$SOURCE/scripts/palari" adopt "$TARGET" --dry-run) >"$TMP_ROOT/wrapper-from-target.out"
grep -Fq "adopt: source $SOURCE" "$TMP_ROOT/wrapper-from-target.out"
grep -Fq "adopt: target $TARGET" "$TMP_ROOT/wrapper-from-target.out"
grep -Fq "adopt: dry-run complete" "$TMP_ROOT/wrapper-from-target.out"

(cd "$SOURCE" && ./bin/palari adopt "$SESSION_TARGET" --governance-only) >"$TMP_ROOT/session-adopt.out"
grep -Fq "adopt: mode governance-only" "$TMP_ROOT/session-adopt.out"
grep -Fq "adopt: ok governance-only" "$TMP_ROOT/session-adopt.out"
grep -Fq "PALARI_ROOT=" "$TMP_ROOT/session-adopt.out"

cd "$SESSION_TARGET"
test -f palari.config.yaml
test -f AGENTS.md
test -f AGENTS.palari.md
test -d tickets/proposed
test -d tickets/open
test -d tickets/closed
test -d reports
test -d reports/evidence
test -d goals/active
test -d decisions/open
test -d workflows/active
test -d humans/active
test -f reports/evidence/.gitkeep
grep -Fq "mode: governance-only" palari.config.yaml
grep -Fq "Do not copy upstream Palari internals" AGENTS.palari.md
grep -Fq "# Existing Session Agent Contract" AGENTS.md
grep -Fxq ".palari/" .gitignore
test ! -e bin
test ! -e lib
test ! -e scripts
test ! -e templates
test ! -e contracts
test ! -e skills
test ! -e schemas
test ! -e adapters
test ! -e gate
test ! -e layouts
test ! -e examples
test ! -e research
test ! -e vendor
test ! -e tests
test ! -e .claude-plugin
test ! -e reports/POS-0009-technical-report.md
test ! -e reports/COS-0000-technical-report.md
PALARI_ROOT="$SESSION_TARGET" PALARI_LIB_DIR="$SOURCE/lib/palari" "$SOURCE/bin/palari" status >"$TMP_ROOT/session-status.out"
grep -Fq "Palari Orchestration status" "$TMP_ROOT/session-status.out"

if (cd "$SOURCE" && ./bin/palari adopt "$SESSION_TARGET" --governance-only --ci) >"$TMP_ROOT/session-ci.out" 2>"$TMP_ROOT/session-ci.err"; then
	printf 'adoption: expected governance-only --ci to fail\n' >&2
	exit 1
fi
grep -Fq "adopt --governance-only cannot install CI" "$TMP_ROOT/session-ci.err"

(cd "$SOURCE" && ./bin/palari adopt "$TARGET" --ci --hooks) >"$TMP_ROOT/adopt.out"
grep -Fq "adopt: source $SOURCE" "$TMP_ROOT/adopt.out"
grep -Fq "adopt: target $TARGET" "$TMP_ROOT/adopt.out"
grep -Fq "adopt: kept existing AGENTS.md" "$TMP_ROOT/adopt.out"
grep -Fq "adopt: write AGENTS.palari.md for merge" "$TMP_ROOT/adopt.out"
grep -Fq "doctor: ok" "$TMP_ROOT/adopt.out"
grep -Fq "adopt: ok" "$TMP_ROOT/adopt.out"
grep -Fq "./bin/palari propose create APP-PROP-0001" "$TMP_ROOT/adopt.out"
grep -Fq "./bin/palari github ruleset-command --repo OWNER/REPO" "$TMP_ROOT/adopt.out"

cd "$TARGET"
test -x bin/palari
test -x scripts/palari
test -f lib/palari/core.bash
test -f lib/palari/roles.bash
test -f lib/palari/init_adopt.bash
test -f palari.config.yaml
test -f AGENTS.md
test -f AGENTS.palari.md
test -f contracts/adoption.md
test -f skills/adoption/SKILL.md
test -f templates/proposal.md
test -d tickets/proposed
test -d roles/active
test -d roles/proposed
test -d roles/revoked
test -f roles/active/ROLE-ROOT.md
test -d reports/planning
test -f reports/evidence/.gitkeep
test -f .github/workflows/palari.yml
test -f .github/palari-required-checks.ruleset.json
test -f lefthook.yml
grep -Fxq ".palari/" .gitignore
grep -Fxq "__pycache__/" .gitignore
grep -Fxq "*.pyc" .gitignore
grep -Fxq ".expo/" .gitignore
grep -Fxq ".metro/" .gitignore
grep -Fxq "node_modules/" .gitignore

grep -Fq "# Existing Agent Contract" AGENTS.md
grep -Fq "# Palari Orchestration Agent Template" AGENTS.palari.md

./bin/palari doctor >"$TMP_ROOT/doctor.out"
grep -Fq "Palari adoption doctor" "$TMP_ROOT/doctor.out"
grep -Fq "doctor: ok executable bin/palari" "$TMP_ROOT/doctor.out"
grep -Fq "doctor: ok file lib/palari/core.bash" "$TMP_ROOT/doctor.out"
grep -Fq "doctor: ok file lib/palari/roles.bash" "$TMP_ROOT/doctor.out"
grep -Fq "doctor: ok file contracts/adoption.md" "$TMP_ROOT/doctor.out"
grep -Fq "doctor: ok file skills/adoption/SKILL.md" "$TMP_ROOT/doctor.out"
grep -Fq "doctor: ok" "$TMP_ROOT/doctor.out"

./bin/palari status >"$TMP_ROOT/status.out"
grep -Fq "Palari Orchestration status" "$TMP_ROOT/status.out"

(cd "$SOURCE" && ./bin/palari adopt "$TARGET" --dry-run) >"$TMP_ROOT/re-adopt-dry-run.out"
grep -Fq "adopt: kept existing bin" "$TMP_ROOT/re-adopt-dry-run.out"
grep -Fq "adopt: kept existing lib" "$TMP_ROOT/re-adopt-dry-run.out"
grep -Fq "adopt: kept existing AGENTS.palari.md" "$TMP_ROOT/re-adopt-dry-run.out"
grep -Fq "adopt: dry-run complete" "$TMP_ROOT/re-adopt-dry-run.out"

printf 'adoption: ok\n'
