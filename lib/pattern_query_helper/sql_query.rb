module PatternQueryHelper
  class SqlQuery

    attr_accessor :query_string, :query_params, :query_filter

    def initialize(
      model:, # the model to run the query against
      query:, # the custom sql to be executed
      query_params: {},
      column_mappings: nil, # A hash that translates aliases to sql expressions
      filters: nil,
      page: nil,
      per_page: nil
    )
      @model = model
      @query_params = query_params
      @page = page.to_i if page
      @per_page = per_page.to_i if per_page


      @column_maps = PatternQueryHelper::ColumnMap.create_from_hash(column_mappings)
      @query_filter = PatternQueryHelper::QueryFilter.new(filter_values: filters, column_maps: @column_maps)

      @query_string = PatternQueryHelper::QueryString.new(
        sql: query,
        where_filters: @query_filter.where_filter_strings,
        having_filters: @query_filter.having_filter_strings,
        sorts: [],
        page: @page,
        per_page: @per_page
      )

      @query_params.merge!(@query_filter.bind_variables)
    end

    def execute_query
      results = @model.find_by_sql([@query_string.build(), @query_params])
      byebug
      results.as_json
    end
  end
end
