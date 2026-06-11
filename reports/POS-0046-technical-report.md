# POS-0046 Technical Report

## Session

- Ticket: POS-0046
- Role: specialist (claude)
- Branch: combine/plugin-import
- Result: in-review

## Files Changed

```text
lib/palari/tickets_workspace.bash
lib/palari/agents_review_scope.bash
lib/palari/adapters_snapshot.bash
bin/palari
tests/run-skills.sh
README.md
AGENTS.md
CHANGELOG.md
tickets/open/POS-0046-related-skills-in-ticket-frontmatter-and-packets.md
```

## Outcome

- What changed: `palari ticket create --skill NAME` (repeatable) writes
  `related_skills` frontmatter and fails fast on unknown names. `palari
  packet` injects a Relevant Skills section: name, path, description, a
  10-line capped excerpt, and the rule line "Skills guide execution; the
  ticket controls authority and scope." `palari lint` warns (not errors) on
  dangling references, because skills are advisory. Per the POS-0043
  reviewer's findings, the authority heuristic gained word boundaries
  (benign pushback/acceptance/merged wording passes; covered by a new
  regression case) and `find_skill_file` resolution order is documented
  (shipped beats adopter beats plugin on name collision).
- What did not change: no schema work (no ticket schema exists, only the
  config schema). Skills still cannot grant or widen authority.

## Verification

- `tests/run-skills.sh` -> `skills: ok` (13 cases; 5 new: benign wording,
  unknown --skill rejected, packet injection, packet none-declared, lint
  warning on dangling reference)
- `tests/run-sandbox.sh`, `tests/run-cli-structure.sh` -> ok (regression)
- `./bin/palari scope-check POS-0046` -> ok (9 changed paths)
- `shellcheck -x` / `shfmt -d` on all changed shell files -> clean

## CI Evidence

- `./bin/palari ci POS-0046` -> ok (first run failed because POS-0045's
  reviewer note had not landed yet - the cross-ticket report gate fired as
  designed; note committed, re-run green)
- Bundle: `reports/evidence/POS-0046/`

## Risks / Follow-Ups

- Packet excerpts are capped at 10 non-empty lines; long skills rely on the
  executor following the "read the full skill" pointer.
- The authority heuristic remains a heuristic; gates stay the enforcement.
