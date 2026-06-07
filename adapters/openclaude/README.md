# Palari OpenClaude Adapter Notes

OpenClaude can be used as a Palari lead or executor when it is installed and
configured with a provider such as DeepSeek. Keep the Palari boundary the same:
the lead proposes, the executor implements, and the human accepts.

## Suggested Lead Use

Create a proposal and lead packet:

```bash
palari propose create POS-PROP-0001 "Improve onboarding" \
  --planner openclaude \
  --model deepseek/deepseek-v4-flash \
  --intent "Make the repository easier for non-programmers to understand."

palari propose packet POS-PROP-0001 > reports/planning/POS-PROP-0001-lead-packet.md
```

Give OpenClaude the packet and ask it to update only the proposal file and
planning notes. Do not let it implement the proposed ticket or run acceptance.

## Suggested Executor Use

For now, use the tested opencode wrapper for execution:

```bash
palari agent run TICKET-ID --executor opencode --model deepseek/deepseek-v4-flash
```

Add a permanent OpenClaude executor wrapper only after a smoke test proves a
stable non-interactive command contract with working directory, attached packet,
JSON or machine-readable logs, and a deny list for lifecycle authority commands.

## Boundary

OpenClaude may be stronger than Palari at multi-step coding. Palari should
remain stronger at repository authority: tickets, scope, worktrees, evidence,
review, and human acceptance.
