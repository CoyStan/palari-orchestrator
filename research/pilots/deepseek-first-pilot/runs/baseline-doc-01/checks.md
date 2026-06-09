## baseline-doc-01 checks

$ grep -q '## Limitations' adapters/opencode/README.md
pass

$ grep -q 'does not accept, merge, push, deploy, or bypass human acceptance' adapters/opencode/README.md
pass

$ git diff --check
pass
