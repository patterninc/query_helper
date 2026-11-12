# Architecture decision records

Each file records one design decision: its context, the decision, and its consequences. Number
records in order (`NNNN-short-title.md`), date them, and never rewrite an accepted record. When a
decision changes, add a new record that supersedes the old one and update the old one's status line.

| ADR | Title | Status |
| --- | --- | --- |
| [0001](0001-postgres-first-sql-generation.md) | Generate Postgres SQL by editing the caller's query string | Accepted |
| [0002](0002-url-param-security-model.md) | Security model for URL-param filtering, sorting and includes | Accepted |
| [0003](0003-publish-to-github-packages.md) | Publish releases to GitHub Packages, automatically on version bump | Accepted |

Template:

```markdown
# NNNN. Title

- Status: Proposed | Accepted | Superseded by NNNN
- Date: YYYY-MM-DD

## Context
## Decision
## Consequences
```
