# Engineering Best Practices Audit — query_helper

| | |
|---|---|
| **Audit date** | 2026-09-08 |
| **Auditor** | Claude — gauge-repo skill |
| **Rubric version** | `item-credit-v1` — 2026-09-04 (`references/best-practices.md`) |

## Repo profile

`query_helper` is a Ruby gem (library) published to RubyGems that adds pagination, sorting, filtering, search, and association-loading to Rails controllers via URL params against Postgres (SQLite is used only for tests). Ruby 2.7.2, RSpec for tests, Brakeman for SAST, no owned HTTP/browser surface, no owned deployment (release = `git tag v*` triggers `publish_rubygems.yml`). Multi-contributor (top 5: 154/48/32/19/17 commits) with active Dependabot bumps. GitHub owner is `patterninc` (verified via `gh repo view patterninc/query_helper --json nameWithOwner`), so inherited Wiz (items 19, 20, 47) and Toolsmith MCP (item 39) apply. No AWS footprint (nothing deployed by this repo), so item 49's `aws[]` sub-check is N/A within item 49; the core manifest itself is still applicable.

## Scorecard

| Metric | Value |
|--------|-------|
| **Critical gates** | **RED** |
| **Adjusted compliance** | **34.7%** |

Critical gate 2 (AGENTS.md) is Gap and gate 16 (required CI checks before merge) is Partial — the org `require-pr-review` ruleset enforces review on `master` but does not require the existing CI/Brakeman workflows as merge status checks. Adjusted compliance is calculated independently:

`(11 Met + 0.5 × 3 Partial) / (49 total - 13 justified N/A) = 12.5 / 36 = 34.7%`

### Status totals

| Status | Items |
|--------|------:|
| Met | 11 |
| Partial | 3 |
| Gap | 22 |
| N/A | 13 |
| **Total** | **49** |

### Per-category breakdown

| Category | Met | Partial | Gap | N/A |
|----------|----:|--------:|----:|----:|
| Documentation & Context | 1 | 0 | 6 | 2 |
| Guardrails & Enforcement | 3 | 1 | 8 | 1 |
| Testing & Feedback Loops | 2 | 2 | 6 | 3 |
| Environment & Tooling | 5 | 0 | 1 | 7 |
| Agent dispatch | 0 | 0 | 1 | 0 |
| **Total** | **11** | **3** | **22** | **13** |

## Documentation & Context

| # | Practice | Status | Evidence | Recommendation / rationale |
|---|----------|--------|----------|----------------------------|
| 1 | Skills / reusable prompt workflows | **Gap** | No `.claude/`, `.cursor/`, or prompt library in the repo | Add a `.claude/skills/` (or `AGENTS.md`) capturing gem-release, add-operator, and add-filter workflows so agents don't rebuild them each task. |
| 2 | AGENTS.md | **Gap** | Absent | Add a top-level `AGENTS.md` covering repo layout (`lib/query_helper/*`), local test command (`bundle exec rspec`), Ruby version pin (`2.7.2`), and release flow (tag `v*` triggers publish). |
| 3 | Architecture decision records | **Gap** | No `docs/adr/` or design docs | Backfill ADRs for the SQL parser/manipulator split (`lib/query_helper/sql_parser.rb`, `sql_manipulator.rb`) and the Postgres-only support decision. |
| 4 | Runbooks | **Gap** | No `docs/runbooks/`; release steps live implicitly in `publish_rubygems.yml` | Add a `docs/runbooks/release.md` covering version bump in `lib/query_helper/version.rb`, tagging, and rollback (yank) procedure. |
| 5 | API contract docs (OpenAPI/protobuf) | **Not applicable** | Ruby library, no HTTP/RPC surface it owns | Public Ruby API is documented in `README.md`; wire contracts don't apply to a gem consumed in-process. |
| 6 | README with setup and run instructions | **Met** | `README.md` covers install, `Gemfile` line, quick use, URL param reference | — |
| 7 | Changelog with migration notes | **Gap** | No `CHANGELOG.md`; version at `0.4.4` in `lib/query_helper/version.rb` | Add `CHANGELOG.md` (Keep a Changelog format) — consumers upgrading the gem have no per-version migration notes today. |
| 8 | On-call playbooks | **Not applicable** | Library, no runtime service to page on | Distributed gem — incident response happens in consuming services, not here. |
| 9 | CODEOWNERS | **Gap** | No `.github/CODEOWNERS` or root `CODEOWNERS`; 30+ contributors visible via `git shortlog` | Add `.github/CODEOWNERS` mapping `lib/` and `spec/` to the PXM team (`backstage.yaml` says `Owner: dev-pxm`). |

