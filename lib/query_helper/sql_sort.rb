require "query_helper/invalid_query_error"

class QueryHelper
  class SqlSort

    attr_accessor :column_maps

    def initialize(sort_string: "", column_maps: [])
      @sort_string = sort_string
      @column_maps = column_maps
    end

    def parse_sort_string
      sql_strings = []
      sorts = @sort_string.split(",")
      sorts.each_with_index do |sort, index|
        sort_alias = sort.split(":")[0]
        direction = sort.split(":")[1]
        modifier = sort.split(":")[2]

        begin
          sql_expression = @column_maps.find{ |m| m.alias_name == sort_alias }.sql_expression
        rescue NoMethodError => e
          raise InvalidQueryError.new("Sorting not allowed on column '#{sort_alias}'")
        end

        if direction == "desc"
          case ActiveRecord::Base.connection.adapter_name
          when "SQLite" # SQLite is used in the test suite
            direction = "desc"
          else
            direction = "desc nulls last"
          end
        else
          direction = "asc"
        end

        case modifier
        when "lowercase"
          sql_expression = "lower(#{sql_expression})"
        end

        sql_strings << "#{sql_expression} #{direction}"
      end

      return sql_strings
    end
  end
end
