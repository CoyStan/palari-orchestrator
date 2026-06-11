# POS-0046 Reviewer Note

## Review Result

Fresh-context review of commit c88ac81 (related skills in ticket frontmatter
and packets). Implementation matches the ticket goal and Definition of Done.
Verification re-run independently and passed. Three minor findings, none
blocking; one contradictory-output bug is worth a follow-up ticket.

## Findings

1. Contradictory packet output for a dangling related skill (minor bug,
   `print_packet_skills` in `lib/palari/agents_review_scope.bash`). `count`
   tracks resolved skills, not declared ones, so a ticket whose only related
   skill was removed after creation produces both lines:
   `- gone (missing; run palari skill list)` followed by `- none declared`.
   Reproduced in a throwaway copy. The dangling-skill case is tested for
   lint but not for packet output, so this slipped through.
2. Duplicate `--skill NAME` flags are not deduplicated (minor). Passing
   `--skill palari-adoption` twice writes the entry twice into
   `related_skills` and would inject the section twice into the packet.
   Creation-time validation rejects unknown names but not repeats.
3. The trailing `(excerpt; read the full skill before editing)` line prints
   even when the skill body is shorter than the cap (entire body already
   shown) or empty (cosmetic). A skill with no description renders cleanly
   with no blank description line, which is correct.
4. Positive checks all hold: the word-boundary regex still flags
   "This skill may merge to main", "The skill can push to origin", and the
   new "is authorized to accept" phrasing, while benign wording (pushback,
   acceptance, merged) passes - confirmed by probe and by the new
   `run_benign_wording_passes` regression case. `find_skill_file`
   resolution-order comment matches actual behavior. Lint correctly warns
   (stderr, non-fatal) on dangling references.
5. Technical report nit: it claims scope-check saw 9 changed paths while the
   committed evidence log records 15; the commit itself touches 13 files.
   Not load-bearing, but the report and evidence disagree.

## Verification Reviewed

- `tests/run-skills.sh` from repo root: `skills: ok` (all 13 cases,
  including the 5 new POS-0046 cases).
- `shellcheck -x bin/palari lib/palari/agents_review_scope.bash`: clean.
- `./bin/palari lint`: ticket lint ok; the only report-lint failure was the
  absence of this reviewer note, which is expected mid-review.
- Scope: every path in c88ac81 (bin/palari, lib/palari/{adapters_snapshot,
  agents_review_scope,tickets_workspace}.bash, tests/run-skills.sh,
  reports/**, AGENTS.md, README.md, CHANGELOG.md,
  tickets/open/POS-0046-*.md) falls inside the ticket's allowed_paths; no
  forbidden paths touched.
- Edge probes in a /tmp throwaway copy (not the repo): no-description skill,
  sub-10-line excerpt, empty-body excerpt, dangling-skill packet,
  duplicate --skill, and authority-regex bypass attempts. Results in
  Findings above.
- Definition of Done: `--skill palari-adoption` packet carries name,
  description, and excerpt (test `run_packet_includes_related_skills`);
  lint warns on a missing related skill (test
  `run_lint_warns_on_missing_related_skill`). Both verified.

## Required Changes

None blocking. Recommended follow-ups (do not gate acceptance):

- Fix the dangling-skill packet contradiction: count declared skills (or
  also increment in the missing branch) so `- none declared` only prints
  when `related_skills` is truly empty; add a packet-output test for the
  dangling case.
- Deduplicate repeated `--skill` values at ticket creation.
- Optionally suppress the excerpt pointer line when the full body fits
  within the cap or the body is empty.

## Recommendation

Accept. The scoped result exists, path and risk rules are respected, all
ticket verification passes on re-run, and skills remain advisory (packets
carry them, tickets scope, gates enforce). File the dangling-skill packet
fix and `--skill` dedup as a small follow-up ticket.
