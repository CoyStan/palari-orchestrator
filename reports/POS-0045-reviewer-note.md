# POS-0045 Reviewer Note

## Review Result

Accept. Commit 783055b delivers the full ticket scope: `sandbox create`
writes `.palari/sandbox.json` metadata, and `sandbox list`, `sandbox
inspect`, and `sandbox destroy` are wired into dispatch, usage text,
README, CHANGELOG, tests, and both CI workflows. The destroy safety
contract (refuse any path lacking the `.palari-sandbox` marker) holds
under independent adversarial probing. No blocking defects found.

## Findings

- Scope compliance: all 13 changed paths fall inside the ticket
  `allowed_paths` (bin/palari, lib/palari/tickets_workspace.bash,
  tests/**, .github/workflows/**, CHANGELOG.md, README.md,
  tickets/open/POS-0045*, reports/**). No forbidden paths touched.
- Destroy safety verified independently: `--path /` and an unmarked
  directory are refused (exit 2); trailing slashes and `..` traversal
  segments are normalized by `abs_path` before the marker check, so
  `--path "$SB/"` and `--path "$SB/../repo"` resolve correctly.
- Pre-metadata sandboxes (no sandbox.json) are handled gracefully:
  inspect prints "unknown (created before sandbox.json)" for each
  metadata field and still reports marker ticket and dirty state.
- JSON metadata escaping verified: a source repo path containing
  spaces and double quotes produces valid JSON (`python3 -m json.tool`
  passes); quotes are escaped via the shared `json_string` helper.
- Minor (non-blocking), in rough priority order:
  1. `--path` given as the last argument crashes with a raw bash
     "unbound variable" error (tickets_workspace.bash, the
     `path="$2"; shift 2` parses in inspect/destroy). It fails closed
     (exit 1), but a clean `die "--path requires a value"` would be
     better.
  2. A relative `--path` resolves against the repo ROOT, not the
     caller's cwd (verified: from an unrelated cwd, `--path repo-sandbox`
     resolved to `$ROOT/repo-sandbox`). Surprising UX; the marker check
     is the only safety net against acting on the wrong directory.
  3. `destroy --path <symlink-to-sandbox>` passes the marker check
     through the symlink, prints "removed <symlink>", but deletes only
     the link; the real sandbox survives. Not destructive, but the
     success message is misleading.
  4. `inspect` prints JSON-escaped values verbatim (a path with quotes
     shows as `\"weird\"`). Display-only; acknowledged in the technical
     report as a known limitation of the line-oriented reader.
  5. Pre-existing: `json_escape` in core.bash does not escape control
     characters, so a path containing a literal tab would produce
     invalid JSON. Pathological input; not introduced by this commit.
  6. An empty `.palari-sandbox` marker yields a blank ticket column in
     `sandbox list`. Cosmetic.
- Design note: destroy/inspect by ticket ID dies if the ticket file is
  gone ("ticket not found"); the `--path` escape hatch covers orphaned
  sandboxes, as documented in the technical report.

## Verification Reviewed

- `tests/run-sandbox.sh` re-run from repo root by this reviewer:
  `sandbox: ok` (exit 0). The 6 cases match the technical report's
  claims (metadata written, list, inspect clean/dirty, inspect by path,
  destroy refuses non-sandbox, destroy removes plus parent cleanup).
- `shellcheck -x bin/palari lib/palari/tickets_workspace.bash
  tests/run-sandbox.sh` and `shfmt -d` on the same files: clean.
- CI wiring confirmed: test.yml gains `bash -n` and a "Sandbox
  lifecycle" step; static-analysis.yml adds tests/run-sandbox.sh to
  both ShellCheck and shfmt lists.
- Independent edge-case probes in /tmp (outside the repo): JSON
  validity for plain and special-character paths, trailing-slash and
  `..` path resolution, refusal of `/` and unmarked dirs, empty
  `--path ""`, missing `--path` value, nonexistent target, symlink
  destroy, pre-metadata inspect, empty marker in list, destroy with
  missing ticket file. Results as described under Findings.
- Evidence bundle present at reports/evidence/POS-0045/ (manifest,
  junit, sarif, verification.log) and consistent with the report.

## Required Changes

None blocking. Suggested follow-ups (may be folded into a future
ticket): clean error for `--path` missing its value (finding 1);
either document or change relative `--path` resolution to be
cwd-relative (finding 2); resolve symlinks (or refuse symlinked
targets) in `resolve_sandbox_target` before destroy (finding 3).

## Recommendation

Accept. Scope, risk, and path rules are respected; the definition of
done is met and independently verified; remaining findings are minor
UX/display issues that fail closed and do not weaken the destroy
safety contract.
