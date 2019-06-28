# QueryHelper
[![TravisCI](https://travis-ci.org/iserve-products/query_helper.svg?branch=master)](https://travis-ci.org/iserve-products/query_helper)
[![Gem Version](https://badge.fury.io/rb/query_helper.svg)](https://badge.fury.io/rb/query_helper)

Ruby Gem developed and used at Pattern to paginate, sort, filter, and include associations on sql and active record queries.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'query_helper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install query_helper

## Use

### SQL Queries

#### Initialize

To create a new sql query object run

```ruby
QueryHelper::Sql.new(
  model:,             # required
  query:,             # required
  query_params: ,     # optional
  column_mappings: ,  # optional
  filters: ,          # optional
  sorts: ,            # optional
  page: ,             # optional
  per_page: ,         # optional
  single_record: ,    # optional, default: false
  associations: ,     # optional
  as_json_options: ,  # optional
  run:                # optional, default: true
)
```

The following arguments are accepted when creating a new objects

<table>
<tr>
<th>Argument</th>
<th>Description</th>
<th>Example</th>
</tr>
<tr>
<td>model</td>
<td>the model to run the query against</td>
<td>
<pre lang="ruby">
Parent
</pre>
</td>
</tr>
<tr>
<td>query</td>
<td>the custom sql string to be executed</td>
<td>
<pre lang="ruby">
'select * from parents'
</pre>
</td>
</tr>
<tr>
<td>query_params</td>
<td>a hash of bind variables to be embedded into the sql query</td>
<td>
<pre lang="ruby">
{
  age: 20,
  name: 'John'
}
</pre>
</td>
</tr>
<tr>
<td>column_mappings</td>
<td>A hash that translates aliases to sql expressions</td>
<td>
<pre lang="ruby">
{
  "age" => "parents.age"
  "children_count" => {
    sql_expression: "count(children.id)",
    aggregate: true
  }
}
</pre>
</td>
</tr>
<tr>
<td>filters</td>
<td>a list of filters in the form of `{"comparate_alias"=>{"operator_code"=>"value"}}`</td>
<td>
<pre lang="ruby">
{
  "age" => { "lt" => 100 },
  "children_count" => { "gt" => 0 }
}
</pre>
</td>
</tr>
<tr>
<td>sorts</td>
<td>a comma separated string with a list of sort values</td>
<td>
<pre lang="ruby">
"age:desc,name:asc:lowercase"
</pre>
</td>
</tr>
<tr>
<td>page</td>
<td>the page you want returned</td>
<td>
<pre lang="ruby">
5
</pre>
</td>
</tr>
<tr>
<td>per_page</td>
<td>the number of results per page</td>
<td>
<pre lang="ruby">
20
</pre>
</td>
</tr>
<tr>
<td>single_record</td>
<td>whether or not you expect the record to return a single result, if toggled, only the first result will be returned</td>
<td>
<pre lang="ruby">
false
</pre>
</td>
</tr>
<tr>
<td>associations</td>
<td>a list of activerecord associations you'd like included in the payload </td>
<td>
<pre lang="ruby">

</pre>
</td>
</tr>
<tr>
<td>as_json_options</td>
<td>a list of as_json options you'd like run before returning the payload</td>
<td>
<pre lang="ruby">

</pre>
</td>
</tr>
<tr>
<td>run</td>
<td>whether or not you'd like to run the query on initilization</td>
<td>
<pre lang="ruby">
false
</pre>
</td>
</tr>
</table>

### Active Record Queries

To run an active record query execute
```ruby
QueryHelper.run_active_record_query(active_record_call, query_helpers, valid_columns, single_record)
```
active_record_call: Valid active record syntax (i.e. ```Object.where(state: 'Active')```)
query_helpers: See docs below
valid_columns: Default is [].  Pass in an array of columns you want to allow sorting and filtering on.
single_record: Default is false.  Pass in true to format payload as a single object instead of a list of objects


model: A valid ActiveRecord model
query: A string containing your custom SQL query
query_params: a symbolized hash of binds to be included in your SQL query
query_helpers: See docs below
valid_columns: Default is [].  Pass in an array of columns you want to allow sorting and filtering on.
single_record: Default is false.  Pass in true to format payload as a single object instead of a list of objects

## Query Helpers
query_helpers is a symbolized hash passed in with information about pagination, associations, filtering and sorting.

### Pagination
There are two pagination keys you can pass in as part of the query_helpers objects

```ruby
{
  page: 1,
  per_page: 20
}
```

If at least one of these keys is present, paginated results will be returned.

### Sorting
Sorting is controlled by the `sort` key in the query_helpers object

```ruby
{
    sort: "column_name:sort_direction"
}
```
Sort direction can be either asc or desc.  If you wish to lowercase string before sorting include the following:
```ruby
{
    sort: "name:desc:lowercase"
}
```

### Filtering
Filtering is controlled by the `filter` object in the query_helpers hash

```ruby
{
  filter: {
    "column_1" => {
      "gte" => 20,
      "lt" => 40
    },
    "column_2" => {
      "eql" => "my_string"
    },
    "column_3" => {
      "like" => "my_string%"
    },
    "column_4" => {
      "in" => "item1,item2,item3"
    }
}
```

The following operator codes are valid

```
“gte”: >=
“lte”: <=
“gt”: >
“lt”: <
“eql”: =
“noteql”: !=
"like": like
“in”: in
“notin” not in
“null”: “is null” or “is not null” (pass in true or false as the value)
```

### Associations

To include associated objects in the payload, pass in the following as part of the query_helpers hash:

```ruby
{
  include: ['associated_object_1', 'associated_object_2']
}
```

### Example

The following is an example of a query_helpers object that can be passed into the sql and active record methods

```ruby
query_helpers = {
  page: 1,
  per_page: 20,
  sort: "name:desc"
  include: ["child"]
  filter: {
    "id" => {
      "gte" => 20,
      "lt" => 40
    }
}
```

## Payload Formats

The QueryHelper gem will return results in one of three formats

### Paginated List Payload
```json
{
  "pagination": {
    "count": 18,
    "current_page": 1,
    "next_page": 2,
    "previous_page": null,
    "total_pages": 6,
    "per_page": 3,
    "first_page": true,
    "last_page": false,
    "out_of_range": false
  },
  "data": [
    {
      "id": 1,
      "attribute_1": "string_attribute",
      "attribute_2": 12345,
      "attribute_3": 0.3423212
    },
    {
      "id": 2,
      "attribute_1": "string_attribute",
      "attribute_2": 12345,
      "attribute_3": 0.3423212
    },
    {
      "id": 3,
      "attribute_1": "string_attribute",
      "attribute_2": 12345,
      "attribute_3": 0.3423212
    },
  ]
}
```

### List Payload
```json
{
  "data": [
    {
      "id": 1,
      "attribute_1": "string_attribute",
      "attribute_2": 12345,
      "attribute_3": 0.3423212
    },
    {
      "id": 2,
      "attribute_1": "string_attribute",
      "attribute_2": 12345,
      "attribute_3": 0.3423212
    },
    {
      "id": 3,
      "attribute_1": "string_attribute",
      "attribute_2": 12345,
      "attribute_3": 0.3423212
    },
  ]
}
```

### Single Record Payload
```json
{
  "data": {
    "id": 1,
    "attribute_1": "string_attribute",
    "attribute_2": 12345,
    "attribute_3": 0.3423212
  }
}
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/query_helper. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the QueryHelper project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/query_helper/blob/master/CODE_OF_CONDUCT.md).
