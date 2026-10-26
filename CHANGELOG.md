# Changelog

## 0.5.0

### Security
- Fixed SQL injection through `column_sort_order`, which `QueryHelperConcern` passes from request params. `column_name` must now be a known column, `direction` must be `asc` or `desc`, and `sort_values` are quoted as SQL literals.
- Model attributes matching `filter_attributes` (Rails `config.filter_parameters`) can no longer be filtered, sorted or searched on unless the query selects them or they are custom mapped. This stops blind extraction of secrets through `filter[...][like]`.
- Added an optional `query_helper_allowed_includes` controller hook to restrict the `include` param.
- `per_page` is capped at `QueryHelper.max_per_page` (default 1000).

### Upgrade notes
These now raise `QueryHelper::InvalidQueryError` (make sure you rescue it and return a 400):
- `page` below 1 or a negative `per_page`
- filter criteria that are hashes, arrays for operators other than `in`/`notin`, or filter values that are not `operator => criterion` pairs
- invalid `column_sort_order` columns, directions or values
- includes that are not in `query_helper_allowed_includes`, when it is defined

`column_sort_order` values are now quoted, so string values compare as strings (`'1'` instead of `1`). Postgres and SQLite coerce these for integer columns.

If you relied on filtering or sorting by a column that matches your `filter_parameters`, select it in your query or add it to `custom_mappings`.

`per_page` above 1000 is now clamped. Set `QueryHelper.max_per_page` or pass `max_per_page:` to change it.

`sqlite3` is no longer a runtime dependency. Add it to your own Gemfile if you use it.
