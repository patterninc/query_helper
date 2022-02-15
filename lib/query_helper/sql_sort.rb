require "query_helper/invalid_query_error"

class QueryHelper
  class SqlSort

    attr_accessor :column_maps, :select_strings, :sort_tiebreak, :column_sort_order

    def initialize(sort_string: "", sort_tiebreak: "", column_maps: [], column_sort_order: {})
      @sort_string = sort_string
      @column_maps = column_maps
      @sort_tiebreak = sort_tiebreak
      @column_sort_order = column_sort_order
      @select_strings = []
    end

    def parse_sort_string
      return [] if @sort_string.blank? && @sort_tiebreak.blank? && @column_sort_order.blank?

      return attributes_sql_expression(@sort_tiebreak) if @sort_string.blank?

      sql_strings = attributes_sql_expression(@sort_string)
      return sql_strings if @sort_tiebreak.blank?

      sql_strings + attributes_sql_expression(@sort_tiebreak)
    end

    def attributes_sql_expression(sort_attribute)
      sql_strings = []
      if sort_attribute.present?
        sorts = sort_attribute.split(",")
        sorts.each_with_index do |sort, index|
          sort_alias = sort.split(":")[0]
          direction = sort.split(":")[1]
          modifier = sort.split(":")[2]
          begin
            sql_expression = @column_maps.find{ |m| m.alias_name.casecmp?(sort_alias) }.sql_expression
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
      end
      sql_strings << parse_custom_sort_string
      sql_strings
    end

    # This method is used for sorting enum based column
    def parse_custom_sort_string
      return '' if @column_sort_order.blank? || @column_sort_order[:sort_values].blank?

      sort_column = @column_sort_order[:column_name]
      sort_values = @column_sort_order[:sort_values]
      direction = @column_sort_order[:direction]

      sql_expression = '(CASE'
      sort_values.each_with_index do |value, index|
          sql_expression << " WHEN #{sort_column}=#{value} THEN #{index}"
      end
      sql_expression << " END) #{direction}" 
      sql_expression
    end
  end
end
