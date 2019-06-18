module PatternQueryHelper
  class Sort

    attr_accessor :sort_strings

    def initialize(sort_string:, column_maps:)
      @sort_string = sort_string
      @column_maps = column_maps
      @sort_strings = []
      parse_sort_string()
    end

    def parse_sort_string
      sorts = @sort_string.split(",")
      sorts.each_with_index do |sort, index|
        sort_alias = sort.split(":")[0]
        direction = sort.split(":")[1]
        modifier = sort.split(":")[2]

        begin
          sql_expression = @column_maps.find{ |m| m.alias_name == sort_alias }.sql_expression
        rescue NoMethodError => e
          raise ArgumentError.new("Sorting not allowed on column '#{sort_alias}'")
        end

        if direction == "desc"
          case PatternQueryHelper.active_record_adapter
          when "sqlite3"
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

        @sort_strings << "#{sql_expression} #{direction}"
      end
    end
  end
end
