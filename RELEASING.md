# Releasing

Palari is pre-1.0. Use small tagged releases and do not imply stable security
guarantees until acceptance, CI evidence, and ruleset enforcement are proven in
CI.

Release checklist:

1. Run the full local check suite from `CONTRIBUTING.md`.
2. Verify GitHub rulesets are installed:

   ```bash
   gh api repos/CoyStan/palari-orchestrator/rulesets --jq '.[].name'
   ```

3. Run OpenSSF Scorecard and record the score in the release notes.
4. Update `CHANGELOG.md`.
5. Create a signed tag when signing is configured:

   ```bash
   git tag -s v0.1.0 -m "v0.1.0"
   ```

6. Publish a GitHub release from the tag.
