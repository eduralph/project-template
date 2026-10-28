# Contributing to {{PROJECT_NAME}}

Thanks for contributing. Read the
[shared contributing guide](https://github.com/{{OWNER}}/.github/blob/main/CONTRIBUTING.md)
first. It covers when to open an issue before writing code, what won't be merged, and the
rules for AI-assisted changes. This file adds what is specific to {{PROJECT_NAME}}.

This project is licensed under the {{LICENSE_NAME}} ([LICENSE](LICENSE)); contributions
are accepted under the same license.

## Developer Certificate of Origin (sign-off)

Every commit must carry a [Developer Certificate of Origin](DCO) (DCO 1.1) sign-off. By
signing off you certify the DCO's terms for your contribution. Sign off with:

```bash
git commit -s
```

This appends a `Signed-off-by: Your Name <you@example.com>` trailer (using your
`git config user.name` / `user.email`). Amend a commit that's missing it with
`git commit --amend -s`. The `dco` check fails a PR with an unsigned commit.

## Pull requests

- Code changes link an agreed issue in the PR description (`Closes #NNN` or `Refs #NNN`).
  PRs without one get the `needs-issue` label. Typo and docs fixes don't need an issue.
- One logical change per PR; split unrelated changes.
- A change ships with the means to verify it: a test, or a stated reason why a test is
  impractical plus a manual repro.

## Running checks

_TODO: name the single command that runs the checks once they exist._
