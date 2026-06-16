# POS-0096 Human Report

## Why This Mattered

Memory can make agents much more useful, but it must not quietly become the
authority layer. Palari needs to decide what memory may be used, by whom, and
with what evidence.

## What Changed

- Added a governed memory provider contract.
- The contract says memory providers supply context, not authority.
- It lists allowed operations such as search, synthesize, cite, ACL check, gap
  report, and proposed write.
- It records that Palari controls actor access, citation requirements,
  freshness, review for writes, and data-class routing to models/providers.
- Tests now check the core contract language.

## What I Should Know

- This does not add GBrain or any live memory provider.
- This does not add network calls, credentials, dependencies, or lockfiles.
- This does not let memory accept work or mutate lifecycle state.
- This does not change policy acceptance, broker behavior, HGL scoring, R5
  controls, deployment, secrets, or runtime state.

## What To Check

- Path: `contracts/adapters.md`
- Command: `./tests/run-memory.sh`

## Recommended Next Move

Fresh-context and human review POS-0096. If accepted later, continue with the
model provider governance contract.
