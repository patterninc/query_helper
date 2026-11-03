# 0002. Security model for URL-param filtering, sorting and includes

- Status: Accepted
- Date: 2026-11-03 (records the model shipped in 1.0.0, 2026-10-27)

## Context

`QueryHelperConcern` passes request params straight into SQL generation:

- `filter[...]` arrives as an unpermitted hash (`params[:filter].to_unsafe_h`),
- `sort`, `sort_tiebreak` and `column_sort_order` choose `order by` expressions,
- `include` chooses associations to load and serialize,
- `page` / `per_page` and `search_for` shape the query.

Before 1.0.0:

- `column_sort_order` values were concatenated into a `CASE` expression, which allowed SQL injection.
- Any association could be included, and every column of it was serialized, including password
  hashes and tokens.
- Any model attribute could be filtered with `like`, so a secret could be extracted one character
  at a time.
- `per_page` had no cap.
- Malformed params (arrays, hashes) raised arbitrary Ruby errors.

## Decision

These rules are enforced in the library, so that host apps are safe by default:

1. **Values are always bind variables.** Each `Filter` gets its own randomly named bind variable,
   and the criterion is passed through `sanitize_sql_array` / `find_by_sql`. `search_for`,
   `limit` and `offset` are bound the same way. A criterion must be a scalar, or an array of
   scalars for `in` / `notin`. Range operators (`gt`, `gte`, `lt`, `lte`) also need something
   that parses as a time, date or number.
2. **Identifiers only come from the column map.** A filter or sort alias must match a `ColumnMap`
   entry (custom mapping, select alias or model attribute). The SQL that gets emitted is the
   mapped expression, never the param. `column_sort_order[:column_name]` resolves the same way.
   Its `direction` must be `asc` or `desc`, and its `sort_values` are quoted with
   `connection.quote`.
3. **Operators come from a fixed list** (`gte lte gt lt eql noteql like in notin null`). Anything
   else is rejected.
4. **Sensitive attributes are hidden by default.** Model attributes that match the model's
   `filter_attributes` (Rails `config.filter_parameters`) can't be filtered, sorted or searched,
   unless the query selects them explicitly or a custom mapping names them. Included records have
   those attributes stripped too, unless the caller supplies its own `as_json` `include`.
5. **Includes are deny-by-default.** The `include` param only works when the controller defines
   `query_helper_allowed_includes`, and every requested path, nested ones included, must be in it.
   `QueryHelper.allow_unlisted_includes = true` restores the old behavior as an explicit,
   global, not-recommended opt-out.
6. **Pagination is bounded.** `page` must be an integer of at least 1 and `per_page` a
   non-negative integer. `per_page` is clamped to `QueryHelper.max_per_page` (default 1000),
   which can be changed globally or per query (`nil` disables it).
7. **One error type.** Every invalid input raises `QueryHelper::InvalidQueryError`. Host apps are
   told to `rescue_from` it and return a 400.

What remains the caller's job (documented in the README "Security" section):

- Never interpolate params into `query`, `custom_mappings` or `column_sort_order[:column_name]`.
- Keep `filter_parameters` complete.
- Rescue `InvalidQueryError`.

## Consequences

- A hostile URL can only pick from expressions the developer already wrote or exposed, and it can
  only supply values as bind variables or quoted literals.
- 1.0.0 is a breaking release. Controllers that use `include` need an allowlist, malformed params
  now return errors instead of being ignored, and very large `per_page` values are clamped. The
  CHANGELOG carries the upgrade notes.
- Every model attribute that isn't sensitive is still filterable and sortable, even if the query
  doesn't select it. This is convenient, but the protection only works as well as the app's
  `filter_parameters`.
- New features that accept URL input must follow the same rules: map identifiers, bind values,
  raise `InvalidQueryError`, and add a hostile-input spec. Any new exposure must be opt-in.
  Loosening any rule above needs a superseding ADR.
