require "active_record"

require "query_helper/version"
require "query_helper/filter"
require "query_helper/column_map"
require "query_helper/associations"
require "query_helper/query_helper_concern"
require "query_helper/sql_parser"
require "query_helper/sql_manipulator"
require "query_helper/sql_filter"
require "query_helper/sql_sort"
require "query_helper/invalid_query_error"

class QueryHelper

  attr_accessor :model, :query, :bind_variables, :sql_filter, :sql_sort, :page, :per_page, :single_record, :associations, :as_json_options, :executed_query, :api_payload

  def initialize(
    model: nil, # the model to run the query against
    query: nil, # a sql string or an active record query
    bind_variables: {}, # a list of bind variables to be embedded into the query
    sql_filter: SqlFilter.new(), # a SqlFilter object
    sql_sort: SqlSort.new(), # a SqlSort object
    page: nil, # define the page you want returned
    per_page: nil, # define how many results you want per page
    single_record: false, # whether or not you expect the record to return a single result, if toggled, only the first result will be returned
    associations: nil, # a list of activerecord associations you'd like included in the payload
    as_json_options: nil, # a list of as_json options you'd like run before returning the payload
    custom_mappings: {}, # custom keyword => sql_expression mappings
    api_payload: false # Return the paginated payload or simply return the result array
  )
    @model = model
    @query = query
    @bind_variables = bind_variables
    @sql_filter = sql_filter
    @sql_sort = sql_sort
    @page = page.to_i if page
    @per_page = per_page.to_i if per_page
    @single_record = single_record
    @associations = associations
    @as_json_options = as_json_options
    @custom_mappings = custom_mappings
    @api_payload = api_payload

    if @page && @per_page
      # Determine limit and offset
      limit = @per_page
      offset = (@page - 1) * @per_page

      # Merge limit/offset variables into bind_variables
      @bind_variables.merge!({limit: limit, offset: offset})
    end
  end

  def update_query(query: nil, model:nil, bind_variables: {})
    @model = model if model
    @query = query if query
    @bind_variables.merge!(bind_variables)
  end

  def add_filter(operator_code:, criterion:, comparate:)
    @sql_filter.filter_values["comparate"] = { operator_code => criterion }
  end

  def execute_query
    # Correctly set the query and model based on query type
    determine_query_type()

    # Create column maps to be used by the filter and sort objects
    column_maps = create_column_maps()
    @sql_filter.column_maps = column_maps
    @sql_sort.column_maps = column_maps

    # create the filters from the column maps
    @sql_filter.create_filters()

    # merge the filter bind variables into the query bind variables
    @bind_variables.merge!(@sql_filter.bind_variables)

    # Execute Sql Query
    manipulator = SqlManipulator.new(
      sql: @query,
      where_clauses: @sql_filter.where_clauses,
      having_clauses:  @sql_filter.having_clauses,
      order_by_clauses: @sql_sort.parse_sort_string,
      include_limit_clause: @page && @per_page ? true : false
    )
    @executed_query = manipulator.build()
    @results = @model.find_by_sql([@executed_query, @bind_variables]) # Execute Sql Query
    @results = @results.first if @single_record # Return a single result if requested

    determine_count()
    load_associations()
    clean_results()
  end

  def results()
    execute_query()
    return paginated_results() if @api_payload
    return @results
  end



  private

    def paginated_results
      { pagination: pagination_results(),
        data: @results }
    end

    def determine_query_type
      # If a custom sql string is passed in, make sure a valid model is passed in as well
      if @query.class == String
        raise InvalidQueryError.new("a valid model must be included to run a custom SQL query") unless @model < ActiveRecord::Base
      # If an active record query is passed in, find the model and sql from the query
      elsif @query.class < ActiveRecord::Relation
        @model = @query.model
        @query = @query.to_sql
      else
        raise InvalidQueryError.new("unable to determine query type")
      end
    end

    def determine_count
      # Determine total result count (unpaginated)
      @count = @page && @per_page && @results.length > 0 ? @results.first["_query_full_count"] : @results.length
    end

    def load_associations
      @results = Associations.load_associations(
        payload: @results,
        associations: @associations,
        as_json_options: @as_json_options
      )
    end

    def clean_results
      @results.map!{ |r| r.except("_query_full_count") } if @page && @per_page
    end

    def pagination_results
      # Set pagination params if they aren't provided
      @per_page = @count unless @per_page
      @page = 1 unless @page

      total_pages = (@count/(@per_page.nonzero? || 1).to_f).ceil
      next_page = @page + 1 if @page.between?(1, total_pages - 1)
      previous_page = @page - 1 if @page.between?(2, total_pages)
      first_page = @page == 1
      last_page = @page == total_pages
      out_of_range = !@page.between?(1,total_pages)

      { count: @count,
        current_page: @page,
        next_page: next_page,
        previous_page: previous_page,
        total_pages: total_pages,
        per_page: @per_page,
        first_page: first_page,
        last_page: last_page,
        out_of_range: out_of_range }
    end

    def create_column_maps
      ColumnMap.create_column_mappings(
        query: @query,
        custom_mappings: @custom_mappings,
        model: @model
      )
    end

end
