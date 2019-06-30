require "query_helper/sql_manipulator"
require "query_helper/associations"

module QueryHelper
  class SqlRunner

    attr_accessor :results

    def initialize(**sql_params)
      update(**sql_params)
    end

    def update(
      model:, # the model to run the query against
      sql:, # a sql string
      bind_variables: {}, # a list of bind variables to be embedded into the query
      sql_filter: nil, # a SqlFilter object
      sql_sort: nil, # a SqlSort object
      page: nil, # define the page you want returned
      per_page: nil, # define how many results you want per page
      single_record: nil, # whether or not you expect the record to return a single result, if toggled, only the first result will be returned
      associations: nil, # a list of activerecord associations you'd like included in the payload
      as_json_options: nil, # a list of as_json options you'd like run before returning the payload
      run: nil # whether or not you'd like to run the query on initilization or update
    )
      @model = model if model
      @sql = sql if sql
      @bind_variables = bind_variables if bind_variables
      @sql_filter = sql_filter if sql_filter
      @sql_sort = sql_sort if sql_sort
      @page = page.to_i if page
      @per_page = per_page.to_i if per_page
      @single_record = single_record if single_record
      @associations = associations if associations
      @as_json_options = as_json_options if as_json_options

      # Determine limit and offset
      limit = @per_page
      offset = (@page - 1) * @per_page

      # Merge the filter variables and limit/offset variables into bind_variables
      @bind_variables.merge!(@sql_filter.bind_variables).merge!{limit: limit, offset: offset}

      execute_query() if run
    end

    def execute_query
      # Execute Sql Query
      manipulator = SqlManipulator.new(
        sql: @sql,
        where_clauses: @sql_filter.where_filter_strings,
        having_clauses:  @sql_filter.having_filter_strings,
        order_by_clauses: @sql_sort.sort_strings,
        include_limit_clause: @page && @per_page ? true : false
      )

      @results = @model.find_by_sql([manipulator.build(), @bind_variables]) # Execute Sql Query
      @results = @results.first if @single_record # Return a single result if requested

      determine_count()
      load_associations()
      clean_results()
    end

    def payload
      if @page && @per_page
        {
          pagination: pagination_results(),
          data: @results
        }
      else
        { data: @results }
      end
    end

    private

    def pagination_results
      total_pages = (@count/(@per_page.nonzero? || 1).to_f).ceil
      next_page = @page + 1 if @page.between?(1, total_pages - 1)
      previous_page = @page - 1 if @page.between?(2, total_pages)
      first_page = @page == 1
      last_page = @page == total_pages
      out_of_range = !@page.between?(1,total_pages)

      {
        count: @count,
        current_page: @page,
        next_page: next_page,
        previous_page: previous_page,
        total_pages: total_pages,
        per_page: @per_page,
        first_page: first_page,
        last_page: last_page,
        out_of_range: out_of_range
      }
    end

    def clean_results
      @results.map!{ |r| r.except("_query_full_count") } if @page && @per_page
    end

    def load_associations
      @results = Associations.load_associations(
        payload: @results,
        associations: @associations,
        as_json_options: @as_json_options
      )
    end

    def determine_count
      # Determine total result count (unpaginated)
      @count = @page && @per_page && results.length > 0 ? results.first["_query_full_count"] : results.length
    end
  end
end
