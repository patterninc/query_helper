require "query_helper/invalid_query_error"

class QueryHelper
  class SqlFilter

    attr_accessor :filter_values, :column_maps, :options

    def initialize(filter_values: [], column_maps: [], options: {})
      @column_maps = column_maps
      @filter_values = filter_values
      @options = options
    end

    def create_filters
      @filters = []

      @filter_values.each do |comparate_alias, criteria|
        # Find the sql mapping if it exists
        map = @column_maps.find { |m| m.alias_name == comparate_alias }
        raise InvalidQueryError.new("cannot filter by #{comparate_alias}") unless map

        # create the filter
        @filters << QueryHelper::Filter.new(
          operator_code: criteria.keys.first,
          criterion: criteria.values.first,
          comparate: map.sql_expression,
          aggregate: map.aggregate,
          qualify_clause: aggregated_attribute?(comparate: map.sql_expression)
        )
      end
    end

    def aggregated_attribute?(comparate:)
      @options['qualify_clause'] && comparate.starts_with?('pct_')
    end

    def qualify_clauses
      # @options.select{ |f| f.qualify_clause == true }.map(&:sql_string)
      @filters.select{ |f| aggregated_attribute?(comparate: f.comparate) }.map(&:sql_string)
    end

    def where_clauses
      @filters.select{ |f| f.aggregate == false && !f.qualify_clause }.map(&:sql_string)
    end

    def having_clauses
      @filters.select{ |f| f.aggregate == true }.map(&:sql_string)
    end

    def bind_variables
      Hash[@filters.collect { |f| [f.bind_variable, f.criterion] }]
    end
  end
end
