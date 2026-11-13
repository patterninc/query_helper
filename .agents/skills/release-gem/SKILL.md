---
name: release-gem
description: Prepares a query_helper release PR (version bump, Gemfile.lock, CHANGELOG entry) and explains that merging it publishes to GitHub Packages. Use when a maintainer asks to cut, prepare or bump a query_helper release. Do not use for ordinary feature or fix PRs, and never push a v* tag or publish the gem yourself.
---

# Release query_helper

## Inputs

- The new version `X.Y.Z` (ask if not given). Follow semver. Anything that makes previously
  accepted requests fail, or changes generated SQL that callers rely on, is a major bump. The 1.0.0
  CHANGELOG entry is the model.
- The changes since the last tag: `git log --oneline $(git describe --tags --abbrev=0)..HEAD`.

## Steps

1. Branch from an up-to-date `master`.
2. Set `VERSION = "X.Y.Z"` in `lib/query_helper/version.rb`.
3. Run `bundle install` so `Gemfile.lock` shows `query_helper (X.Y.Z)`. Commit only that line
   change in the lockfile. Don't also bump other gems.
4. Add `## X.Y.Z` at the top of `CHANGELOG.md` with `### Breaking`, `### Security`, `### Fixed` or
   `### Added` subsections as needed. For any breaking change, add `### Upgrade notes` that say
   exactly what callers must change.
5. Run `bundle exec rspec spec` and `gem build query_helper.gemspec`, then delete the built `.gem`.
   Both must succeed.
6. Open a PR titled `Release vX.Y.Z` with the CHANGELOG section as the body.
7. In the PR, tell the maintainer that merging it releases: the publish workflow
   (`.github/workflows/publish_github_packages.yml`) tests, builds, pushes to the
   `patterninc` GitHub Packages registry, tags `vX.Y.Z` and creates a GitHub release. No tag needs
   pushing by hand.

## Guardrails

- Never push a `v*` tag, run `rake release` or `gem push`. The workflow publishes when the
  maintainer merges the release PR.
- Never edit `.github/workflows/`. If the publish workflow needs a change, write the diff in the
  PR description. Check `.github/workflows/` actually contains `publish_github_packages.yml`
  (not the old `publish_rubygems.yml`) before promising that merging publishes.
- After the merge, check that the version shows up under the repository's Packages
  (https://github.com/orgs/patterninc/packages?repo_name=query_helper). A green run alone doesn't
  prove the gem was published.
