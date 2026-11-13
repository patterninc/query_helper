# AGENTS.md

Guidance for AI agents (and humans) working in `patterninc/query_helper`.

## What this repo is

`query_helper` is a Ruby gem, published to the `patterninc` GitHub Packages registry, that adds pagination, sorting, filtering,
text search and association loading to Rails API endpoints, driven by URL params
(`page`, `per_page`, `sort`, `sort_tiebreak`, `custom_sort`, `filter[...]`, `search_for`, `include`).
It works on ActiveRecord relations and on raw SQL strings by parsing the SQL and inserting
`where` / `having` / `qualify` / `order by` / `limit` clauses into it.

- It is a **library**. It is not deployed anywhere and has no AWS, database or runtime
  infrastructure of its own. A "release" is a gem version pushed to GitHub Packages.
- Generated SQL targets **Postgres** (e.g. `ilike`, `::varchar`, `nulls last`,
  `count(*) over ()`). The spec suite runs on in-memory **SQLite**; see
  [ADR 0001](docs/adr/0001-postgres-first-sql-generation.md).
- The repo is **public**. Do not commit internal URLs, ticket links, account ids or secrets.

User-facing docs live in [README.md](README.md). The breaking changes and upgrade notes for each
release are in [CHANGELOG.md](CHANGELOG.md).

## Layout

```text
lib/
  query_helper.rb                    # QueryHelper class: options, update, build_query, results, pagination
  query_helper/
    query_helper_concern.rb          # Rails controller concern: turns request params into a QueryHelper
    sql_parser.rb                    # Finds clause positions in raw SQL (strings/subqueries are "whited out")
    sql_manipulator.rb               # Inserts where/having/qualify/order by/limit + count(*) over () into the SQL
    column_map.rb                    # alias -> SQL expression map: custom mappings, select aliases, model attributes
    sql_filter.rb                    # filter[...] params -> Filter objects -> where/having/qualify clauses
    filter.rb                        # One filter: operator code -> SQL operator, criterion validation, bind variable
    sql_sort.rb                      # sort / sort_tiebreak / column_sort_order -> order by clauses
    associations.rb                  # include param: allowlist check, preload, as_json, sensitive-attribute stripping
    invalid_query_error.rb           # QueryHelper::InvalidQueryError (raised for any bad request input)
    version.rb                       # QueryHelper::VERSION
spec/
  spec_helper.rb                     # In-memory SQLite schema (parents, children) seeded with Faker data
  fixtures/                          # Minimal Rails app, routes, controllers, models, example SQL queries
  query_helper/*_spec.rb             # Unit specs per component
  rails_integration_spec.rb          # Controller specs through QueryHelperConcern
bin/setup, bin/console               # bundle install / IRB with the gem loaded
.github/workflows/
  ci.yml                             # bundle exec rspec spec (Ruby 2.7.8) on every push
  brakeman.yml                       # Brakeman 5.4.1 on every push
  publish_github_packages.yml        # On a version bump merged to master: test, build, push to GitHub Packages, tag
  backfill_github_packages.yml       # Manual: publish already-released tags (default: the ones apps pin) to GitHub Packages
docs/adr/                            # Architecture decision records
.agents/
  pattern-agents.json                # Oly agent-dispatch manifest
  skills/                            # Repo-local agent skills (release, add a filter operator)
```

## Commands

Prerequisites: Ruby 2.7.8 (what CI uses, the last 2.7 patch release; the gemspec allows `>= 2.6.0`), Bundler 2.2.x (lockfile
is `BUNDLED WITH 2.2.29`), and a C toolchain for the `sqlite3` and `nokogiri` native extensions.
You do **not** need Postgres to run the tests.

```bash
gem install bundler -v 2.2.29
bundle install                       # or bin/setup

bundle exec rspec spec               # full suite, exactly what CI runs
bundle exec rspec spec/query_helper/filter_spec.rb      # one file
bundle exec rspec spec/query_helper/filter_spec.rb:10   # one example
bundle exec rake                     # default task = spec

gem install brakeman -v 5.4.1 && brakeman --color --force -q   # static analysis, as in brakeman.yml
bin/console                          # IRB with query_helper loaded
gem build query_helper.gemspec       # build the .gem locally (never push it by hand)
```

There is no RuboCop or other linter configured. Brakeman is the only static check. There is no
Terraform in this repo.

## Release / deploy flow

