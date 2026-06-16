# POS-0087 Human Report

## Why This Mattered

Palari had the company OS governance data, but the operator dashboard still made
too much of it feel implicit. Humans need the risky parts visible at a glance.

## What Changed

- Added dashboard cards for company OS governance.
- Cards show HGL, high-risk decisions, missing skills, bottlenecks, autonomy
  gates, policy candidates, broker posture, outcomes, secure posture, and active
  workflows.
- The broker card says when evidence is only mock/observed-only.
- The policy card says policy candidates are simulation-only.
- The dashboard now renders those cards in the existing Company Governance area.

## What I Should Know

- This is read-only dashboard/snapshot work.
- It does not accept policies.
- It does not change HGL scoring.
- It does not change broker behavior or add side effects.
- It does not change workflows, outcomes, authority, secrets, or dependencies.
- A small legacy full-snapshot reliability fix was included because the required
  dashboard rubric exposed a snapshot failure in the stacked worktree.

## What To Check

- Command: `./bin/palari web --check`
- Command: `./tests/run-dashboard-rubric.sh`
- Command: `./tests/run-company-os-snapshot.sh`

## Recommended Next Move

Fresh-context review POS-0087. If accepted later, continue with the typed-schema
phase in the company AI OS plan.
