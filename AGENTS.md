# Agent context — {{PROJECT_NAME}}

Rules for any coding agent (Claude, Codex, or other) working **on this repository**.
[CONTRIBUTING.md](CONTRIBUTING.md) governs humans and agents alike; this file adds the
agent-specific discipline.

## STOP discipline — the merge is never yours

- **Never merge a pull request.** Not `gh pr merge`, not the web UI, not
  auto-merge — no path, regardless of green checks or how trivial the change is.
- **Never mark a draft pull request ready** (`gh pr ready`).
- Your work on a change **ends at the open PR with green checks**. Report the PR
  URL and stop. The ready-mark and the merge are the maintainer's sign-off.

## Change discipline

- Code changes start from an issue, and the PR body links it (`Closes #NNN`, or
  `Refs #NNN` for partial work). Typo and docs fixes can go without one.
- One logical change per issue / branch / PR; split unrelated changes.
- Commits are signed off (`git commit -s`, [DCO](DCO)) with a
  conventional-prefix subject (`fix:`, `feat:`, `docs:`, `ci:`, `chore:`) and a
  body that explains the why.
- You must be able to explain every line you change. The person who opens the PR
  answers for it in review.
- Keep the checks green (the command is in [CONTRIBUTING.md](CONTRIBUTING.md)).
