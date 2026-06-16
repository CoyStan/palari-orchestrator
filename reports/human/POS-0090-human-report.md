# POS-0090 Human Report

## Why This Mattered

Palari's company OS artifacts were readable Markdown, but future agents need a
machine-readable contract for what those artifacts mean before autonomy grows.

## What Changed

- Added typed schemas for workflows, human governance profiles, simulation
  policies, outcomes, broker observations, and the company OS snapshot.
- Added a focused schema test that creates representative artifacts in a
  temporary repo and validates them against the schemas.
- Recorded the schema compatibility boundary in the company AI OS contract.

## What I Should Know

- This does not change product/runtime behavior.
- This does not migrate existing artifacts.
- This does not make policy acceptance real.
- This does not give the broker real side effects or credentials.
- Runtime lints still exist in Bash/Python; the schemas are a contract and test
  layer for future typed validation.

## What To Check

- Path: `schemas/workflow.schema.json`
- Path: `schemas/human.schema.json`
- Path: `schemas/policy.schema.json`
- Path: `schemas/outcome.schema.json`
- Path: `schemas/broker-observation.schema.json`
- Path: `schemas/company-os-snapshot.schema.json`
- Command: `./tests/run-company-os-schemas.sh`

## Recommended Next Move

Fresh-context review POS-0090. If accepted later, continue with POS-0091 for
the human capacity migration helper.
