## palari-doc-01 checks

$ ./bin/palari agent run PLT-1001 --executor opencode --model deepseek/deepseek-v4-flash
worktree: ok
Ticket: PLT-1001 - Opencode README limitations
Target branch: main (f3022d3)
Ticket branch: ticket/PLT-1001 (created from main)
Ticket worktree: /home/quetza/palari-pilot-workspaces/deepseek-palari-doc-01-root-20260609T132645Z/../palari-orchestrator-worktrees/PLT-1001
Worktree branch: ticket/PLT-1001
Worktree HEAD: f3022d3
Worktree changed paths: 0
Worker cd: cd /home/quetza/palari-pilot-workspaces/deepseek-palari-doc-01-root-20260609T132645Z/../palari-orchestrator-worktrees/PLT-1001
agent run: PLT-1001 via opencode
opencode exit: 0
scope-check exit: 0
ci exit: 0
evidence: reports/evidence/PLT-1001/executor/opencode

$ ./bin/palari ci PLT-1001
# Palari CI Evidence

- Ticket: PLT-1001
- Base ref: local working tree
- Created: 2026-06-09T13:27:30Z

## scope-check

```text
scope-check: ok for PLT-1001 (18 changed path(s))
```

## lint

```text
report-lint: ok for PLT-1001
lint: ok for PLT-1001
```

## verification 1

Command: `grep -q '## Limitations' adapters/opencode/README.md`

```text

```

## verification 2

Command: `grep -q 'does not accept, merge, push, deploy, or bypass human acceptance' adapters/opencode/README.md`

```text

```

## verification 3

Command: `git diff --check`

```text

```