## Guardrails & Enforcement

| # | Practice | Status | Evidence | Recommendation / rationale |
|---|----------|--------|----------|----------------------------|
| 10 | Linters | **Gap** | No `.rubocop.yml` or equivalent Ruby linter config | Adopt RuboCop with a minimal `.rubocop.yml` and wire it into `.github/workflows/ci.yml`. |
| 11 | Formatters | **Gap** | No `.rubocop.yml` (Layout) or `standard`/`rufo` config | Same as item 10 — RuboCop Layout cops or `standard` covers formatting. |
| 12 | Type checking | **Gap** | No Sorbet (`sorbet/`) or RBS (`sig/`) files | Optional but valuable for a library — add RBS signatures for the `QueryHelper` public API in `lib/query_helper.rb`. |
| 13 | Pre-commit hooks | **Gap** | No `.pre-commit-config.yaml` or `.githooks/` | Install `pre-commit` running RuboCop and Brakeman locally so CI isn't the first line of feedback. |
| 14 | Commit message conventions | **Gap** | No `commitlint`/`.gitmessage`; recent commits show ad-hoc subjects | Adopt Conventional Commits and add a `commitlint` job — supports future changelog automation. |
| 15 | Branch protection | **Met** | Org ruleset `require-pr-review` (`gh api repos/patterninc/query_helper/rulesets/3174764`) targets `~DEFAULT_BRANCH` with required review, block deletion, block non-fast-forward | — |
| 16 | Required CI checks before merge | **Partial** | `.github/workflows/ci.yml` and `brakeman.yml` run on push, but the org ruleset has no `required_status_checks` rule — merges are not blocked on green CI | Add a required-status-checks rule to the org ruleset (or a repo-level ruleset) listing `test` and `brakeman` jobs so a red build blocks merge. |
| 17 | Dependency allow/deny lists | **Gap** | No `bundler-audit` allowlist or `.gemfile_policy` | Add `bundler-audit` (or license-check) in CI to flag disallowed/known-bad gems. |
| 18 | License compliance scanning | **Gap** | No `license_finder` / `licensee` CI job; gem is MIT (`LICENSE.txt`) | Add `license_finder` to CI so transitive-dependency license drift is caught. |
| 19 | Secret scanning | **Met** | Inherited Pattern Wiz policy (org-wide) | — |
| 20 | SAST / static analysis gates | **Met** | Inherited Pattern Wiz policy plus repo-local `.github/workflows/brakeman.yml` running `brakeman --color --force -q` on push | — |
| 21 | Max complexity limits | **Gap** | No RuboCop `Metrics` config | Enable RuboCop `Metrics/*` cops with sensible thresholds; the SQL parser/manipulator modules would benefit from an enforced ceiling. |
| 22 | Import boundary enforcement | **Not applicable** | Single-namespace gem — all code lives under `QueryHelper` in `lib/query_helper/`; no architectural layers to police | Small library with a flat module structure — an import-boundary linter would add no value. |

## Testing & Feedback Loops

| # | Practice | Status | Evidence | Recommendation / rationale |
|---|----------|--------|----------|----------------------------|
| 23 | Unit tests | **Met** | `spec/query_helper/sql_manipulator_spec.rb` and RSpec configured via `.rspec`, run in CI (`.github/workflows/ci.yml`) | — |
| 24 | Integration tests | **Met** | `spec/rails_integration_spec.rb` exercises `ParentsController` end-to-end through an in-memory SQLite fixture app (`spec/fixtures/application.rb`) | — |
| 25 | Snapshot / golden-file tests | **Partial** | `spec/fixtures/example_queries.rb` supplies expected-SQL/expected-sorts pairs (near-golden), but no diff-based snapshotting library | Consider `rspec-snapshot` for the SQL-manipulator outputs so intentional changes surface as reviewable diffs. |
| 26 | Contract tests | **Not applicable** | Ruby gem consumed in-process — no producer/consumer wire contract exists | Public Ruby API surface is documented in README and covered by unit + integration specs. |
| 27 | End-to-end tests | **Not applicable** | No owned browser UI | Library used inside consumers' Rails controllers — the integration spec is the equivalent surface. |
| 28 | Visual regression tests | **Not applicable** | No visual surface | Library with no rendered output. |
| 29 | Test coverage thresholds | **Gap** | No SimpleCov or coverage gate in CI | Add SimpleCov with a minimum-coverage gate in `.github/workflows/ci.yml`. |
| 30 | Mutation testing | **Gap** | No `mutant` or similar | Optional — consider `mutant-rspec` on `lib/query_helper/sql_filter.rb` and `sql_sort.rb` where correctness is subtle. |
| 31 | Load / performance benchmarks | **Gap** | No `benchmark/` dir | Add a benchmark for large-page queries so pagination regressions surface pre-release. |
| 32 | Flaky test quarantine | **Gap** | No quarantine convention; specs seed with Faker but no `--tag flaky` split | Adopt a `flaky` RSpec tag with a nightly job so the main CI stays green. |
| 33 | Structured CI output | **Gap** | `.rspec` uses `--format documentation` only; no JUnit XML upload | Add `--format RspecJunitFormatter --out tmp/rspec.xml` and upload as a GitHub Actions artifact. |
| 34 | Deterministic test fixtures | **Partial** | `spec/fixtures/` supplies fixed models/controllers/routes, but `spec_helper.rb` uses `Faker::Number.between(...)` without a fixed seed | Pin `Faker` with `Faker::Config.random = Random.new(1234)` in `spec_helper.rb` for reproducibility. |
| 35 | Smoke tests for deploys | **Gap** | `publish_rubygems.yml` publishes on tag but has no post-publish install-check | After `rake release`, add a step that `gem install`s the just-published version in a clean container to catch broken gemspecs. |

