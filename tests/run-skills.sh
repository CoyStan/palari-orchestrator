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

run_benign_wording_passes() {
	mkdir -p agent-skills/benign
	cat >agent-skills/benign/SKILL.md <<'EOF'
---
name: benign
description: A skill with benign wording near risky words.
---

# Benign Skill

This skill may encourage pushback during acceptance testing. The skill can
explain merged history and previously accepted conventions.
EOF
	./bin/palari skill lint >"$TMP_ROOT/lint-benign.out"
	grep -Fq "skill-lint: ok" "$TMP_ROOT/lint-benign.out"
	rm -rf agent-skills/benign
}

run_ticket_create_rejects_unknown_skill() {
	if ./bin/palari ticket create LAB-0101 "Unknown skill ref" \
		--allowed "docs/**" --verify "noop" \
		--skill no-such-skill >"$TMP_ROOT/create-unknown.out" 2>"$TMP_ROOT/create-unknown.err"; then
		echo "ticket create should reject an unknown --skill" >&2
		exit 1
	fi
	grep -Fq "related skill not found: no-such-skill" "$TMP_ROOT/create-unknown.err"
}

run_packet_includes_related_skills() {
	./bin/palari ticket create LAB-0102 "Packet skill injection" \
		--allowed "docs/**" \
		--allowed "tickets/**" \
		--allowed "reports/**" \
		--verify "packet skill check" \
		--skill palari-adoption >/dev/null
	grep -Fq "related_skills:" "$(find tickets/open -name 'LAB-0102-*.md')"
	git add .
	git commit -m "packet skill baseline" >/dev/null
	./bin/palari worktree LAB-0102 >/dev/null
	./bin/palari packet LAB-0102 specialist >"$TMP_ROOT/skill-packet.out"
	grep -Fq "Relevant Skills:" "$TMP_ROOT/skill-packet.out"
	grep -Fq "palari-adoption (skills/adoption/SKILL.md)" "$TMP_ROOT/skill-packet.out"
	grep -Fq "(excerpt; read the full skill before editing)" "$TMP_ROOT/skill-packet.out"
	grep -Fq "Skills guide execution; the ticket controls authority and scope." "$TMP_ROOT/skill-packet.out"
}

run_packet_without_skills_says_none() {
	grep -Fq "Relevant Skills:" "$TMP_ROOT/skill-packet.out" || exit 1
	./bin/palari ticket create LAB-0103 "No skills declared" \
		--allowed "docs/**" \
		--allowed "tickets/**" \
		--verify "noop" >/dev/null
	git add .
	git commit -m "no-skill baseline" >/dev/null
	./bin/palari worktree LAB-0103 >/dev/null
	./bin/palari packet LAB-0103 specialist >"$TMP_ROOT/no-skill-packet.out"
	grep -Fq "none declared" "$TMP_ROOT/no-skill-packet.out"
}

run_lint_warns_on_missing_related_skill() {
	./bin/palari skill create doomed --description "Will be removed" >/dev/null
	./bin/palari ticket create LAB-0104 "Dangling skill ref" \
		--allowed "docs/**" \
		--allowed "tickets/**" \
		--verify "noop" \
		--skill doomed >/dev/null
	rm -rf agent-skills/doomed
	./bin/palari lint LAB-0104 >"$TMP_ROOT/lint-dangling.out" 2>"$TMP_ROOT/lint-dangling.err"
	grep -Fq "warning: related skill not found: doomed" "$TMP_ROOT/lint-dangling.err"
	grep -Fq "lint: ok for LAB-0104" "$TMP_ROOT/lint-dangling.out"
}

run_packet_polish() {
	mkdir -p agent-skills/shorty
	cat >agent-skills/shorty/SKILL.md <<'EOF'
---
name: shorty
description: A short skill that fits one excerpt.
---

# Shorty

One rule only.
EOF
	./bin/palari skill create doomed2 --description "Will vanish before packet" >/dev/null
	./bin/palari ticket create LAB-0105 "Packet polish" \
		--allowed "docs/**" \
		--allowed "tickets/**" \
		--allowed "reports/**" \
		--verify "noop" \
		--skill shorty \
		--skill shorty \
		--skill doomed2 >/dev/null
	test "$(grep -Fc -- '- shorty' "$(find tickets/open -name 'LAB-0105-*.md')")" = "1"
	rm -rf agent-skills/doomed2
	git add .
	git commit -m "packet polish baseline" >/dev/null
	./bin/palari worktree LAB-0105 >/dev/null
	./bin/palari packet LAB-0105 specialist >"$TMP_ROOT/polish-packet.out"
	grep -Fq "shorty (agent-skills/shorty/SKILL.md)" "$TMP_ROOT/polish-packet.out"
	if grep -Fq "(excerpt; read the full skill before editing)" "$TMP_ROOT/polish-packet.out"; then
		echo "short skill bodies must not print the excerpt pointer" >&2
		exit 1
	fi
	grep -Fq "doomed2 (missing; run palari skill list)" "$TMP_ROOT/polish-packet.out"
	if grep -Fq "none declared" "$TMP_ROOT/polish-packet.out"; then
		echo "declared-but-missing skills must not print none declared" >&2
		exit 1
	fi
	rm -rf agent-skills/shorty
}

run_shipped_skills_are_discoverable
run_clean_repo_lints_ok
run_generated_skill_lints_ok
run_missing_frontmatter_fails
run_authority_claim_fails
run_negated_authority_wording_passes
run_duplicate_name_in_root_fails
run_same_name_across_roots_passes
run_benign_wording_passes
run_ticket_create_rejects_unknown_skill
run_packet_includes_related_skills
run_packet_without_skills_says_none
run_lint_warns_on_missing_related_skill
run_packet_polish

printf 'skills: ok\n'
