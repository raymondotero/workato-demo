---
name: code-review
description: Review the current implementation or Git diff for correctness, security, regressions, architecture consistency, and missing tests. Use before merging, committing, or deploying.
context: fork
---

# Code review

1. Read `AGENTS.md`.
2. Inspect `git status`, the complete diff, and relevant surrounding code.
3. Compare the implementation against the stated requirement.
4. Check security and secret handling.
5. Check error paths, edge cases, compatibility, and data integrity.
6. Verify tests cover the changed behavior.
7. Rank findings by severity and include file locations.
8. Do not praise routine work or invent defects.
9. If no material findings exist, say so and list residual validation risks.
