# DSF-EVD-02 Timing

- Start: `2026-06-10T02:11:05Z`
- End: `2026-06-10T02:16:21Z`
- Exit code: `0`
- Approximate wall time: 5 minutes 16 seconds
- Operator interventions: added an explicit repository-root instruction before
  first run due the DSF-GOV-02 path-root failure, manually merged the
  `tests/run-cli-structure.sh` hunk with DSF-TST-01's earlier block, and added
  generated-manifest metadata so future Palari CI evidence contains a literal
  manifest reference.
- Rework cycles: 0 model reruns; 1 operator integration adjustment
