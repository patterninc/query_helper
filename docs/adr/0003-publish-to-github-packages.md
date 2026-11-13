# 0003. Publish releases to GitHub Packages, automatically on version bump

- Status: Accepted
- Date: 2026-11-12

## Context

Releases went to rubygems.org through a manual tag push and a third-party action that ran
`rake release` without the bundle installed (the `v1.0.0` run failed, so rubygems.org still lists
`0.4.0`). The gem is for Pattern's own Rails apps, not the public, so it should be installable only
by people authenticated to the `patterninc` GitHub organization.

## Decision

- Publish to the GitHub Packages RubyGems registry, `https://rubygems.pkg.github.com/patterninc`.
- Releases are automatic: a merge to `master` that changes `QueryHelper::VERSION` runs tests, builds
  the gem, pushes it with the workflow's `GITHUB_TOKEN`, then tags `vX.Y.Z` and creates a GitHub
  release. A version that already has a tag is skipped. No long-lived secret is involved.
- The gemspec sets `allowed_push_host` to the registry, so nothing can push to rubygems.org by
  accident.
- The version number stays a human decision in `version.rb`. Nothing derives it from commits.

## Consequences

- GitHub Packages RubyGems has no package-level permissions: **access is inherited from the
  repository.** While this repo is public, the package is readable by any GitHub user with a token.
  Limiting it to the organization requires making the repository private (or internal on GitHub
  Enterprise). This is a repository setting, not something the code can enforce.
- Consumers need a token with `read:packages` even to install (see the README).
- Other repositories' Actions can only install the gem if this repository's Actions access setting
  allows it (private repos: Settings > Actions > General > Access).
- Applications pin git tags today, not gem versions. `backfill_github_packages.yml` (manual) publishes
  those existing tags to the registry so apps can switch source without changing code. It publishes
  each tag under the tag's own number, because `v0.3.2` and `v0.4.1` were tagged without bumping
  `version.rb`.
- rubygems.org keeps the old `0.4.0` and `1.0.0` never reached it. New versions are not published
  there. Yank or leave `0.4.0` as the maintainers prefer.
- A push that succeeds followed by a tag step that fails leaves a published version with no tag. A
  re-run then fails on the duplicate version; push the tag by hand.
