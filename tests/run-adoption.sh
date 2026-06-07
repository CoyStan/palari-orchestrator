#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

SOURCE="$TMP_ROOT/source"
TARGET="$TMP_ROOT/target"
DRY_TARGET="$TMP_ROOT/dry-target"
mkdir -p "$SOURCE" "$TARGET" "$DRY_TARGET"

(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$SOURCE" && tar -xf -)

chmod +x "$SOURCE/bin/palari" "$SOURCE/scripts/palari" "$SOURCE/tests/run-adoption.sh"

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

(cd "$SOURCE" && ./bin/palari adopt "$DRY_TARGET" --dry-run) >"$TMP_ROOT/dry-run.out" 2>"$TMP_ROOT/dry-run.err" || true
grep -Fq "adopt target must be an existing git repository" "$TMP_ROOT/dry-run.err"
test ! -e "$DRY_TARGET/bin"

(cd "$SOURCE" && ./bin/palari adopt "$TARGET" --ci --hooks) >"$TMP_ROOT/adopt.out"
grep -Fq "adopt: source $SOURCE" "$TMP_ROOT/adopt.out"
grep -Fq "adopt: target $TARGET" "$TMP_ROOT/adopt.out"
grep -Fq "adopt: kept existing AGENTS.md" "$TMP_ROOT/adopt.out"
grep -Fq "adopt: write AGENTS.palari.md for merge" "$TMP_ROOT/adopt.out"
grep -Fq "doctor: ok" "$TMP_ROOT/adopt.out"
grep -Fq "adopt: ok" "$TMP_ROOT/adopt.out"
grep -Fq "./bin/palari propose create APP-PROP-0001" "$TMP_ROOT/adopt.out"
grep -Fq "./bin/palari github ruleset-command --repo OWNER/REPO" "$TMP_ROOT/adopt.out"

test -x bin/palari
test -x scripts/palari
test -f palari.config.yaml
test -f AGENTS.md
test -f AGENTS.palari.md
test -f contracts/adoption.md
test -f skills/adoption/SKILL.md
test -f templates/proposal.md
test -d tickets/proposed
test -d reports/planning
test -f reports/evidence/.gitkeep
test -f .github/workflows/palari.yml
test -f .github/palari-required-checks.ruleset.json
test -f lefthook.yml

grep -Fq "# Existing Agent Contract" AGENTS.md
grep -Fq "# Palari Orchestration Agent Template" AGENTS.palari.md

./bin/palari doctor >"$TMP_ROOT/doctor.out"
grep -Fq "Palari adoption doctor" "$TMP_ROOT/doctor.out"
grep -Fq "doctor: ok executable bin/palari" "$TMP_ROOT/doctor.out"
grep -Fq "doctor: ok file contracts/adoption.md" "$TMP_ROOT/doctor.out"
grep -Fq "doctor: ok file skills/adoption/SKILL.md" "$TMP_ROOT/doctor.out"
grep -Fq "doctor: ok" "$TMP_ROOT/doctor.out"

./bin/palari status >"$TMP_ROOT/status.out"
grep -Fq "Palari Orchestration status" "$TMP_ROOT/status.out"

(cd "$SOURCE" && ./bin/palari adopt "$TARGET" --dry-run) >"$TMP_ROOT/re-adopt-dry-run.out"
grep -Fq "adopt: kept existing bin" "$TMP_ROOT/re-adopt-dry-run.out"
grep -Fq "adopt: kept existing AGENTS.palari.md" "$TMP_ROOT/re-adopt-dry-run.out"
grep -Fq "adopt: dry-run complete" "$TMP_ROOT/re-adopt-dry-run.out"

printf 'adoption: ok\n'