There is no deployment. Releases go to the GitHub Packages RubyGems registry
(`https://rubygems.pkg.github.com/patterninc`), automatically ([ADR 0003](docs/adr/0003-publish-to-github-packages.md)):

1. Bump `QueryHelper::VERSION` in `lib/query_helper/version.rb` and run `bundle install` so the
   `query_helper (x.y.z)` line in `Gemfile.lock` matches.
2. Add a `## x.y.z` section to `CHANGELOG.md`. Breaking changes and upgrade notes are required for
   anything that changes behavior callers rely on.
3. Merge to `master` through a PR, with CI and Brakeman green.
4. The merge triggers the publish workflow, which runs the specs, builds the gem, pushes it with the
   built-in `GITHUB_TOKEN`, then tags `vx.y.z` and creates a GitHub release. A version that is
   already tagged is skipped. There is no tag step for a human and no API-key secret.

Known state: `publish_github_packages.yml` replaced `publish_rubygems.yml`, which failed on `v1.0.0`
and pushed to rubygems.org. The package is private to the org by default and its access is
managed in the package settings, not the repo (see the ADR). Never make it public: that can't be undone.

See [.agents/skills/release-gem/SKILL.md](.agents/skills/release-gem/SKILL.md) for the step-by-step.

## Conventions

- Plain Ruby, no Zeitwerk. Every file under `lib/query_helper/` is required explicitly from
  `lib/query_helper.rb`, and files require their own dependencies (`require "query_helper/..."`).
- Everything lives under the `QueryHelper` class namespace (`QueryHelper::SqlFilter`, etc.).
- Keyword arguments with defaults for constructors and `update`. Add new options to both
  `initialize` and `update` in `lib/query_helper.rb`, and document them in the README.
- **Any invalid request input raises `QueryHelper::InvalidQueryError`.** Never let it raise
  `NoMethodError`/`ArgumentError`, and never silently ignore it. Host apps rescue this one class
  and return a 400.
- **Values reach SQL only as bind variables** (`:name` placeholders resolved by
  `sanitize_sql_array` / `find_by_sql`). Identifiers reach SQL only through a `ColumnMap`
  lookup. Literals that must be inlined (e.g. `column_sort_order` values) go through
  `ActiveRecord::Base.connection.quote`. See [ADR 0002](docs/adr/0002-url-param-security-model.md).
- `Filter` generates random 20-letter bind-variable names. Specs match generated SQL with
  regexes (`/:[a-z]+/`), not exact strings.
- Specs use RSpec `expect` syntax with monkey patching disabled (`RSpec.describe`, not `describe`).
  Seed data is random (Faker), so assert on shape and relationships, not on fixed values.
- Every behavior change needs a spec in `spec/query_helper/` or `spec/rails_integration_spec.rb`.
  Every security-relevant change also needs a spec that sends the hostile input.
- Rails compatibility: the gem supports ActiveRecord/ActiveSupport `> 5`. The lockfile pins 6.1
  for development. Keep the existing pre/post Rails 7 fallbacks (e.g. `Preloader` in
  `associations.rb`) unless you are deliberately dropping support, and record that in the CHANGELOG.

## Guardrails

Do:

- Run `bundle exec rspec spec` before opening a PR, and say in the PR if you could not.
- Keep the README "Security" section and CHANGELOG in sync with any change to what URL params
  can reach.
- Keep new SQL Postgres-compatible. If the SQLite test DB can't express it, branch on
  `ActiveRecord::Base.connection.adapter_name` the way `sql_sort.rb` does.
- Record a new ADR in `docs/adr/` when you change a design decision (SQL dialect, parsing
  approach, security model).

Don't:

- Don't interpolate request params into SQL, and don't `send` / `constantize` user-supplied
  strings.
- Don't widen what URL params can reach (unlisted includes, sensitive columns, unmapped
  identifiers) by default. New exposure must be opt-in, like `QueryHelper.allow_unlisted_includes`.
- Don't loosen or delete security specs to make a change pass.
- Don't bump `VERSION`, push `v*` tags or publish the gem anywhere unless a maintainer asked for a
  release. Merging a version bump publishes it.
- Don't edit `.github/workflows/` from an agent. Put the proposed diff in the PR description instead.
- Don't add `sqlite3` (or any database adapter) back as a runtime dependency. It is development-only.
- Don't commit secrets, `.env` files, internal links or account ids. The repo is public.
- Don't add a `CLAUDE.md`. This file is the agent entry point.
