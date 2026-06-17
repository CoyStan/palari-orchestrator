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
(cd "$SOURCE" &&
	git init -b main >/dev/null &&
	git config user.email "adoption-source@example.invalid" &&
	git config user.name "Adoption Source Test" &&
	git add . &&
	git commit -m "source baseline" >/dev/null)
SOURCE_SHA="$(git -C "$SOURCE" rev-parse HEAD)"

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

if (cd "$SOURCE" && ./bin/palari adopt "$TARGET" --ci --hooks) >"$TMP_ROOT/unplanned-adopt.out" 2>&1; then
	printf 'adoption: expected non-dry-run adopt without approved plan to fail\n' >&2
	exit 1
fi
grep -Fq "adopt requires approved bootstrap/adoption plan before writing target files" "$TMP_ROOT/unplanned-adopt.out"

(cd "$SOURCE" && ./bin/palari adopt plan "$TARGET" --ci --hooks --out "$TMP_ROOT/adoption-plan.md") >"$TMP_ROOT/plan.out"
grep -Fq "adopt plan: $TMP_ROOT/adoption-plan.md" "$TMP_ROOT/plan.out"
test -f "$TMP_ROOT/adoption-plan.md"
grep -Fq "type: bootstrap-adoption-plan" "$TMP_ROOT/adoption-plan.md"
grep -Fq "status: proposed" "$TMP_ROOT/adoption-plan.md"
grep -Fq "source_path: \"$SOURCE\"" "$TMP_ROOT/adoption-plan.md"
grep -Fq "target_path: \"$TARGET\"" "$TMP_ROOT/adoption-plan.md"
grep -Fq "source_sha: \"$SOURCE_SHA\"" "$TMP_ROOT/adoption-plan.md"
grep -Fq "path_manifest:" "$TMP_ROOT/adoption-plan.md"
grep -Fq "  - bin" "$TMP_ROOT/adoption-plan.md"
grep -Fq "  - lib" "$TMP_ROOT/adoption-plan.md"
grep -Fq "excluded_paths:" "$TMP_ROOT/adoption-plan.md"
grep -Fq "downstream_customization_boundaries:" "$TMP_ROOT/adoption-plan.md"
grep -Fq "excluded_foreign_governance_artifacts:" "$TMP_ROOT/adoption-plan.md"

if (cd "$SOURCE" && ./bin/palari adopt "$TARGET" --ci --hooks --plan "$TMP_ROOT/adoption-plan.md") >"$TMP_ROOT/proposed-plan.out" 2>&1; then
	printf 'adoption: expected proposed plan to fail before write\n' >&2
	exit 1
fi
grep -Fq "adopt plan must be approved before writing target files; current status: proposed" "$TMP_ROOT/proposed-plan.out"

cp "$TMP_ROOT/adoption-plan.md" "$TMP_ROOT/missing-approval-plan.md"
sed -i 's/^status: proposed$/status: approved/' "$TMP_ROOT/missing-approval-plan.md"
if (cd "$SOURCE" && ./bin/palari adopt "$TARGET" --ci --hooks --plan "$TMP_ROOT/missing-approval-plan.md") >"$TMP_ROOT/missing-approval-plan.out" 2>&1; then
	printf 'adoption: expected missing approval metadata to fail before write\n' >&2
	exit 1
fi
grep -Fq "adopt plan missing approved_by" "$TMP_ROOT/missing-approval-plan.out"

cp "$TMP_ROOT/adoption-plan.md" "$TMP_ROOT/stale-source-plan.md"
sed -i \
	-e 's/^status: proposed$/status: approved/' \
	-e 's/^source_sha: .*$/source_sha: "0000000000000000000000000000000000000000"/' \
	-e 's/^approved_by:$/approved_by: founder/' \
	-e 's/^approved_at:$/approved_at: 2026-06-17T00:00:00Z/' \
	"$TMP_ROOT/stale-source-plan.md"
if (cd "$SOURCE" && ./bin/palari adopt "$TARGET" --ci --hooks --plan "$TMP_ROOT/stale-source-plan.md") >"$TMP_ROOT/stale-source-plan.out" 2>&1; then
	printf 'adoption: expected stale source plan to fail before write\n' >&2
	exit 1
