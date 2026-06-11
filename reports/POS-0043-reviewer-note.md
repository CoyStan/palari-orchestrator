# POS-0043 Reviewer Note

Fresh-context review of commit ed0fb64 (machine-discoverable skills with
`skill list` and `skill lint`). Reviewer did not implement this work.

## Review Result

accept. The Definition of Done is met, verification re-runs pass, scope is
clean, and the known weaknesses of the authority-claim heuristic are honestly
disclosed in the technical report rather than overstated.

## Findings

- [medium] Authority-claim heuristic false negatives. The negation filter in
  `skill_authority_claim_lines` (`lib/palari/adapters_snapshot.bash`) is a
  per-line veto: any line containing `not`, `never`, `cannot`, or `only` is
  whitelisted wholesale. Probed adversarially (grep pipeline on stdin, outside
  the repo): "This skill may accept and merge tickets, but only on Tuesdays"
  and "This skill may merge to main, not asking anyone first" both pass lint.
  Further evasions: imperative phrasing ("Accept the ticket, merge to main,
  and push without review."), second person ("You may accept tickets..."),
  unlisted verbs ("This skill is authorized to accept..."), and
  period-splitting ("This skill may, e.g., accept tickets...") because the
  regex uses `[^.]*` within a sentence. 7 of 8 adversarial probes evaded; only
  the literal "overrides AGENTS.md" form was caught. Mitigation: the report
  and code comment disclose this as a heuristic guard, and authority is
  enforced by tickets/gates, not skills. Not blocking; deserves a follow-up.
- [medium] Authority-claim heuristic false positives. `(accept|merge|push)`
  match as bare substrings with no trailing word boundary. Probed benign
  lines all tripped the linter: "The agent can help you avoid pushback...",
  "This skill can speed up acceptance testing...", "The agent may surface
  merge conflicts early so a human resolves them", "Skills allow teams to
  document accepted conventions...". Adopter skills describing normal review
  workflows will fail lint with confusing errors. Cheap improvement: word
  boundaries plus explicit stems (accept/accepts/merge/merges/push/pushes).
- [low] `find_skill_file` is dead code in this commit (built for POS-0046).
  It also resolves cross-root name collisions silently by root order
  (`skills/` wins over `plugin/skills/`); since per-root duplicate names are
  allowed by design, this ambiguity should be settled when it gains a caller.
- [low] Evidence drift: the technical report says scope-check saw 10 changed
  paths while the committed `reports/evidence/POS-0043/verification.log` says
  13 (evidence files were added after the snapshot). Immaterial.
- [info] The committed verification.log shows full `./bin/palari lint` -> ok;
  that snapshot predates the in-review status flip. At review time the full
  lint failed only on "missing fresh-context reviewer note" for POS-0043,
  which this note resolves. Expected lifecycle behavior, not a false claim.
- [info] `skill lint` is not wired into aggregate `palari lint` or as a
  direct CI step; CI coverage comes via `tests/run-skills.sh`, which lints a
  copied repo plus failure fixtures. Consistent with ticket scope.
- Scope check: all 15 changed paths in ed0fb64 fall within the ticket's
  allowed_paths (skills/**, lib/palari/adapters_snapshot.bash, bin/palari,
  tests/**, .github/workflows/**, CHANGELOG.md, reports/**,
  tickets/open/POS-0043*). No forbidden paths touched. README.md was allowed
  but not needed; usage text in bin/palari was updated as scoped.

## Verification Reviewed

- `tests/run-skills.sh` (repo root): re-ran, output `skills: ok` (8 cases
  including authority-claim failure, negated wording pass, duplicate-in-root
  failure, cross-root reuse pass). Matches the report's claim.
- `./bin/palari skill lint`: re-ran, output `skill-lint: ok (4 skill(s))`.
- `./bin/palari skill list`: re-ran; prints name, path, and truncated
  description for the 3 shipped skills plus the plugin skill, then a count.
  Matches the Definition of Done.
- `./bin/palari lint`: re-ran; failed only on the missing reviewer note for
  POS-0043 (this file), all other checks ok. Re-run after writing this note.
- `shellcheck -x bin/palari lib/palari/adapters_snapshot.bash`: could NOT be
  re-run; the review sandbox denies the shellcheck command. CI's
  static-analysis workflow runs it (and was extended to cover
  tests/run-skills.sh), and the committed evidence log shows a clean run.
- Heuristic probes: ran the exact grep pipeline from
  `skill_authority_claim_lines` against adversarial and benign wordings fed
  via stdin (the sandbox denied creating throwaway files under /tmp; stdin is
  equivalent for grep). Results documented under Findings.

## Required Changes

none. Suggested non-blocking follow-ups: (1) add word boundaries to the
authority-claim verb/object alternations to cut false positives; (2) replace
the per-line negation veto with something narrower so "only on Tuesdays"
cannot whitelist a genuine grant; (3) resolve cross-root name shadowing in
`find_skill_file` when POS-0046 gives it a caller.

## Recommendation

accept. All three Definition of Done items verify: shipped skills carry valid
frontmatter, `skill list` enumerates shipped/adopter/plugin skills with
descriptions, and `skill lint` passes on the repo while failing on an
authority-claiming fixture (covered by tests I re-ran). The heuristic's
limits are real but disclosed, advisory by design, and backstopped by gates;
they warrant a follow-up ticket, not a reopen.
