# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

<!-- template:begin -->
> **This is a GitHub template repository.** It holds the repo-level setup shared by
> eduralph, Ralphovi and getwyrd projects: DCO sign-off, the agent STOP rules, a
> contributing guide that points at the
> [shared one](https://github.com/eduralph/.github/blob/main/CONTRIBUTING.md), and the PR
> triage workflow that labels code PRs without a linked issue `needs-issue` (it never
> blocks or closes them). It also ships the design-documentation layout used by
> [wyrd](https://github.com/getwyrd/wyrd/tree/main/docs): four document classes under
> `docs/design/`, governance under `docs/governance/`, and the `docs-immutability` check.
> Each file still to be written carries a **How to fill this in** block. For projects driven by the PDCA quality cycle, use
> [pdca-project-template](https://github.com/eduralph/pdca-project-template) instead.
>
> ### Start a new project
>
> ```bash
> gh repo create <owner>/<name> --public --template eduralph/project-template \
>   --description "<one line>" --clone
> cd <name>
> scripts/init-repo.sh          # asks for the license, fills placeholders, applies settings
> ```
>
> `init-repo.sh` asks which license to use (Apache-2.0 by default) and the contact address
> for conduct and policy reports, replaces the `{{…}}`
> placeholders, and commits and pushes that once to `main`. It then creates the
> `needs-issue` label, turns on private vulnerability reporting, turns off the wiki and
> protects `main` (PRs required, `dco` and `docs-immutability` checks required, admins
> included, no force-push or deletion). It removes itself and this block in the same commit. GitHub doesn't copy
> labels, settings or protection rules from a template, which is why the script exists.
<!-- template:end -->

## Status

Early.

## Documentation

[`docs/`](docs/README.md) is the map. Design documents are in [`docs/design/`](docs/design/README.md):
architecture, decision records (ADRs), proposals and specifications. Governance and the Code
of Conduct are in [`docs/governance/`](docs/governance/GOVERNANCE.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and, for coding agents, [AGENTS.md](AGENTS.md).

## License

Copyright © {{YEAR}} {{AUTHOR}}.

{{PROJECT_NAME}} is licensed under the **{{LICENSE_NAME}}** ([LICENSE](LICENSE)).

Contributions are accepted under the same license and gated on the
[Developer Certificate of Origin](DCO). Sign off commits with `git commit -s`.
