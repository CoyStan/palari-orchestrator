---
name: palari-adoption
description: Use when installing Palari into a repository or improving the adoption path - palari init, palari adopt, doctor checks, and adapter generation without overwriting product files or activating CI and rulesets uninvited.
---

# Palari Adoption Skill

Use this skill when installing Palari into a repository or improving the
adoption path.

## Clean Adoption Rubric

1. One primary command exists for adoption.
2. The command refuses non-git targets and explains why.
3. Existing files are kept by default.
4. Existing `AGENTS.md` is not overwritten; a Palari merge copy is written.
5. Required directories are created by `palari init`.
6. `palari doctor` reports the installed state.
7. The command prints copyable next steps.
8. Optional GitHub CI and hooks are opt-in.
9. The README shows a short copy-paste path before advanced details.
10. Tests prove the install path in a disposable target repo.
11. App/product repos can start a governed session without copying Palari
    internals into the target.

## Workflow

1. For app/product repos or "use Palari as governance" requests, run
   `palari adopt TARGET --governance-only` from the Palari package checkout.
2. Confirm the target did not receive Palari internals such as `bin`,
   `lib/palari`, `adapters`, `gate`, `research`, upstream tests, vendor data,
   or POS/COS report history.
3. Run the external status command printed by adoption, using `PALARI_ROOT`
   and `PALARI_LIB_DIR` to point the Palari checkout at the target.
4. Read any warnings about `AGENTS.palari.md` and tell the user how to merge
   the governance-session contract.
5. Use full adoption only when the user explicitly wants the local Palari
   runtime, `./bin/palari` in the target, CI, or hooks. Full adoption requires
   `palari adopt plan TARGET --out ADOPTION-PLAN.md`, human approval of that
   plan, then `palari adopt TARGET --plan ADOPTION-PLAN.md`.
6. For full adoption, run `cd TARGET && ./bin/palari doctor`.
7. Create the first proposal or ticket only after the adopted/session status is
   healthy.

## Stop Conditions

Stop when adoption would overwrite product files, touch secrets, require
production access, install a remote service, or activate GitHub rulesets without
explicit human approval. Stop and ask before full adoption would vendor Palari
runtime files into an app/product repository.
