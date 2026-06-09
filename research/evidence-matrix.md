# Palari Safety And Performance Evidence Matrix

Last updated: 2026-06-09

This matrix separates external evidence anchors from claims Palari must measure
directly. External anchors can justify why a control belongs in the Palari
design, but they do not prove Palari improves safety, speed, quality, or market
adoption in a real team.

## Evidence Status Legend

| Status | Meaning | Allowed use |
| --- | --- | --- |
| External anchor | A standard, guidance document, benchmark, or study supports the control shape or measurement concept. | Use as rationale for design controls and research hypotheses. |
| Palari-measurable | The claim depends on Palari-specific data from pilots, benchmarks, CI evidence, review outcomes, or user research. | Use only as a hypothesis until measured. |
| Unsupported | The current evidence set does not support the claim, or the claim is too broad to verify. | Do not use as a research or product claim without narrowing and measurement. |

## Palari Design Controls

| Control | Research meaning |
| --- | --- |
| Scoped tickets | Work has a declared goal, risk tier, non-goals, allowed paths, forbidden paths, and verification commands. |
| Roles | Authority is explicit and narrowed from parent role to delegated role to ticket. |
| Worktrees | Substantive edits happen on a ticket branch/worktree, reducing collisions with parallel agents and unrelated user changes. |
| Evidence bundles | `palari ci` records verification logs, JUnit, SARIF, and integrity manifests for later review and acceptance. |
| Review packets | Specialists and reviewers receive scoped packets that bind context, authority, verification, reports, and evidence. |
| CI gates | Scope checks, lint/report gates, and ticket verification commands turn claims into repeatable checks. |
| Human acceptance | `palari accept` is separate from implementation and review; humans or authorized acceptors own final risk acceptance. |

## Source Anchors

