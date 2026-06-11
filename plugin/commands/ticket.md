---
description: Create a well-scoped Palari ticket from a description
---

Create a Palari ticket for: $ARGUMENTS

1. Ask only if essential information is missing; otherwise infer sensibly and state assumptions.
2. Choose the narrowest `--allowed` globs that cover the work, real `--verify` commands that prove it, an honest risk tier (R2+ auto-requires review), and link a goal with `--goal GOAL-ID` when one fits (`./bin/palari goal list`).
3. Run `./bin/palari ticket create ID "Title" ...` then `./bin/palari lint ID` and show the resulting ticket file path.
4. Do not claim or start the work unless the user asks; suggest `/palari-orchestrator:next` for that.