## Environment & Tooling

| # | Practice | Status | Evidence | Recommendation / rationale |
|---|----------|--------|----------|----------------------------|
| 36 | Devcontainer config | **Gap** | No `.devcontainer/` | Add a devcontainer pinning Ruby 2.7.2 to match CI (`GEMFILE_RUBY_VERSION` in `.github/workflows/ci.yml`). |
| 37 | One-command setup | **Met** | `bin/setup` runs `bundle install`; `bin/console` starts an IRB with the gem loaded | — |
| 38 | Seed scripts for local databases | **Not applicable** | Library — test DB is in-memory SQLite spun up by `spec/spec_helper.rb`; no persistent local DB to seed | Fixtures under `spec/fixtures/` cover the equivalent surface. |
| 39 | MCP servers | **Met** | Toolsmith-managed MCP access (inherited Pattern) | — |
| 40 | Scoped secrets per environment | **Met** | Only prod-relevant secret is `RUBYGEMS_API_KEY` in `.github/workflows/publish_rubygems.yml`, gated by tag push — single-env publish flow with no dev/staging surface | — |
| 41 | Preview environments per PR | **Not applicable** | Nothing to deploy | Distributed gem — reviewers evaluate the diff plus CI-green, not a live env. |
| 42 | Hot-reload / watch mode | **Not applicable** | Ruby library; `bin/console` covers interactive iteration | No long-running process to hot-reload. |
| 43 | Structured logging (JSON) | **Not applicable** | Library does not own its logging surface | Consumers control formatting in their Rails app. |
| 44 | Observable traces and metrics | **Not applicable** | Not a running service | Consuming services instrument their own controllers. |
| 45 | Feature flags with local overrides | **Not applicable** | Library — behavior is driven by URL params and constructor args, not runtime flags | Consumers can wrap calls in their own flag system. |
| 46 | Database migration tooling | **Not applicable** | Library does not own a schema | Consumers manage their own migrations. |
| 47 | Dependency update automation | **Met** | Inherited org-wide Wiz; Dependabot PRs also visible in `origin` branches (e.g. `dependabot/bundler/actionpack-6.1.7.9`) | — |
| 48 | Reproducible builds (lockfiles) | **Met** | `Gemfile.lock` committed and consumed by CI via `bundler-cache: true` in `ruby/setup-ruby@v1` | — |

## Documentation & Context (agent dispatch)

| # | Practice | Status | Evidence | Recommendation / rationale |
|---|----------|--------|----------|----------------------------|
| 49 | Agent-dispatch manifest | **Gap** | No `.agents/pattern-agents.json`; `backstage.yaml` names `dev-pxm` as owner but is not the Pattern agent-dispatch manifest | Add `.agents/pattern-agents.json` with `schema_version`, `github.repo = patterninc/query_helper`, PXM `clickup_list_id`, PXM Slack channel, and `datadog.service` (or omit if truly unused). No AWS footprint — `aws[]` is not required for Met on this repo. |

## Prioritized recommendations

