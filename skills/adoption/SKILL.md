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

## Workflow

1. Run `palari adopt TARGET` from the Palari package checkout.
2. Run `cd TARGET && ./bin/palari doctor`.
3. Read any warnings about `AGENTS.palari.md`, GitHub workflows, or rulesets.
4. Create the first proposal or ticket only after the doctor passes.

## Stop Conditions

Stop when adoption would overwrite product files, touch secrets, require
production access, install a remote service, or activate GitHub rulesets without
explicit human approval.
