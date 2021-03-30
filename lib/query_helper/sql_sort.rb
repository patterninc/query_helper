require "query_helper/invalid_query_error"

class QueryHelper
  class SqlSort

    attr_accessor :column_maps, :select_strings, :sort_tiebreak

    def initialize(sort_string: "", sort_tiebreak: "", column_maps: [])
      @sort_string = sort_string
      @column_maps = column_maps
      @sort_tiebreak = sort_tiebreak
      @select_strings = []
    end

    def parse_sort_string
      return [] if @sort_string.blank? && @sort_tiebreak.blank?

      return attributes_sql_expression(@sort_tiebreak) if @sort_string.blank?

      sql_strings = attributes_sql_expression(@sort_string)
      return sql_strings if @sort_tiebreak.blank?

      sql_strings + attributes_sql_expression(@sort_tiebreak)
    end

    def attributes_sql_expression(sort_attribute)
      sql_strings = []
      sorts = sort_attribute.split(",")
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
          # When select distincts are used, the order by clause must be included in the select clause
          @select_strings << sql_expression
        end

        sql_strings << "#{sql_expression} #{direction}"
      end
      sql_strings
    end
  end
end
