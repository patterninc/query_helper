module QueryHelper
  class QueryFilter

    attr_accessor :filters, :where_filter_strings, :having_filter_strings, :bind_variables

    def initialize(filter_values:, column_maps:)
      @column_maps = column_maps
      @filter_values = filter_values
      @filters = create_filters()
      @where_filter_strings = filters.select{ |f| f.aggregate == false }.map(&:sql_string)
      @having_filter_strings = filters.select{ |f| f.aggregate == true }.map(&:sql_string)
      @bind_variables = Hash[filters.collect { |f| [f.bind_variable, f.criterion] }]
    end

    def create_filters
      filters = []
      @filter_values.each do |comparate, criteria|
        # Default values
        aggregate = false

        # Find the sql mapping if it exists
        map = @column_maps.find{ |m| m.alias_name == comparate } # Find the sql mapping if it exists
        if map
          comparate = map.sql_expression
          aggregate = map.aggregate
        end

        # Set the criteria
        operator_code = criteria.keys.first
        criterion = criteria.values.first

        # create the filter
        filters << QueryHelper::Filter.new(
          operator_code: operator_code,
          criterion: criterion,
          comparate: comparate,
          aggregate: aggregate,
        )
      end
      filters
    end
  end
end
