# Claude Code Instructions

Use [AGENTS.md](./AGENTS.md) as the primary shared source of project rules.

Additional Claude-specific guidance:

- Use plan mode for broad, risky, or multi-file changes before editing.
- Prefer explicit diffs and explain any architectural departure.
- Use checkpoints before large refactors when available.
- Do not auto-approve destructive shell operations.
- After implementation, review the complete Git diff as a separate quality pass.
