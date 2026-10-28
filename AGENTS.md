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

## Design documents — pick the right class, change it the right way

- **Pick the class by intent** (`docs/design/README.md` is the map):
  - **ADR** (`docs/design/adr/`) — a settled decision and its reasons (ADR-0001).
  - **Proposal** (`docs/design/proposals/`) — an implementation plan or milestone scope;
    ratified draft → accepted (ADR-0003).
  - **Spec** (`docs/design/specs/`) — a normative, versioned compatibility contract
    (bytes, wire format, conformance) (ADR-0003).
  - **Architecture overview** (`docs/design/architecture/`) — the living description of
    the current system; update it in the same PR whenever the system changes.
  - **Review** (`docs/design/reviews/`) — a dated go/no-go or readiness assessment.
- **Start from the template** in `docs/design/templates/` and add a row to the class index.
- **Changing a ratified doc = supersede, never rewrite.** Once an ADR is Accepted, a
  proposal accepted or a spec stable, its file is frozen (`docs-immutability` enforces
  this). To change it, write a **new** doc carrying `supersedes: <old>`, change only the old
  file's `status:` to superseded (optionally adding `superseded-by:`) and nothing else, and
  mark it superseded in the class index (ADR-0004). Small implementation facts go in the
  living architecture or code comments, not back into an accepted proposal.
- **Security-relevant changes** update the threat model (`docs/design/architecture/14-threat-model.md`
  and the summary in `.oss-scanner/threat_model.md`) in the same PR.
- **Leave the `How to fill this in` blocks to the maintainer** unless the task is to fill
  that document in.
