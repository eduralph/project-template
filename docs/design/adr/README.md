---
created: {{DATE}}
type: index
tags:
  - adr
---
# Architecture Decision Records

Numbered, immutable records of significant decisions and *why* they were made. An ADR is
never edited after acceptance; a later ADR supersedes it (ADR-0004). This index is the
authoritative record of each ADR's current status. Format: the lightweight Nygard template
(ADR-0001); start from `../templates/adr.md`.

**What deserves an ADR:** a decision that later work depends on and that would be expensive
to reverse: a language or core dependency, a data format, a trust boundary, a process rule.
Not every choice does; if reversing it touches one file, it doesn't need an ADR.
Example: wyrd's [ADR index](https://github.com/getwyrd/wyrd/blob/main/docs/design/adr/README.md).

## Index

| # | Title | Status |
|---|-------|--------|
| [0001](0001-record-architecture-decisions.md) | Record architecture decisions | Accepted |
| [0002](0002-license-and-dco.md) | {{LICENSE_NAME}} and DCO sign-off | Proposed |
| [0003](0003-proposal-and-spec-process.md) | Proposal and specification process, lifecycle, and immutability | Accepted |
| [0004](0004-supersession.md) | How a frozen document is superseded | Accepted |
| [0005](0005-issue-priority-and-automated-triage.md) | Issue priority: severity and reach set P0–P3, applied by hand or by a bot | Proposed |
