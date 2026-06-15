# SNP-0001 Human Report

## Why This Mattered

Company OS state needs to become visible in the same machine-readable snapshot
that the console and operators already trust.

## What Changed

SNP-0001 adds a top-level `company_os` section to `palari snapshot --json`, the
Bash snapshot fallback, and `palari web --check`.

## What I Should Know

The section reports workflow counts, human profile counts, open HGL estimate,
R3/R4/R5 decision counts, missing skills, bottlenecks, autonomy gate
distribution, simulation-only policy posture, and broker side-effect posture.

This is read-only. It does not create workflow plans, render new dashboard
cards, activate policies, run brokers, or perform side effects.

## What To Check

- Empty repos show empty counts instead of crashing.
- Populated workflow/human fixtures show HGL and missing-skill state.
- Fast snapshot performance remains acceptable.

## Founder Acceptance

Founder pre-approval from Quetzali covers this marathon's review path.
SNP-0001 is accepted after green verification because it adds read-only Company
OS snapshot visibility without enabling policy or broker authority.

## Recommended Next Move

Accept SNP-0001 after verification, then continue to DSH-0001 for console
visibility.
