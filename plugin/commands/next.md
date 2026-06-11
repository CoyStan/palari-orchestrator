---
description: Plan the queue (read-only) and propose the next safe step
---

Plan what should happen next in this Palari-governed repository. Optional focus: $ARGUMENTS (a GOAL-ID or ticket id).

1. Run `./bin/palari run --dry-run` (add `--goal GOAL-ID` if one was given). This is read-only.
2. Present the plan: stop items first (open decisions, human gates) with their exact commands for the human, then the next agent-safe step.
3. Ask the user whether to execute the next agent-safe step. Only proceed after they confirm, and then follow the palari-orchestrator skill lifecycle exactly (claim, worktree, packet, scoped work, evidence, ready). Never accept, merge, or record decisions.
