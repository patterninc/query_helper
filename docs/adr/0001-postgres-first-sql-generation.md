# 0001. Generate Postgres SQL by editing the caller's query string

- Status: Accepted
- Date: 2026-11-03 (records decisions in place since the first releases in 2019)

## Context

QueryHelper has to paginate, filter and sort two kinds of queries the same way:

- ActiveRecord relations (`Resource.all`, scopes), and
- hand-written SQL strings with CTEs, joins, subqueries, `group by` and window functions. Pattern
  APIs rely on these for reporting endpoints that ActiveRecord can't express cleanly.

Both have to produce one response shape: rows plus a pagination block with the total count. The
count must come from the same query, not from a second `count(*)` round trip.

The host apps that use the gem run on Postgres.

## Decision

1. **Everything becomes a SQL string.** `QueryHelper#update` / `#query=` call `to_sql` on an
   ActiveRecord relation and remember its `base_class` as the model. From there, both paths go
   through the same code (`lib/query_helper.rb`).
2. **Parse just enough SQL to find insertion points, then insert text.** `SqlParser` "whites out"
   anything inside quotes or parentheses, so subqueries, CTE bodies, string literals and function
   arguments are ignored. It then finds the *last* top-level `select`, `from`, `where`, `qualify`,
   `group by`, `having`, `order by` and `limit` keywords with case-insensitive regexes.
   `SqlManipulator` inserts `where` / `having` / `qualify` conditions (with `and` when the clause
   already exists), replaces `order by` and `limit`, and adds extra select expressions. The gem
   doesn't use a full SQL parser or an AST.
3. **Column names come from the query itself.** `ColumnMap` builds the list of filterable and
   sortable aliases from explicit `custom_mappings`, then from `expr as alias` / `table.column` in
   the select list, then from the model's attributes (`table.column`). An expression that calls a
   known aggregate (`sum(`, `count(`, `max(`, `any_value(`…) is flagged as aggregate, so its
   filters go to `having` instead of `where`.
4. **Count with a window function.** When paginating, `SqlManipulator` adds
   `count(*) over () as _query_full_count` to the select list. With a `qualify` clause it wraps the
   query in a `qualified_results` CTE instead. It then appends `limit :limit offset :offset`. The
   total count is read from the first row and stripped from the results.
5. **Emit Postgres SQL.** Generated fragments use Postgres syntax and semantics: `ilike` and
   `::varchar` for search, `desc nulls last` for descending sorts, window-function counts.
   Supporting other databases is not a goal. The README says "It currently only supports
   Postgres."
6. **Test on in-memory SQLite.** `spec/spec_helper.rb` uses `sqlite3` with `:memory:` so the suite
   runs without a database server. Where the dialects differ, code branches on
   `ActiveRecord::Base.connection.adapter_name` (e.g. `SqlSort` drops `nulls last` on SQLite).
   Since 1.0.0, `sqlite3` is a development dependency only.

## Consequences

- Raw SQL and ActiveRecord queries get the same filtering, sorting and pagination, and the page
  and total count come back in one query.
- The SQL handling is heuristic. It assumes the outermost statement's clauses are the last
  top-level keywords. Edge cases go through the whited-out text and `custom_mappings`: unusual
  aliasing, keywords in identifiers, comments (stripped first), a `qualify` keyword. When
  auto-detection fails, the documented fix is a `custom_mappings` entry.
- Window-function counting runs the full query without `limit` inside the database. That is cheap
  enough for the intended endpoints, but it scales with the unpaginated result size.
- MySQL and other adapters are unsupported. The SQLite specs prove the clause manipulation and
  validation work, not Postgres-only behavior: `ilike` search and `nulls last` are not exercised
  by the suite. Changes to search or sort SQL need a manual check against Postgres in a host app.
- Changing the parsing approach (e.g. adopting a real SQL parser) or adding another dialect is a
  new ADR that supersedes this one.