| Source / anchor | What it supports | Palari controls mapped | Claim labels | Evidence status | Source-quality note |
| --- | --- | --- | --- | --- | --- |
| [NIST AI RMF 1.0](https://www.nist.gov/publications/artificial-intelligence-risk-management-framework-ai-rmf-10) and [AI RMF overview](https://www.nist.gov/itl/ai-risk-management-framework) | AI systems need governed risk identification, measurement, management, and accountability across design, development, use, and evaluation. | Scoped tickets, roles, evidence bundles, review packets, CI gates, human acceptance | Safety, governance | External anchor | Official NIST voluntary framework, consensus-oriented and broad. Strong for control rationale; not an empirical Palari performance study. |
| [NIST SSDF SP 800-218 v1.1](https://csrc.nist.gov/pubs/sp/800/218/final) | Secure development benefits from practices integrated into the SDLC, shared vocabulary, vulnerability reduction, and traceable secure-software work. | Scoped tickets, worktrees, evidence bundles, review packets, CI gates, human acceptance | Safety, governance | External anchor | Official NIST secure software guidance. Strong for SDLC control mapping; not AI-agent-specific and not proof of Palari efficacy. |
| [OWASP Top 10 for LLM Applications 2025](https://genai.owasp.org/resource/owasp-top-10-for-llm-applications-2025/) and [OWASP LLM project page](https://owasp.org/www-project-top-10-for-large-language-model-applications/) | LLM applications face prompt injection, sensitive information disclosure, supply-chain, excessive agency, overreliance, and resource-consumption risks. | Scoped tickets, roles, CI gates, review packets, human acceptance | Safety, governance | External anchor | Community-maintained OWASP security guidance. Practical and recognizable to AppSec teams; not a compliance certification or measured Palari mitigation result. |
| [OWASP Top 10 for Agentic Applications 2026](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/) | Agentic systems add risks around autonomous planning, tool use, identity, cascading actions, human-agent trust, and rogue or misaligned agents. | Scoped tickets, roles, worktrees, evidence bundles, review packets, CI gates, human acceptance | Safety, governance, market signal | External anchor | OWASP GenAI Security Project guidance with industry/research/practitioner input. Useful agent-specific threat taxonomy; mitigations still need local validation. |
| [SWE-bench](https://www.swebench.com/original.html), [SWE-bench paper](https://arxiv.org/abs/2310.06770), and [SWE-bench Verified](https://openai.com/index/introducing-swe-bench-verified/) | Repository-level issue resolution can be benchmarked with issue descriptions, real codebases, patches, and tests. Verified adds human screening for better-scoped issues. | Scoped tickets, worktrees, evidence bundles, CI gates, review packets | Performance, market signal | External anchor for benchmark vocabulary; Palari-measurable for Palari scores | Stronger than toy coding tasks for repository work, but still benchmark-bound. OpenAI later warned that SWE-bench Verified no longer measures frontier coding capabilities well because of contamination and residual test validity issues: https://openai.com/index/why-we-no-longer-evaluate-swe-bench-verified/. |
| [METR task-completion time horizons](https://metr.org/time-horizons/) and [Measuring AI Ability to Complete Long Software Tasks](https://arxiv.org/abs/2503.14499) | Long-horizon agent capability should be expressed as reliability over tasks grouped by human-estimated task duration, not as anecdotal "it worked" stories. | Scoped tickets, worktrees, evidence bundles, CI gates, review packets, human acceptance | Safety, performance | External anchor for measurement method; Palari-measurable for Palari task completion | Useful operational metric for agent capability and risk. METR notes task distributions are limited and cleaner than many real jobs, so Palari needs its own messy-task measurements. |
| [Peng et al., GitHub Copilot productivity RCT](https://arxiv.org/abs/2302.06590) and [early-2025 experienced OSS developer RCT](https://arxiv.org/abs/2507.09089) | AI coding-assistant productivity is context-sensitive: controlled/simple tasks and mature-project maintenance can produce different productivity effects. | Evidence bundles, review packets, CI gates, human acceptance | Performance, market signal | External anchor for hypothesis framing; Palari-measurable for Palari productivity | Randomized studies are higher quality than surveys, but samples, tasks, tools, and developer populations differ. They do not justify a blanket Palari speedup claim. |

## External-Anchor Claims

| Claim | Label | Evidence status | External support | Palari controls | Boundary |
| --- | --- | --- | --- | --- | --- |
| Scoped, reviewable agent work is aligned with recognized AI risk governance practice. | Governance | External anchor | NIST AI RMF | Scoped tickets, roles, review packets, human acceptance | Alignment claim only; not evidence that Palari reduces incidents. |
| Ticket-level path boundaries, CI checks, reports, and evidence bundles align with secure SDLC practices. | Safety | External anchor | NIST SSDF | Scoped tickets, worktrees, evidence bundles, CI gates | Supports control choice; vulnerability reduction must be measured in Palari. |
| Agents need explicit constraints against excessive agency, unsafe tool use, prompt injection effects, overreliance, and supply-chain exposure. | Safety | External anchor | OWASP LLM and agentic guidance | Scoped tickets, roles, CI gates, review packets, human acceptance | Supports threat model; does not prove any single Palari gate blocks all instances. |
| Repository-level issue-resolution benchmarks are relevant to coding-agent evaluation. | Performance | External anchor | SWE-bench and SWE-bench Verified | Scoped tickets, worktrees, CI gates, evidence bundles | Use as benchmark vocabulary, not as proof of production usefulness. |
| Long-task agent capability should be measured by success probability over human-estimated task duration. | Performance | External anchor | METR long-task research | Scoped tickets, worktrees, evidence bundles, review packets | Palari must define its own task suite and reliability threshold. |
| Productivity claims for AI coding workflows must be measured in the target context. | Performance | External anchor | AI coding-assistant RCTs | Evidence bundles, CI gates, review packets, human acceptance | Existing studies motivate measurement; they do not transfer directly to Palari. |

## Palari-Measurable Claims

| Claim to measure | Label | Evidence status | Minimum direct measurement | Suggested evidence source |
| --- | --- | --- | --- | --- |
| Palari reduces out-of-scope or forbidden file changes by coding agents. | Safety | Palari-measurable | Rate of scope-check failures, forbidden-path touches, reviewer-found scope escapes, and accepted-ticket scope defects. | `palari scope-check`, SARIF, reviewer notes, accepted/reopened ticket history. |
| Palari improves auditability of AI-agent work. | Governance | Palari-measurable | Percentage of tickets with complete reports, verification logs, manifests, reviewer notes, and clear acceptor identity. | `reports/**`, `reports/evidence/**`, ticket lifecycle state. |
| Palari reduces unsafe autonomous completion or self-acceptance. | Safety | Palari-measurable | Count of rejected acceptance attempts, missing-review gates, stale evidence rejections, and human override/escalation events. | `palari accept` output, ticket audit logs, reviewer notes. |
| Palari improves reviewer efficiency. | Performance | Palari-measurable | Reviewer time to decision, number of clarification loops, reopened tickets, defects found after review, and evidence lookup time. | Pilot timing logs, review packets, reviewer notes. |
| Palari improves implementation throughput without reducing quality. | Performance | Palari-measurable | Cycle time from claim to in-review/acceptance, task success rate, CI pass rate, reopen rate, and post-acceptance defect rate. | Ticket timestamps, CI evidence, downstream defect tracking. |
| Palari helps agents complete longer or messier tasks safely. | Safety, performance | Palari-measurable | Success probability by human-estimated task duration and messiness score, including failure severity and recovery path. | Palari benchmark task suite, METR-style time bins, reviewer adjudication. |
| Palari is valuable to target teams or buyers. | Market signal | Palari-measurable | Pilot retention, repeat use, willingness to pay, procurement/security-review feedback, and qualitative user interviews. | Product analytics, sales notes, research interviews. |

## Unsupported Claims - Do Not Use

| Unsupported claim | Label | Why unsupported | What would make it measurable |
| --- | --- | --- | --- |
| "Palari makes AI coding agents safe." | Safety | Too broad; safety depends on model, tool permissions, environment, task, review quality, and acceptance behavior. | Narrow to specific harms and measure incident rates, escape rates, and mitigation effectiveness. |
| "Palari prevents prompt injection, data leakage, supply-chain compromise, or rogue-agent behavior." | Safety | OWASP identifies these risks, but no Palari-specific red-team or incident evidence proves prevention. | Threat-specific tests, red-team tasks, blocked-action logs, and residual-risk review. |
| "Palari guarantees secure code." | Safety | NIST SSDF supports secure-development practices, not guarantees. CI and review can miss defects. | Security defect rates, vulnerability classes, severity, exploitability, and post-acceptance findings. |
| "Palari always makes developers or agents faster." | Performance | Productivity studies are mixed and context-bound; governance can add overhead. | Controlled pilots comparing cycle time, quality, review load, and rework with and without Palari. |
| "SWE-bench Verified scores prove real-world coding-agent readiness." | Performance | Verified is useful but has known contamination and test-validity limitations for frontier models. | Use fresh or private tasks, hidden tests, human adjudication, and production-like acceptance criteria. |
| "NIST AI RMF, NIST SSDF, or OWASP compliance has been achieved." | Governance | These sources are guidance/standards anchors here; this matrix is not an audit or certification. | Formal control mapping, evidence collection, independent review, and explicit compliance scope. |
| "Market demand for Palari is proven." | Market signal | Standards and benchmarks show attention to the problem space, not buyer adoption of Palari. | Measured pilots, customer commitments, procurement feedback, and churn/retention data. |

## Measurement Backlog

| Measurement | Primary label | Why it matters | Candidate owner |
| --- | --- | --- | --- |
| Scope-escape rate per ticket and per agent | Safety | Directly tests the scoped-ticket/worktree control claim. | Safety Reviewer |
| Evidence completeness score | Governance | Tests whether review packets and evidence bundles are reliable enough for acceptance. | Research Evaluator |
| Review effort and reopen rate | Performance | Tests whether Palari helps or burdens reviewers. | Research Evaluator |
| Time-to-accepted with quality guardrails | Performance | Tests throughput without confusing speed with correctness. | Research Lead |
| Agentic threat red-team suite | Safety | Tests OWASP-derived risks against Palari controls. | Safety Reviewer |
| Task success by human-estimated duration | Performance | Connects Palari benchmarks to METR-style long-task reliability. | Research Evaluator |
| Pilot adoption and willingness-to-pay evidence | Market signal | Separates real demand from standards/benchmark interest. | Founder or Research Lead |
