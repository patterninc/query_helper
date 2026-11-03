---
name: release-gem
description: Prepares a query_helper release PR (version bump, Gemfile.lock, CHANGELOG entry) and gives the maintainer the tag command that publishes to RubyGems. Use when a maintainer asks to cut, prepare or bump a query_helper release. Do not use for ordinary feature or fix PRs, and never push a v* tag or publish the gem yourself.
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
7. In the PR, tell the maintainer to run this after merge:

   ```bash
   git checkout master && git pull
   git tag vX.Y.Z && git push origin vX.Y.Z
   ```

   The tag triggers `.github/workflows/publish_rubygems.yml` (`rake release`).

## Guardrails

- Never push a `v*` tag, run `rake release` or `gem push`. Publishing is the maintainer's step.
- Never edit `.github/workflows/`. If the publish workflow needs a change, write the diff in the
  PR description. The v1.0.0 publish failed with `LoadError: rspec/core/rake_task` because
  `rake release` ran without the bundle installed. Check whether that is fixed before promising
  the tag will publish.
- After a publish run, check that the version shows up at https://rubygems.org/gems/query_helper.
  A green tag alone doesn't prove the gem was published.
