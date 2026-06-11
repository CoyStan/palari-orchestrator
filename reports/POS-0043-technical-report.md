# POS-0043 Technical Report

## Session

- Ticket: POS-0043
- Role: specialist (claude)
- Branch: combine/plugin-import
- Result: in-review

## Files Changed

```text
skills/orchestrator/SKILL.md
skills/planner/SKILL.md
skills/adoption/SKILL.md
lib/palari/adapters_snapshot.bash
bin/palari
tests/run-skills.sh
.github/workflows/test.yml
.github/workflows/static-analysis.yml
CHANGELOG.md
tickets/open/POS-0043-machine-discoverable-skills-with-skill-list-and-lint.md
```

## Outcome

- What changed: the three shipped skills now carry YAML frontmatter
  (`name`, `description`). New commands `palari skill list` (enumerates
  shipped, adopter, and plugin skills with descriptions) and
  `palari skill lint` (validates frontmatter, per-root name uniqueness, and
  refuses grant-shaped authority wording). `find_skill_file NAME` resolves a
  skill by name for reuse by packet injection (POS-0046).
- What did not change: skills remain advisory. The linter is a heuristic
  guard, not a parser: it skips negated or human-gated wording so skills can
  state their limits ("only a human may accept") without tripping it.
- Design decision: name uniqueness is enforced per skill root, because the
  plugin packaging under `plugin/skills/` legitimately reuses the shipped
  `palari-orchestrator` name.

## Verification

- `tests/run-skills.sh` -> `skills: ok` (8 cases: discovery, clean lint,
  generated skill, missing frontmatter fails, authority claim fails, negated
  wording passes, duplicate-in-root fails, cross-root reuse passes)
- `tests/run-cli-structure.sh` -> `cli-structure: ok`
- `./bin/palari lint POS-0043` -> ok (serves_goal warning only)
- `./bin/palari scope-check POS-0043` -> ok (10 changed paths)
- `shellcheck -x` and `shfmt -d` on `bin/palari`,
  `lib/palari/adapters_snapshot.bash`, `tests/run-skills.sh` -> clean

## CI Evidence

- `./bin/palari ci POS-0043` -> ok
- Bundle: `reports/evidence/POS-0043/` (junit.xml, palari.sarif,
  manifest.json)

## Risks / Follow-Ups

- The authority-claim linter is a wording heuristic; adversarial phrasing can
  evade it. Authority enforcement remains in tickets and gates, not skills.
- POS-0046 will build `related_skills` packet injection on
  `find_skill_file`.
