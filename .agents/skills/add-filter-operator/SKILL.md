---
name: add-filter-operator
description: Adds or changes a filter operator code (the `filter[column][operator]=value` URL param) in query_helper safely, with validation, bind variables, specs and docs. Use when asked to support a new filter operator (e.g. ilike, between, notnull) or change how an existing one builds SQL. Do not use for sorting, search or include changes, or for changes to column mapping.
---

# Add or change a filter operator

## Inputs

- The operator code as it will appear in the URL (lowercase letters only, e.g. `ilike`).
- The SQL it should produce, and which criterion types are valid (scalar, list, boolean, range).

## Where it lives

- `lib/query_helper/filter.rb`:
  - `translate_operator_code` maps the code to the SQL operator. Unknown codes raise.
  - `validate_criterion_type` checks the criterion is a scalar, or an array of scalars for
    list operators. It runs before any mutation.
  - `mofify_criterion` lowercases, splits `in` lists, adds `like` wildcards (the method name's
    spelling is the existing one; keep it).
  - `modify_comparate` wraps the column in `lower(...)` for text comparisons.
  - `validate_criterion` does per-operator checks (range operators need a time, date or number).
  - `sql_string` builds the final fragment with `:#{bind_variable}`.
- `lib/query_helper/sql_filter.rb` decides whether the fragment goes to `where`, `having` or
  `qualify`. You usually don't need to touch it.

## Steps

1. Add the code to `translate_operator_code`.
2. If the operator takes a list, add it next to `in` / `notin` in `validate_criterion_type`,
   `mofify_criterion` and `sql_string`.
3. Add any per-operator validation to `validate_criterion`. Invalid input must call
   `invalid_criterion_error` (`QueryHelper::InvalidQueryError`).
4. Keep the criterion a bind variable. Never interpolate it into `sql_string`.
5. Add specs to `spec/query_helper/filter_spec.rb`:
   - the generated SQL, matched with a regex such as `/\Aparents.age op :[a-z]+\z/`, because bind
     names are random,
   - rejection of a hash criterion, of an array criterion for scalar operators, and of an
     invalid value.
6. If the operator is Postgres-only (e.g. `ilike`), note that in the spec. The suite runs on SQLite
   (see `docs/adr/0001-postgres-first-sql-generation.md`), so assert on the SQL string rather than
   running it.
7. Add a row to the operator table in `README.md` ("Filtering") and an entry to `CHANGELOG.md`.
8. Run `bundle exec rspec spec`.

## Guardrails

- Follow `docs/adr/0002-url-param-security-model.md`: values bound, operators from a fixed list,
  any bad input raises `InvalidQueryError`.
- Don't relax `validate_criterion_type` for existing operators to fit a new one.
- Changing what an existing operator generates is a breaking change. Call it out in the CHANGELOG.
