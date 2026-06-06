# Feature Contracts And Skills Guidance

Feature contracts describe the durable behavior a ticket must preserve. Skills
describe how an agent should perform specialized work without expanding the core
orchestrator.

Use a feature contract when work changes:

- user-visible behavior
- source-of-truth rules
- data persistence
- prompts or model behavior
- external integrations
- visible UI, copy, or workflow order

Use an optional skill adapter when a recurring specialist workflow needs stable
instructions:

- browser review
- accessibility review
- migration review
- API contract review
- product-feel review profile
- release-readiness review

Keep project taste, product vocabulary, and app-specific preferences in
adapters or project skills. The core should only define the gates and evidence
shape.

Scaffold a feature-contract skill adapter with:

```bash
palari skill create feature-name --description "Preserve the feature contract for ..."
```

The generated shape follows the PRC-0066 pattern: applicability, promise,
invariants, owned files/APIs, forbidden behavior, required tests or browser
paths, gotchas, and acceptance checklist.