1. **[S] Gap — AGENTS.md (critical gate 2):** Add top-level `AGENTS.md` with repo layout, `bundle exec rspec` test command, Ruby 2.7.2 pin, and the `git tag v*` release flow.
2. **[S] Partial — required CI checks (critical gate 16):** Add a `required_status_checks` rule (org ruleset or repo ruleset) listing the `test` job from `ci.yml` and `brakeman` job from `brakeman.yml` so red builds block merge.
3. **[S] Gap — agent-dispatch manifest (item 49):** Add `.agents/pattern-agents.json` with GitHub repo, PXM ClickUp list, PXM Slack, and Datadog service metadata.
4. **[S] Gap — CODEOWNERS (item 9):** Add `.github/CODEOWNERS` mapping `lib/` and `spec/` to the PXM team named in `backstage.yaml`.
5. **[S] Gap — CHANGELOG (item 7):** Add `CHANGELOG.md` (Keep a Changelog) and backfill entries from git tags starting at `0.4.4`.
6. **[S] Gap — linter + formatter (items 10, 11, 21):** Add `.rubocop.yml` (Layout, Style, Metrics) and a `rubocop` step in `ci.yml`.
7. **[M] Gap — test coverage gate (item 29):** Add SimpleCov with a minimum-coverage threshold in `ci.yml`.
8. **[S] Partial — deterministic fixtures (item 34):** Seed Faker in `spec/spec_helper.rb` (`Faker::Config.random = Random.new(1234)`).
9. **[S] Gap — structured CI output (item 33):** Emit JUnit XML from RSpec and upload as a GitHub Actions artifact.
10. **[S] Gap — dependency + license scanning (items 17, 18):** Add `bundler-audit` and `license_finder` jobs in `ci.yml`.
11. **[M] Gap — Skills / AGENTS content (items 1, 3, 4):** Add `.claude/skills/` (or expand AGENTS.md) covering gem-release, add-operator, and add-filter workflows; backfill ADRs and a release runbook under `docs/`.
12. **[S] Partial — snapshot tests (item 25):** Add `rspec-snapshot` for SQL manipulator outputs.
13. **[S] Gap — post-publish smoke (item 35):** Add a step in `publish_rubygems.yml` that `gem install`s the published version in a clean job after tag publish.
14. **[M] Gap — devcontainer (item 36):** Add `.devcontainer/` pinning Ruby 2.7.2.
15. **[S] Gap — pre-commit + commit conventions (items 13, 14):** Adopt `pre-commit` running RuboCop/Brakeman locally and Conventional Commits with a `commitlint` job.
16. **[L] Gap — type checking (item 12):** Add RBS signatures for the `QueryHelper` public API.
17. **[L] Gap — mutation + benchmarks (items 30, 31):** Add `mutant-rspec` on the SQL modules and a `benchmark/` for pagination hot paths.
18. **[S] Gap — flaky test quarantine (item 32):** Adopt a `flaky` RSpec tag with a nightly job.

## Declined practices

| # | Practice | Rationale |
|---|----------|-----------|
| 5 | API contract docs (OpenAPI / protobuf) | Ruby gem consumed in-process — no wire contract to formalize. Public Ruby API is in `README.md`. |
| 8 | On-call playbooks | Library, no runtime service — incident response belongs to consumers. |
| 22 | Import boundary enforcement | Single-namespace gem with flat module structure under `lib/query_helper/`; no architectural layers to police. |
| 26 | Contract tests | In-process Ruby API — no producer/consumer wire contract. |
| 27 | End-to-end tests | No owned browser UI; `spec/rails_integration_spec.rb` covers the equivalent full-stack surface. |
| 28 | Visual regression tests | No visual surface. |
| 38 | Seed scripts for local databases | Test DB is in-memory SQLite bootstrapped by `spec/spec_helper.rb`; no persistent local DB. |
| 41 | Preview environments per PR | Distributed gem — nothing to deploy. |
| 42 | Hot-reload / watch mode | Ruby library; `bin/console` covers interactive iteration. |
| 43 | Structured logging (JSON) | Library does not own its logging surface. |
| 44 | Observable traces and metrics | Not a running service. |
| 45 | Feature flags with local overrides | Behavior driven by URL params and constructor args, not runtime flags. |
| 46 | Database migration tooling | Library does not own a schema. |

## Beyond the checklist

- `backstage.yaml` catalogues the repo (Owner `dev-pxm`, System `pxm`), giving discoverability inside Backstage even without an agent-dispatch manifest.
- CI pins Ruby explicitly via `GEMFILE_RUBY_VERSION: 2.7.2` and consumes `bundler-cache: true` from `ruby/setup-ruby@v1` — reproducible test environment even without a devcontainer.
- Fixture Rails app under `spec/fixtures/` (application, controllers, models, routes, example_queries) lets integration specs exercise a real controller pipeline without requiring host-app setup.
- Brakeman is wired in as its own workflow (`.github/workflows/brakeman.yml`) in addition to the inherited Wiz SAST, giving Ruby-specific findings on every push.
