module PatternQueryHelper
  class Sorting
    def self.parse_sorting_params(params)
      sort_sql= []
      if params[:sort]
        sorts = params[:sort].split(",")
        sorts.each_with_index do |sort, index|
          if sort.split(":")[1] == "desc"
            case PatternQueryHelper.active_record_adapter
            when "sqlite3"
              direction = "desc"
            else
              direction = "desc null last"
            end
          else
            direction = "asc"
          end
          sort_sql << "#{sort.split(":")[0]} #{direction}"
        end
      end
      sort_sql.join(", ")
    end

    def self.sort_active_record_query(active_record_call, sort_string)
      active_record_call.order(sort_string)
    end
  end
end
