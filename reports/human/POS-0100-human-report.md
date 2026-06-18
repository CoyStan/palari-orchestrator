# POS-0100 Human Report

## Why This Mattered

The minimax review showed that labels such as `founder` and `admin` could make
one person look like multiple actors. That weakens self-acceptance and quorum
rules because the system should separate people, not merely strings.

## What Changed

- Human profiles can now carry a stable `person_id`.
- The default admin profile declares `PERSON-QUETZA` and aliases for `admin` and
  `founder`.
- Acceptance checks compare stable identity when deciding whether two actors are
  distinct.
- A user cannot satisfy self-acceptance or two-human quorum rules by using two
  labels that resolve to the same person.
- Error messages now say which stable identity caused the conflict.

## What I Should Know

- This does not accept, merge, push, or deploy anything.
- This does not change policy acceptance, broker behavior, or Google/GitHub
  behavior.
- Existing one-human flows still work where governance config permits them.
- Old human profiles without `person_id` still work by deriving identity from
  their human profile ID.

## What To Check

- `lib/palari/ci_accept.bash`
- `lib/palari/humans.bash`
- `humans/active/HUMAN-ADMIN-admin.md`
- `tests/palari_acceptance.bats`
- Run `bats tests/palari_acceptance.bats`

## Recommended Next Move

Run Palari CI/evidence checks and fresh-context review. If the reviewer agrees,
leave POS-0100 in review for later founder acceptance.
