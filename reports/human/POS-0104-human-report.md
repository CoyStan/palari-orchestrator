# POS-0104 Human Report

## Why This Mattered

A green evidence bundle should not hide the fact that the important check was
manual, skipped, TODO, or expected to fail. That creates false confidence during
review and acceptance.

## What Changed

- CI manifests now expose skipped/deferred evidence metadata.
- Manual/descriptive verification is recorded as skipped acceptance evidence.
- Evidence validation refuses skipped own-ticket verification unless the ticket
  is explicitly documentation or test-discovery work.
- TODO/FIXME or expected-failure evidence must name follow-up tickets unless it
  is covered by that explicit exception.

## What I Should Know

This does not weaken acceptance. It makes acceptance more conservative when the
evidence says "passed" but the ticket's own verification was actually skipped.

## What To Check

- `reports/evidence/POS-0104/manifest.json`
- `./tests/run-evidence-quality.sh`
- `bats tests/palari_acceptance.bats`
- `./tests/run-cli-structure.sh`

## Recommended Next Move

Run fresh-context review for POS-0104. If the reviewer agrees the evidence
truthfulness boundary is correct, leave POS-0104 in review for founder
acceptance.
