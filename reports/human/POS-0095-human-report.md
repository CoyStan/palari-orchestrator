# POS-0095 Human Report

## Why This Mattered

Before Palari connects to more workers, the repo needs a clear rule: workers do
work, but Palari owns authority.

## What Changed

- Added a company OS worker adapter contract.
- The contract covers future Hermes, GBrain, OpenRouter, Codex, local agents,
  and human delegates.
- It says workers can receive scoped work, produce evidence, and ask the broker
  for actions.
- It says workers cannot hold company credentials, accept work, or own merge,
  deploy, send, charge, or refund authority.
- Tests now check the core contract language.

## What I Should Know

- This does not add a real integration.
- This does not add network calls or dependencies.
- This does not give any worker credentials.
- This does not change policy acceptance, R5 controls, broker behavior, HGL
  scoring, lifecycle state, deployment, secrets, or runtime state.
- Future real integrations still need separate scoped tickets and human review.

## What To Check

- Path: `contracts/adapters.md`
- Command: `./tests/run-agent-wrapper.sh`

## Recommended Next Move

Fresh-context and human review POS-0095. If accepted later, continue with the
memory provider governance contract.
