module PatternQueryHelper
  class QueryFilter

    attr_accessor :column_maps, :filter_values, :filters, :sql_string, :cte_filter, :embedded_having_strings, :embedded_where_strings, :bind_variables

    def initialize(
      filter_values:,
      column_maps:
    )
      @column_maps = column_maps
      @filter_values = filter_values
      @filters = create_filters()
      @cte_strings = filters.select{ |f| f.cte_filter == true }.map(&:sql_string)
      @embedded_having_strings = filters.select{ |f| f.cte_filter == false && aggregate == true }.map(&:sql_string)
      @embedded_where_strings = filters.select{ |f| f.cte_filter == false && aggregate == false }.map(&:sql_string)
      @bind_variables = Hash[filters.collect { |f| [f.bind_variable, f.criterion] }]
    end

    def create_filters
      filters = []
      filter_values.each do |comparate, criteria|
        # Default values
        aggregate = false
        cte_filter = true

        # Find the sql mapping if it exists
        map = column_maps.find{ |m| m.alias_name == comparate } # Find the sql mapping if it exists
        if map
          comparate = map.sql_expression
          aggregate = map.aggregate
          cte_filter = false
        end

        # Set the criteria
        operator_code = criteria.keys.first
        criterion = criteria.values.first

        # create the filter
        filters << PatternQueryHelper::Filter.new(
          operator_code: operator_code,
          criterion: criterion,
          comparate: comparate,
          aggregate: aggregate,
          cte_filter: cte_filter
        )
      end
      filters
    end
  end
end
