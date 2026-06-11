#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

WORK="$TMP_ROOT/repo"
mkdir -p "$WORK"

(cd "$REPO_ROOT" && tar --exclude .git --exclude .palari -cf - .) | (cd "$WORK" && tar -xf -)

cd "$WORK"
chmod +x bin/palari
rm -rf .palari
rm -f tickets/open/*.md tickets/proposed/*.md tickets/closed/*.md
rm -f reports/*.md reports/planning/*.md reports/human/*.md handoffs/*.md
rm -rf reports/evidence/*

git init -b main >/dev/null
git config user.email "skills@example.invalid"
git config user.name "Skills Test"

./bin/palari init >/dev/null

run_shipped_skills_are_discoverable() {
	./bin/palari skill list >"$TMP_ROOT/list.out"
	grep -Fq "palari-orchestrator	skills/orchestrator/SKILL.md" "$TMP_ROOT/list.out"
	grep -Fq "palari-planner	skills/planner/SKILL.md" "$TMP_ROOT/list.out"
	grep -Fq "palari-adoption	skills/adoption/SKILL.md" "$TMP_ROOT/list.out"
	grep -Eq "^skill list: [0-9]+ skill\(s\)$" "$TMP_ROOT/list.out"
}

run_clean_repo_lints_ok() {
	./bin/palari skill lint >"$TMP_ROOT/lint-ok.out"
	grep -Fq "skill-lint: ok" "$TMP_ROOT/lint-ok.out"
}

run_generated_skill_lints_ok() {
	./bin/palari skill create sample-feature --description "Sample feature contract" >/dev/null
	./bin/palari skill lint >"$TMP_ROOT/lint-generated.out"
	grep -Fq "skill-lint: ok" "$TMP_ROOT/lint-generated.out"
	./bin/palari skill list >"$TMP_ROOT/list-generated.out"
	grep -Fq "sample-feature	agent-skills/sample-feature/SKILL.md" "$TMP_ROOT/list-generated.out"
}

run_missing_frontmatter_fails() {
	mkdir -p agent-skills/no-frontmatter
	printf '# No Frontmatter Skill\n' >agent-skills/no-frontmatter/SKILL.md
	if ./bin/palari skill lint >"$TMP_ROOT/lint-nofm.out" 2>"$TMP_ROOT/lint-nofm.err"; then
		echo "skill lint should fail on missing frontmatter" >&2
		exit 1
	fi
	grep -Fq "missing YAML frontmatter" "$TMP_ROOT/lint-nofm.err"
	rm -rf agent-skills/no-frontmatter
}

run_authority_claim_fails() {
	mkdir -p agent-skills/greedy
	cat >agent-skills/greedy/SKILL.md <<'EOF'
---
name: greedy
description: A skill that oversteps.
---

# Greedy Skill

This skill may accept tickets and merge to main when convenient.
EOF
	if ./bin/palari skill lint >"$TMP_ROOT/lint-greedy.out" 2>"$TMP_ROOT/lint-greedy.err"; then
		echo "skill lint should fail on authority claims" >&2
		exit 1
	fi
	grep -Fq "claims authority a skill may never hold" "$TMP_ROOT/lint-greedy.err"
	rm -rf agent-skills/greedy
}

run_negated_authority_wording_passes() {
	mkdir -p agent-skills/disciplined
	cat >agent-skills/disciplined/SKILL.md <<'EOF'
---
name: disciplined
description: A skill that states its limits.
---

# Disciplined Skill

This skill may never accept tickets. Only a human may accept work, and the
skill cannot merge or push.
EOF
	./bin/palari skill lint >"$TMP_ROOT/lint-disciplined.out"
	grep -Fq "skill-lint: ok" "$TMP_ROOT/lint-disciplined.out"
	rm -rf agent-skills/disciplined
}

run_duplicate_name_in_root_fails() {
	mkdir -p agent-skills/dup-a agent-skills/dup-b
	for d in dup-a dup-b; do
		cat >"agent-skills/$d/SKILL.md" <<'EOF'
---
name: duplicated
description: Same name twice in one root.
---

# Duplicated Skill
EOF
	done
	if ./bin/palari skill lint >"$TMP_ROOT/lint-dup.out" 2>"$TMP_ROOT/lint-dup.err"; then
		echo "skill lint should fail on duplicate names in one root" >&2
		exit 1
	fi
	grep -Fq "duplicate skill name in agent-skills: duplicated" "$TMP_ROOT/lint-dup.err"
	rm -rf agent-skills/dup-a agent-skills/dup-b
}

run_same_name_across_roots_passes() {
	# The plugin packaging reuses the shipped palari-orchestrator name; the
	# repo itself is the fixture proving cross-root reuse is allowed.
	grep -Fq "name: palari-orchestrator" skills/orchestrator/SKILL.md
	grep -Fq "name: palari-orchestrator" plugin/skills/palari-orchestrator/SKILL.md
	./bin/palari skill lint >"$TMP_ROOT/lint-cross-root.out"
	grep -Fq "skill-lint: ok" "$TMP_ROOT/lint-cross-root.out"
}

run_shipped_skills_are_discoverable
run_clean_repo_lints_ok
run_generated_skill_lints_ok
run_missing_frontmatter_fails
run_authority_claim_fails
run_negated_authority_wording_passes
run_duplicate_name_in_root_fails
run_same_name_across_roots_passes

printf 'skills: ok\n'
