# Palari MCP Adapter

This directory is an optional adapter boundary, not part of the Bash core.

`tools.json` describes the Palari CLI commands an MCP wrapper can expose to an
agent runtime. A production MCP server should translate tool calls into the
listed CLI invocations and return stdout, stderr, exit code, and the repository
root used for the call.

Keep this adapter thin:

- The CLI remains the source of truth.
- MCP exposes discovery and tool-call ergonomics.
- CI, ticket files, reports, and git state remain authoritative.
- Agents may call `packet`, `scope-check`, and `lint`; `accept` stays outside
  this manifest because acceptance is a human or explicitly authorized reviewer
  action.
- The MCP adapter does not accept, merge, push, deploy, or bypass human acceptance. It is a read-and-report boundary only.
