module PatternQueryHelper
  class SqlQuery

    attr_accessor :model, :query_string, :query_params, :query_filter, :results

    def initialize(
      model:, # the model to run the query against
      query:, # the custom sql to be executed
      query_params: {},
      column_mappings: {}, # A hash that translates aliases to sql expressions
      filters: {},
      sorts: "",
      page: nil,
      per_page: nil,
      single_record: false,
      associations: [],
      as_json_options: {}
    )
      @model = model
      @query_params = query_params
      @page = page.to_i if page
      @per_page = per_page.to_i if per_page
      @single_record = single_record
      @as_json_options = as_json_options
      @column_maps = PatternQueryHelper::ColumnMap.create_from_hash(column_mappings)
      @query_filter = PatternQueryHelper::QueryFilter.new(filter_values: filters, column_maps: @column_maps)
      @sorts = PatternQueryHelper::Sort.new(sort_string: sorts, column_maps: @column_maps)
      @associations = PatternQueryHelper::Associations.process_association_params(associations)
      @query_string = PatternQueryHelper::QueryString.new(
        sql: query,
        where_filters: @query_filter.where_filter_strings,
        having_filters: @query_filter.having_filter_strings,
        sorts: @sorts.sort_strings,
        page: @page,
        per_page: @per_page
      )
      @query_params.merge!(@query_filter.bind_variables)
      execute_query()
    end

    def execute_query
      # Execute Sql Query
      @results = @model.find_by_sql([@query_string.build(), @query_params])

      # Determine total result count
      @count = @page && @per_page && results.length > 0? results.first["_query_full_count"] : results.length

      # Return a single result if requested
      @results = @results.first if @single_record

      load_associations()
      clean_results()
    end

    def load_associations
      @results = PatternQueryHelper::Associations.load_associations(
        payload: @results,
        associations: @associations,
        as_json_options: @as_json_options
      )
    end

    def clean_results
      @results.map!{ |r| r.except("_query_full_count") } if @page && @per_page
    end

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
  end
end