fi
grep -Fq "adopt plan source_sha mismatch" "$TMP_ROOT/stale-source-plan.out"

cp "$TMP_ROOT/adoption-plan.md" "$TMP_ROOT/force-mismatch-plan.md"
sed -i \
	-e 's/^status: proposed$/status: approved/' \
	-e 's/^approved_by:$/approved_by: founder/' \
	-e 's/^approved_at:$/approved_at: 2026-06-17T00:00:00Z/' \
	"$TMP_ROOT/force-mismatch-plan.md"
if (cd "$SOURCE" && ./bin/palari adopt "$TARGET" --ci --hooks --force --plan "$TMP_ROOT/force-mismatch-plan.md") >"$TMP_ROOT/force-mismatch-plan.out" 2>&1; then
	printf 'adoption: expected force mismatch to fail before write\n' >&2
	exit 1
fi
grep -Fq "adopt plan force mismatch: expected true, got false" "$TMP_ROOT/force-mismatch-plan.out"

cp "$TMP_ROOT/adoption-plan.md" "$TMP_ROOT/ci-mismatch-plan.md"
sed -i \
	-e 's/^status: proposed$/status: approved/' \
	-e 's/^approved_by:$/approved_by: founder/' \
	-e 's/^approved_at:$/approved_at: 2026-06-17T00:00:00Z/' \
	"$TMP_ROOT/ci-mismatch-plan.md"
if (cd "$SOURCE" && ./bin/palari adopt "$TARGET" --hooks --plan "$TMP_ROOT/ci-mismatch-plan.md") >"$TMP_ROOT/ci-mismatch-plan.out" 2>&1; then
	printf 'adoption: expected ci mismatch to fail before write\n' >&2
	exit 1
fi
grep -Fq "adopt plan with_ci mismatch: expected false, got true" "$TMP_ROOT/ci-mismatch-plan.out"

cp "$TMP_ROOT/adoption-plan.md" "$TMP_ROOT/missing-foreign-plan.md"
awk '
	$0 == "excluded_foreign_governance_artifacts:" { skip = 1; next }
	skip && $0 ~ /^downstream_customization_boundaries:/ { skip = 0 }
	!skip { print }
' "$TMP_ROOT/adoption-plan.md" >"$TMP_ROOT/missing-foreign-plan.md"
sed -i \
	-e 's/^status: proposed$/status: approved/' \
	-e 's/^approved_by:$/approved_by: founder/' \
	-e 's/^approved_at:$/approved_at: 2026-06-17T00:00:00Z/' \
	"$TMP_ROOT/missing-foreign-plan.md"
if (cd "$SOURCE" && ./bin/palari adopt "$TARGET" --ci --hooks --plan "$TMP_ROOT/missing-foreign-plan.md") >"$TMP_ROOT/missing-foreign-plan.out" 2>&1; then
	printf 'adoption: expected missing foreign governance artifact list to fail before write\n' >&2
	exit 1
fi
grep -Fq "adopt plan missing excluded_foreign_governance_artifacts entries" "$TMP_ROOT/missing-foreign-plan.out"

sed -i \
	-e 's/^status: proposed$/status: approved/' \
	-e 's/^approved_by:$/approved_by: founder/' \
	-e 's/^approved_at:$/approved_at: 2026-06-17T00:00:00Z/' \
	"$TMP_ROOT/adoption-plan.md"

(cd "$SOURCE" && ./bin/palari adopt "$TARGET" --ci --hooks --plan "$TMP_ROOT/adoption-plan.md") >"$TMP_ROOT/adopt.out"
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

if (cd "$SOURCE" && ./bin/palari adopt "$TARGET" --plan "$TMP_ROOT/missing-plan.md") >"$TMP_ROOT/missing-plan.out" 2>&1; then
	printf 'adoption: expected missing plan to fail\n' >&2
	exit 1
fi
grep -Fq "adopt plan not found: $TMP_ROOT/missing-plan.md" "$TMP_ROOT/missing-plan.out"

printf 'adoption: ok\n'
