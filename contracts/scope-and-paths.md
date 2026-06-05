# Scope And Path Contract

Every ticket must declare `allowed_paths` and `forbidden_paths`.

Agents may edit only paths listed in `allowed_paths`. If the work needs another
path, stop and rescope before editing.

Forbidden paths win over allowed paths. If a changed path matches both, the
scope check fails.

Recommended default forbidden paths:

```text
.env
.env.*
**/secrets/**
**/*secret*
**/*token*
infra/prod/**
prod/**
```

Run:

```bash
palari scope-check TICKET-ID
```

Scope checks inspect changed, staged, and untracked paths in the current git
worktree.
