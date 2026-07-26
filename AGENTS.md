# Shared Agent Instructions

These rules apply to GitHub Copilot, OpenAI Codex, Claude Code, and other coding agents working in this repository.

## Operating approach

- Inspect the repository before proposing changes.
- State assumptions when requirements are incomplete.
- For nontrivial work, provide a concise implementation plan before editing.
- Prefer the smallest safe change that fully solves the problem.
- Preserve existing architecture and conventions unless there is a clear reason to change them.
- Do not modify unrelated files.
- Never claim a test, build, deployment, or command succeeded unless it actually ran successfully.
- When a command cannot be run, state that clearly and provide the exact command the user should run.

## Safety and security

- Never hardcode credentials, tokens, passwords, connection strings, or private keys.
- Do not read, print, commit, or expose `.env` values or authentication files.
- Treat production data and deployment changes as high risk.
- Ask before destructive operations, schema deletion, force pushes, history rewrites, or broad dependency upgrades.
- Do not use `npm audit fix --force` without explicit approval and impact review.
- Validate user input and handle errors deliberately.
- Prefer least-privilege access and reversible changes.

## Engineering quality

- Follow the repository's existing language, framework, formatting, and naming conventions.
- Keep functions and components focused and understandable.
- Avoid unnecessary dependencies.
- Add or update tests for behavioral changes when a test framework exists.
- Run the most relevant lint, type-check, test, and build commands after changes.
- Review the final diff for accidental edits, generated files, and secrets.
- Explain material tradeoffs and remaining risks.

## Git workflow

- Check `git status` before and after work.
- Do not commit or push unless explicitly requested.
- Use descriptive, conventional commit messages when asked to commit.
- Never force-push without explicit approval.
- Keep generated artifacts and local secrets out of version control.

## Response format after implementation

Report:
1. What changed
2. Why it changed
3. Validation performed and results
4. Known limitations or follow-up items
