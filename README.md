# QueryHelper
[![Gem Version](https://badge.fury.io/rb/query_helper.svg)](https://badge.fury.io/rb/query_helper)
[![CI](https://github.com/patterninc/query_helper/actions/workflows/ci.yml/badge.svg)](https://github.com/patterninc/query_helper/actions)

QueryHelper is a ruby gem used to paginate, sort, and filter your API calls in Ruby on Rails using URL params in your HTTP requests.  It currently only supports Postgres.  

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'query_helper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install query_helper

## Quick Use

### Step 1: Update Base Controller to use the QueryHelper Concern

```ruby
class ApplicationController < ActionController::API
  include QueryHelper::QueryHelperConcern
  before_action :create_query_helper
end
```

Adding this code creates a `QueryHelper` object preloaded with pagination, filtering, sorting, and association information included in the URL.  This object can be accessed by using the `@query_helper` instance variable from within your controllers.

### Step 2: Use QueryHelper to run active record and sql queries within your controller

#### Raw SQL Example

```ruby
class ResourceController < ApplicationController

  def index
    @query_helper.update(
      model: UserNotificationSetting,
      query: "select * from resources r where r.user_id = :user_id",
      bind_variables: { user_id: current_user().id }
    )

    render json: @query_helper.results()
  end

end
```

#### ActiveRecord Example

```ruby
class ResourceController < ApplicationController

  def index
    @query_helper.update(query: Resource.all)
    render json: @query_helper.results()
  end

end
```

*NOTE: Previous documentation stated you could simply run `@query_helper.query = Resource.all`.  While this method still works, it will evaluate the ActiveRecord query causing it to hit the database twice.  It is recommended that you always use the update method to avoid this inefficiency*

### Step 3: Paginate, Sort, Filter, and Include Associations using URL params

#### Pagination

`page=1`

`per_page=20`

`http://www.example.com/resources?page=1&per_page=25`

#### Sorting

`sort=column:direction`

Single Sort: `http://www.example.com/resources?sort=resource_name:desc`

Multiple Sorts: `http://www.example.com/resources?sort=resource_name:desc,resource_age:asc`

Lowercase Sort: `http://www.example.com/resources?sort=resource_name:desc:lowercase`

Custom Sort: `http://www.example.com/resources?custom_sort=resource_name:desc`
Example:
  Custom Sort is basically used for enum based column.
  ```
  class Customer < ApplicationRecord
    enum customer_type: {
      enum1: 0,
      enum2: 1,
      enum3: 3
    }
  end
  ```

  Usage at Controller

  ```
  class SomeController

    def index
      sort_column, sort_direction = params[:custom_sort]&.split(':')  

      column_sort_order = {
        column_name: sort_column,
        direction: sort_direction,
        sort_values: Customer.send(sort_column.pluralize).values
      }

      @query_helper.update(query: query, column_sort_order: column_sort_order)
    end
  end
  ```
#### Filtering

`filter[column][operator_code]=value`

Single Filter: `http://www.example.com/resources?filter[resource_age][gt]=50`

Multiple Filters: `http://www.example.com/resources?filter[resource_age][gt]=50&[resource_name][eql]=banana_resource`

Operator Code | SQL Operator
--- | ---
gte | >=
lte | <=
gt | >
lt | <
eql | =
noteql | !=
like | like
in | in
notin | not in
null | is null *or* is not null

Note: For the null operator code, toggle *is null* operator with true and *is not null* operator with false

#### Search

QueryHelper supports searching across multiple fields.  To implement pass an array of column aliases into the `search_fields` argument when creating or updating a `QueryHelper` object.

```ruby
@query_helper.update(search_fields: ["column1", "column2"])
render json: @query_helper.results()
```

You can then take advantage of the `search_for` url param to do text matching in any of the columns included

Request: `http://www.example.com/resources?search_for=foo`

Results: 
```json
[
  {
    "column1": "foobar",
    "column2": "bar"
  },
  {
    "column1": "bar",
    "column2": "barfoo"
  }
]
```

#### Associations

Include ActiveRecord associations in the payload.  The association must be defined in the model.

`include=association`

Single Association: `http://www.example.com/resources?include=child_resource`

Multiple Associations: `http://www.example.com/resources?include[]=child_resource&include[]=parent_resource`



## Payload Formats

The QueryHelper gem will return the following payload

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

## Using in Models or Services

If your complex queries are defined in a model or service, you can still use QueryHelper to automatically paginate, filter, and sort api calls that reference the given model/service.  

### Example

#### Model

```ruby
class MyModel < ApplicationRecord

  def complex_sql_function(query_helper=QueryHelper.new)
    query = "select * from resource"
    query_helper.update(
      model: Resource,
      query: query,
    )
  end
end
```

When calling this model from outside a controller, you will get the full result set without the api wrapping. (i.e. `MyModel.first.complex_sql_function` will return an array.

#### Controller

```ruby
class MyModelsController < ApplicationController

  def get_complex_query
    @object = MyModel.find(params[:id])
    response = @object.complex_sql_function(@query_helper)
    render json: response
  end
end
```

When you pass in the `@query_helper` object from the controller, QueryHelper will paginate, sort, and filter as expected.

## Advanced Options

### Associations

You can preload additional and include additional associations in your payload besides what's defined in the `include` url parameter.

```ruby
@query_helper.update(
  associations: ['association1']
)
```

### as_json options

You can pass in additional as_json options to be included in the payload.

```ruby
@query_helper.update(
  as_json_options: { methods: [:last_ran_at] }
)
```

### Preload

This is handy if you are loading other associations or methods with the as_json config and need to preload associations to avoid n+1 queries.

```ruby
@query_helper.update(
  preload: [:association1, :association2]
)
```
or
```ruby
@query_helper.update(
  preload: [association: [:child_association]]
)
```

### Custom Sort and Filter mappings

QueryHelper will automatically determine which sql aliases to run filtering and sorting on.  In cases where this doesn't work, you can provide your own custom mappings so QueryHelper knows how to correctly sort and filter.  One common example of this is when you run a `select * from resource1` but pass `resource2` in as the model.  

```ruby
@query_helper.update(
  custom_mappings: {
    "alias" => "complex_sql_function"
  }
)
```

To indicate that a custom mapping refers to an aggregate function use the following:

```ruby
@query_helper.update(
  custom_mappings: {
    "alias" => { sql_expression: "MAX(resouce.age)", aggregate: true }
  }
)
```

### Single Record Queries
If you only want to return a single result, but still want to be able to use some of the other functionality of QueryHelper, you can set `single_record` to true in the QueryHelper object.

```ruby
@query_helper.single_record = true
```
or
```ruby
@query_helper.update(
  single_record: true
)
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

Bug reports and pull requests are welcome on GitHub at https://github.com/patterninc/query_helper. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the QueryHelper project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/query_helper/blob/master/CODE_OF_CONDUCT.md).
