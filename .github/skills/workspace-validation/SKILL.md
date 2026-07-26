---
name: workspace-validation
description: Validate a repository after code changes by detecting and running safe lint, type-check, test, and build commands. Use after implementation, refactoring, dependency changes, or before a commit.
---

# Workspace validation

1. Check `git status --short`.
2. Inspect the repository's package or build metadata.
3. Prefer existing scripts over invented commands.
4. Run non-destructive checks in this order when available:
   - formatting check
   - lint
   - type-check
   - tests
   - build
5. Do not use force flags or modify dependencies merely to make validation pass.
6. Record each command, exit code, and concise result.
7. If a command fails, identify whether the failure appears pre-existing or caused by the current changes.
8. End with a pass/fail summary and any unvalidated areas.

On Windows, prefer the repository script `scripts/Test-AgentWorkspace.ps1` when present.
