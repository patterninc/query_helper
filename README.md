# QueryHelper
[![TravisCI](https://travis-ci.org/iserve-products/query_helper.svg?branch=master)](https://travis-ci.org/iserve-products/query_helper)
[![Gem Version](https://badge.fury.io/rb/query_helper.svg)](https://badge.fury.io/rb/query_helper)

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

#### Active Record Example

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

#### Raw SQL Example

```ruby
class ResourceController < ApplicationController

  def index
    @query_helper.query = Resource.all
    render json: @query_helper.results()
  end

end
```

You can also use the `@query_helper.update()` method to update the QueryHelper with an ActiveRecord object

```ruby
@query_helper.update(
  query: Resource.all
)
```

### Step 3: Paginate, Sort, Filter, and Include Associations using URL params

#### Pagination

`http://www.example.com/resources?page=1&per_page=25`

#### Sorting

`http://www.example.com/resources?sort=resource_name:desc`

You can also sort my multiple columns by separating them with commas

`sort=resource_name:desc,resource_age:asc`

Additionally, for text columns you can force a lowercase sort by adding an extra modifier.  

`sort=resource_name:desc:lowercase,resource_age:asc`

#### Filtering

`http://www.example.com/resources?filter[resource_age][gt]=50`

You can add multiple filters to the url params.  Just make sure it follows the form of `filter[column][operator_code]=value`

`http://www.example.com/resources?filter[resource_age][gt]=50&[resource_name][eql]=banana_resource`

##### Valid Operator Codes

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

#### Associations

You can ask to include active_record associations in the payload.  The association must be defined in the model.

`http://www.example.com/resources?include=child_resource`

You can also include multiple associations

`http://www.example.com/resources?include[]=child_resource&include[]=parent_resource`



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
