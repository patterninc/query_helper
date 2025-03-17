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

  attr_accessor :model, :bind_variables, :sql_filter, :sql_sort, :page, :per_page, :single_record, :associations, :as_json_options, :executed_query, :api_payload, :preload, :search_field, :search_string, :metadata
  attr_reader :query

  def initialize(
    model: nil, # the model to run the query against
    query: nil, # a sql string or an active record query
    bind_variables: {}, # a list of bind variables to be embedded into the query
    sql_filter: SqlFilter.new(), # a SqlFilter object
    sql_sort: SqlSort.new(), # a SqlSort object
    page: nil, # define the page you want returned
    per_page: nil, # define how many results you want per page
    single_record: false, # whether or not you expect the record to return a single result, if toggled, only the first result will be returned
    associations: [], # a list of activerecord associations you'd like included in the payload
    as_json_options: nil, # a list of as_json options you'd like run before returning the payload
    custom_mappings: {}, # custom keyword => sql_expression mappings
    api_payload: false, # Return the paginated payload or simply return the result array
    preload: [], # preload activerecord associations - used instead of `associations` when you don't want them included in the payload
    search_fields: [],
    search_string: nil,
    metadata: {}
  )
    @query = query.class < ActiveRecord::Relation ? query.to_sql : query
    @model = query.class < ActiveRecord::Relation ? query.base_class : model
    @bind_variables = bind_variables
    @sql_filter = sql_filter
    @sql_sort = sql_sort
    @page = determine_page(page: page, per_page: per_page)
    @per_page = determine_per_page(page: page, per_page: per_page)
    set_limit_and_offset()
    @single_record = single_record
    @associations = associations
    @as_json_options = as_json_options
    @custom_mappings = custom_mappings
    @api_payload = api_payload
    @preload = preload
    @search_fields = search_fields
    @search_string = search_string
    @metadata = metadata
  end

  def update(
    query: nil,
    model: nil,
    bind_variables: {},
    filters: [],
    associations: [],
    as_json_options: nil,
    single_record: nil,
    custom_mappings: nil,
    preload: [],
    search_fields: nil,
    sql_filter: nil,
    sql_sort: nil,
    sort_tiebreak: nil,
    column_sort_order: nil,
    page: nil,
    per_page: nil,
    search_string: nil,
    metadata: nil
  )
    @query = query.class < ActiveRecord::Relation ? query.to_sql : query if query
    @model = query.class < ActiveRecord::Relation ? query.base_class : model if model || query
    @bind_variables.merge!(bind_variables)
    filters.each{ |f| add_filter(**f) }
    @associations = @associations | associations
    @single_record = single_record if single_record
    @as_json_options = as_json_options if as_json_options
    @custom_mappings = custom_mappings if custom_mappings
    @preload = preload if preload
    @search_fields = search_fields if search_fields
    @sql_filter = sql_filter if sql_filter
    @sql_sort = sql_sort if sql_sort
    @sql_sort.sort_tiebreak = sort_tiebreak if sort_tiebreak
    @sql_sort.column_sort_order = column_sort_order if column_sort_order
    @search_string = search_string if search_string
    @page = determine_page(page: page, per_page: per_page) if page
    @per_page = determine_per_page(page: page, per_page: per_page) if per_page
    @metadata = metadata if metadata
    set_limit_and_offset()
    return self
  end

  def add_filter(operator_code:, criterion:, comparate:)
    @sql_filter.filter_values["comparate"] = { operator_code => criterion }
  end

  def query=(value)
    if value.class < ActiveRecord::Relation
      @query = value.to_sql
      @model = value.base_class
    else
      @query = value
    end
    return ""
  end

  def build_query
    # Create column maps to be used by the filter and sort objects
    column_maps = create_column_maps()

    @sql_filter.column_maps = column_maps
    @sql_sort.column_maps = column_maps

    # create the filters from the column maps
    @sql_filter.create_filters()

    having_clauses = @sql_filter.having_clauses
    where_clauses = @sql_filter.where_clauses
    qualify_clauses = @sql_filter.qualify_clauses

    if @search_string
      search_filter = search_filter(column_maps)
      if search_filter[:placement] == :where
        where_clauses << search_filter[:filter]
      else
        having_clauses << search_filter[:filter]
      end
    end


    # merge the filter bind variables into the query bind variables
    @bind_variables.merge!(@sql_filter.bind_variables)

    # Execute Sql Query
    manipulator = SqlManipulator.new(
      sql: @query,
      where_clauses: where_clauses,
      having_clauses: having_clauses,
      qualify_clauses: qualify_clauses,
      order_by_clauses: @sql_sort.parse_sort_string,
      include_limit_clause: @page && @per_page ? true : false,
      additional_select_clauses:  @sql_sort.select_strings
    )
    manipulator.build()
  end

  def to_json(args)
    results.to_json
  end

  def to_sql
    query = build_query()
    return query if @bind_variables.length == 0
    begin
      return @model.sanitize_sql_array([query, @bind_variables])
    rescue NoMethodError
      # sanitize_sql_array is a protected method before Rails v5.2.3
      return @model.send(:sanitize_sql_array, [query, @bind_variables])
    end
  end

  def view_query
    to_sql
  end

  def execute_query
    query = build_query()
    @results = @model.find_by_sql([query, @bind_variables]) # Execute Sql Query
    @results = @single_record ? @results.first : @results

    determine_count()
    preload_associations()
    load_associations()
    clean_results()
  end

  def results
    execute_query()
    return paginated_results() if @api_payload
    return @results
  end

  def pagination_results(count=@count)
    # Set pagination params if they aren't provided
    results_per_page = @per_page || count
    results_page = @page || 1

    total_pages = (count.to_i/(results_per_page.nonzero? || 1).to_f).ceil
    next_page = results_page + 1 if results_page.between?(1, total_pages - 1)
    previous_page = results_page - 1 if results_page.between?(2, total_pages)
    first_page = results_page == 1
    last_page = results_page >= total_pages
    out_of_range = !results_page.between?(1,total_pages)

    { count: count,
      current_page: results_page,
      next_page: next_page,
      previous_page: previous_page,
      total_pages: total_pages,
      per_page: results_per_page,
      first_page: first_page,
      last_page: last_page,
      out_of_range: out_of_range }
  end

  private

    def determine_page(page:, per_page:)
      return page.to_i if page
      return 1 if !page && per_page
      return nil
    end

    def determine_per_page(page:, per_page:)
      return per_page.to_i if per_page
      return 100 if !per_page && page
      return nil
    end

    def set_limit_and_offset
      if @page && @per_page
        # Determine limit and offset
        limit = @per_page
        offset = (@page - 1) * @per_page

        # Merge limit/offset variables into bind_variables
        @bind_variables[:limit] = limit
        @bind_variables[:offset] = offset
      end
    end

    def paginated_results
      { pagination: pagination_results(),
        data: @results,
        metadata: @metadata }
    end

    def determine_count
      # Determine total result count (unpaginated)
      if @single_record
        @count = 1
      else
        @count = @page && @per_page && @results.length > 0 ? @results.first["_query_full_count"] : @results.length
      end
    end

    def load_associations
      result = Associations.load_associations(
        payload: Array(@results),
        associations: @associations,
        as_json_options: @as_json_options
      )

      @results = @single_record ? result.first : result
    end

    def preload_associations
      Associations.preload_associations(
        payload: Array(@results),
        preload: @preload
      )
    end

    def clean_results
      @results.map!{ |r| r.except("_query_full_count") } if @page && @per_page && !@single_record
    end

    def create_column_maps
      ColumnMap.create_column_mappings(
        query: @query,
        custom_mappings: @custom_mappings,
        model: @model
      )
    end

    def search_filter(column_maps)
      raise ArgumentError.new("search_fields not defined") unless @search_fields.length > 0
      placement = :where
      maps = column_maps.select do |cm|
        if @search_fields.include? cm.alias_name
          placement = :having if cm.aggregate
          true
        else
          false
        end
      end
      bind_variable = ('a'..'z').to_a.shuffle[0,20].join.to_sym
      @bind_variables[bind_variable] = "%#{@search_string}%"
      filter = "#{maps.map{|m| "coalesce(#{m.sql_expression}::varchar, '')"}.join(" || ")} ilike :#{bind_variable}"
      return {
        filter: filter,
        placement: placement
      }
    end
end
