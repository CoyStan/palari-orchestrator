# Palari Repo Memory

Repo memory is optional. When present, memory truth lives in Markdown files under
these kind folders:

- `memory/invariants/`
- `memory/decisions/`
- `memory/gotchas/`
- `memory/failures/`
- `memory/patterns/`
- `memory/commands/`

Each memory file carries frontmatter with an `id`, `kind`, `status`,
`truth_key`, scoped `paths`, `tags`, a `source_ticket`, and explicit links.
Generated search indexes under `.palari/cache/` are disposable read models, not
truth.

Use `palari memory add`, `palari memory lint`, `palari memory index`, and
`palari memory query` to manage memory without making it mandatory for normal
Palari usage.
