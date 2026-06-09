# Baseline DOC-01 Prompt

You are working in a disposable copy of the Palari Orchestrator repository.

Task:

Update `adapters/opencode/README.md` with a concise `## Limitations` section
explaining that the opencode wrapper records executor evidence but does not
accept, merge, push, deploy, or bypass human acceptance.

Constraints:

- Keep the edit small.
- Preserve existing wording.
- Do not use Palari lifecycle commands.
- Do not commit, push, merge, deploy, remove files, or touch secrets.
- Only edit `adapters/opencode/README.md`.

Run these checks if possible:

- `grep -q '## Limitations' adapters/opencode/README.md`
- `grep -q 'does not accept, merge, push, deploy, or bypass human acceptance' adapters/opencode/README.md`
- `git diff --check`

Final response:

- List files changed.
- List checks run and results.
- Say whether the task is complete or blocked.
