# Palari Research Claims Safety Review

Last updated: 2026-06-09

## Plain-English summary for a founder/operator

Palari can safely say that the current research package defines a careful way
to study AI-agent governance. The package describes scoped tickets, role
boundaries, evidence bundles, review gates, and final human acceptance as
controls to test, and it separates external standards or benchmark references
from Palari-specific results.

Palari cannot yet say that it makes agents safer, faster, more compliant, or
more valuable in production. The artifacts are research setup, not pilot
results. They support cautious statements about what Palari intends to measure
and why those measurements matter. Any public-facing claim that Palari improves
safety, delivery speed, reviewer efficiency, compliance, or buyer adoption
needs pilot evidence and Human acceptance before publication.

## Reviewed artifacts

- `research/agent-governance-study-protocol.md`
- `research/evidence-matrix.md`
- `research/benchmark-task-suite.md`
- `research/pilot-scoring-rubric.md`
- `research/pilot-data-capture-template.md`
- `reports/POS-0019-reviewer-note.md`
- `reports/POS-0020-reviewer-note.md`
- `reports/POS-0021-reviewer-note.md`
- `reports/POS-0022-reviewer-note.md`
- `reports/evidence/POS-0019/`
- `reports/evidence/POS-0020/`
- `reports/evidence/POS-0021/`
- `reports/evidence/POS-0022/`

## Claim tiers

### Safe to say now

- Palari has a research protocol for comparing a normal AI coding-agent
  workflow with a Palari-governed workflow on matched repository tasks.
- The research design treats the first pilot as directional governance
  evidence, not proof that Palari guarantees agent safety or delivery
  improvement.
- The evidence matrix maps recognized external anchors, including NIST, OWASP,
  SWE-bench, METR-style task-duration measurement, and coding-assistant
  productivity studies, to Palari control rationale and measurement concepts.
- The package distinguishes external-anchor claims from Palari-measurable
  claims and unsupported claims.
- The benchmark task suite is a design and manifest template for future pilot
  work, not a completed benchmark result.
- The scoring rubric separates safety outcomes, performance outcomes, and
  operator comprehension, and warns against treating speed as safety.
- The data capture template records baseline-agent and Palari-governed runs
  separately, including status, owner/role, evidence, next action, acceptance
  readiness, and escalation needs.
- Human acceptance remains the final authority. A passed Palari gate is
  evidence for review, not permission to merge, deploy, publish, or accept work.

### Needs pilot evidence

- Palari reduces out-of-scope edits, forbidden-path touches, lifecycle bypasses,
  or evidence gaps.
- Palari improves auditability, reviewer efficiency, operator comprehension, or
  next-action clarity.
- Palari improves implementation throughput, time to ready, time to acceptance,
  first-pass verification rate, or rework rate.
- Palari helps agents complete longer or messier tasks safely.
- Palari reduces post-acceptance corrections, reopen events, or acceptance
  reversals.
- Palari is valuable to target teams or buyers.
- Palari-governed work compares favorably with baseline-agent work in this
  repository or any other repository.

### Unsupported claims

- "Palari makes AI coding agents safe."
- "Palari prevents prompt injection, data leakage, supply-chain compromise, or
  rogue-agent behavior."
- "Palari guarantees secure code."
- "Palari always makes developers or agents faster."
- "SWE-bench Verified scores prove real-world coding-agent readiness."
- "NIST AI RMF, NIST SSDF, or OWASP compliance has been achieved."
- "Market demand for Palari is proven."
- "Palari CI evidence proves production readiness."
- "A reviewer note or technical report replaces founder/operator judgment."

These claims should not be used without narrowing them into measurable claims
and collecting direct Palari evidence.

### Claims requiring Human acceptance before publication

- Any claim that Palari improves safety, governance, performance, reviewer
  efficiency, or market adoption, even if pilot data later supports it.
- Any claim using external standards, benchmarks, or studies in public-facing
  material, because source freshness and interpretation must be checked near
  publication time.
- Any customer, investor, sales, compliance, or security-review claim that could
  affect business reliance on Palari.
- Any claim that summarizes pilot results, because the human acceptor must
  confirm the sample, exclusions, confounders, failed checks, and limitations.
- Any decision to omit negative outcomes, failed checks, reopen events, or
  unsupported claims from public materials.

Human acceptance is the final publication gate. The research package can inform
the decision, but it does not grant publication authority by itself.

## Authority model review

The research tickets preserve Palari's authority model in substance:

- POS-0019 defines the Palari-governed workflow as ticketed, claimed,
  scope-bound, reviewed, and human-accepted. It explicitly says the performing
  agent is not the final acceptor.
- POS-0020 maps scoped tickets, roles, worktrees, evidence bundles, review
  packets, CI gates, and human acceptance to the governance model without
  claiming those controls prove Palari efficacy.
- POS-0021 makes the Baseline workflow fair but excludes Palari lifecycle
  commands from baseline runs, keeping the governance layer as the variable
  under test.
- POS-0022 records unauthorized lifecycle actions, stale review state, unsafe
  escalation handling, owner/role clarity, and acceptance readiness.

Authority-model risk is low for the research package, with two caveats. First,
the broad ticket allowed paths overlap across POS-0019 through POS-0023, so
future operators should keep actual edits narrower than the broad research
scope. Second, accepted reviewer notes for POS-0019 through POS-0022 are review
recommendations for research setup; they are not human publication acceptance.

## Negative outcomes and failure modes review

The metrics include negative outcomes and failure modes. POS-0019 tracks scope
violations, forbidden-path touches, lifecycle bypasses, evidence gaps, safety
findings, overclaiming, and acceptance reversals. POS-0021 records failed or
irreproducible checks, task exclusions, baseline strengths, Palari weaknesses,
environment noise, and residual risk. POS-0022 scores missing evidence,
unauthorized lifecycle actions, stale review state, unsafe escalation handling,
CI failures, rework cycles, and unresolved ambiguity.

The most important protection is that failed checks and missing data remain in
the dataset. Future pilot reports should preserve raw timings, findings,
failed evidence, reopened tickets, exclusions, and qualitative notes alongside
any score or summary.

## Evidence bundles, review gates, and human acceptance

The package represents evidence bundles accurately as audit material, not as
proof of product claims. The reviewed POS-0019 through POS-0021 evidence
bundles show passing Palari CI evidence against `origin/main`. The POS-0022
evidence bundle records a failed report-lint gate caused by the then-missing
fresh-context reviewer note; the later reviewer note treats that as an expected
pre-review artifact gate, not as a research-safety blocker.

Review gates are represented accurately: specialist artifacts, technical
reports, CI evidence, and reviewer notes prepare a ticket for decision, but do
not accept it. Human acceptance is represented accurately as the final
authority for acceptance and publication. Public claims should not imply that
evidence bundles, reviewer notes, or Palari CI replace human judgment.

## Recommendation

Recommendation: needs-human.

The research package is safe to use internally as a research design and as a
claim-safety checklist. It should not be published or used for customer,
investor, compliance, or sales claims until a human/founder accepts the claim
language and confirms that any later pilot evidence, failed checks, limitations,
and unsupported claims are represented honestly.

No reopen is recommended for the existing research setup artifacts based on
this review. The required next gate is human acceptance before publication, not
agent acceptance.
