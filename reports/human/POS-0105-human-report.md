# POS-0105 Human Report

## Why This Mattered

Downstream adoption should install Palari as a framework, not import the source
repo's old governance history. A new repo needs clean local tickets, reports,
humans, workflows, and evidence instead of inherited records from the repo that
provided the tooling.

## What Changed

- Adoption plans now explicitly list excluded upstream governance artifacts.
- Adoption skips source governance-history directories when building the path
  manifest, source manifest hash, and non-dry-run copy plan.
- The adoption test harness now plants source-only tickets, reports, evidence,
  human reports, memory, tests, humans, workflows, policies, outcomes, goals,
  and decisions, then proves they do not appear in the target repo.
- The adoption contract and README explain that adoption installs the substrate,
  not the source repo's project history.

## What I Should Know

This does not add an import mode for old governance history. It keeps the first
safe behavior simple: downstream repos start with empty local governance
scaffolding unless a future ticket designs an explicit import workflow.

## What To Check

- `lib/palari/init_adopt.bash`
- `tests/run-adoption.sh`
- `contracts/adoption.md`
- `reports/evidence/POS-0105/manifest.json` after CI evidence is generated

## Recommended Next Move

Run POS-0105 CI evidence and fresh-context review. If the reviewer agrees the
downstream adoption boundary is honest and complete, leave POS-0105 in review
for founder acceptance.
