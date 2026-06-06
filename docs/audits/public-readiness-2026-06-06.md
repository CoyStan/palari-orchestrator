# Palari Public-Readiness Audit

Date: 2026-06-06

Commit audited: `01d67101e7ba9891641e568fabd91ffe8dcd7575`

## Verdict

Announce after fixes.

The project has a coherent portable core, but it was not ready to announce as a
professional governance package. The audit found missing open-source hygiene,
uninstalled live GitHub enforcement, failed shell static checks, weak evidence
validation, and an OpenSSF Scorecard result of 3.5/10.

## Top Blockers Found

1. `palari accept` accepted forgeable local evidence files.
2. The GitHub ruleset template existed but was not installed on the live repo.
3. OpenSSF Scorecard was 3.5/10.
4. ShellCheck and shfmt failed on `bin/palari`.
5. No license, security policy, contribution docs, release notes, issue
   templates, or release process existed.
6. README evidence claims were stronger than local `accept` enforcement.
7. The test suite was mostly a monolithic golden test with no Bats coverage.
8. `bin/palari` was a large security-sensitive Bash monolith.
9. The dashboard warned on non-loopback binds but still served.
10. The MCP manifest exposed `palari_accept`, blurring the human acceptance
    boundary.

## Deterministic Results

- `git clone`: passed
- `git status --short --branch`: passed
- `find . -maxdepth 3 -type f | sort`: passed
- `tests/run-golden.sh`: passed
- `./bin/palari lint`: passed
- `python3 -m py_compile adapters/web/server.py`: passed
- `tests/run-dashboard-rubric.sh`: passed
- `actionlint`: passed after installing locally for audit
- `shellcheck bin/palari scripts/palari`: failed
- `shfmt -d bin/palari scripts/palari`: failed
- `npx repomix@latest --style xml --output repomix-output.xml`: passed
- `bats tests`: ran, but no Bats tests existed
- OpenSSF Scorecard: ran manually with user-provided token, score 3.5/10

## Scorecard Result

Overall: 3.5/10

Zero or failing checks:

- Branch-Protection
- CII-Best-Practices
- Code-Review
- Contributors
- Dependency-Update-Tool
- Fuzzing
- License
- Maintained
- Pinned-Dependencies
- SAST
- Security-Policy
- Signed-Releases

## Follow-Up Standard

Public claims must be tied to enforcement. If a gate is local-only, say so. If
evidence is trusted because GitHub produced and attested it, `accept` or the
merge path must verify that fact.

## Remediation Recorded

The follow-up work for this audit addressed the blockers by adding evidence
manifest integrity validation, installing the live GitHub ruleset, adding
open-source project hygiene files, removing MCP exposure of `accept`, refusing
non-loopback dashboard binds by default, adding static/security workflows,
pinning GitHub Actions to commit SHAs, adding Bats regression coverage, and
making ShellCheck/shfmt/actionlint part of the project checks.
