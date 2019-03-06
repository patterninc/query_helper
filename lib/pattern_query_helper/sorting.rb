module PatternQueryHelper
  class Sorting
    def self.parse_sorting_params(sort, valid_columns)
      sort_sql = []
      if sort
        sorts = sort.split(",")
        sorts.each_with_index do |sort, index|
          column = sort.split(":")[0]
          direction = sort.split(":")[1]
          modifier = sort.split(":")[2]

          raise ArgumentError.new("Sorting not allowed on column '#{column}'") unless valid_columns.include? column

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
            column = "lower(#{column})"
          end

          sort_sql << "#{column} #{direction}"
        end
      end
      sort_sql.join(", ")
    end

    def self.sort_active_record_query(active_record_call, sort_string)
      active_record_call.order(sort_string)
    end
  end
end
