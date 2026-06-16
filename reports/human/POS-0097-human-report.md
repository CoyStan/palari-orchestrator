# POS-0097 Human Report

## Why This Mattered

Model providers can make Palari smarter and cheaper, but they must never become
the hidden authority layer. Palari needs to decide which model may be used, for
which risk/data class, and with what evidence.

## What Changed

- Added a governed model provider contract.
- The contract says model providers supply capability, not authority.
- It records routing factors such as risk, data sensitivity, cost, latency,
  task type, historical success, allowed providers, customer data restrictions,
  evaluation score, and fallback availability.
- It records that routing policy is subordinate to Palari authority: tickets,
  risk, policy simulation, broker boundaries, data classification, human
  governance, R5 controls, evidence, and review/acceptance gates.
- It says OpenRouter remains model supply, not governance.
- Tests now check the core contract language.

## What I Should Know

- This does not add a new model provider integration.
- This does not change OpenRouter runtime behavior.
- This does not add network calls, credentials, dependencies, or lockfiles.
- This does not let models accept work, decide policy, bypass data restrictions,
  replace review, or mutate lifecycle state.
- This does not change broker behavior, policy acceptance, HGL scoring, R5
  controls, deployment, secrets, or runtime state.

## What To Check

- Path: `contracts/adapters.md`
- Command: `./tests/run-model-routing.sh`
- Command: `./tests/run-openrouter.sh`

## Recommended Next Move

Fresh-context and human review POS-0097. If accepted later, the named plan
sequence through POS-0097 is complete; choose the next roadmap phase before
creating more tickets.
