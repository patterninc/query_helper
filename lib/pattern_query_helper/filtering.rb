module PatternQueryHelper
  class Filtering
    def self.create_filters(filters, valid_columns_map=nil, symbol_prefix="")
      filters ||= {}
      all_conditions = []
      filter_params = {}
      filter_array = []
      filters.each do |filter_attribute, criteria|
        if valid_columns_map
          raise ArgumentError.new("Invalid filter '#{filter_attribute}'") unless valid_columns_map[filter_attribute]
          filter_column = valid_columns_map[filter_attribute]
        else
          filter_column = filter_attribute
        end
        criteria.each do |operator_code, criterion|
          filter_symbol = "#{symbol_prefix}#{filter_attribute}_#{operator_code}"
          case operator_code
            when "gte"
              operator = ">="
            when "lte"
              operator = "<="
            when "gt"
              operator = ">"
            when "lt"
              operator = "<"
            when "eql"
              operator = "="
            when "noteql"
              operator = "!="
            when "like"
              modified_filter_column = "lower(#{filter_column})"
              operator = "like"
              criterion.downcase!
            when "in"
              operator = "in (:#{filter_symbol})"
              # if criterion are anything but numbers, downcase the filter_column
              if criterion.scan(/[^\d|,|\s]/).any?
                modified_filter_column = "lower(#{filter_column})"
              end
              criterion = criterion.downcase.split(",")
              filter_symbol_already_embedded = true
            when "notin"
              operator = "not in (:#{filter_symbol})"
              # if criterion are anything but numbers, downcase the filter_column
              if criterion.scan(/[^\d|,|\s]/).any?
                modified_filter_column = "lower(#{filter_column})"
              end
              criterion = criterion.downcase.split(",")
              filter_symbol_already_embedded = true
            when "null"
              operator = criterion.to_s == "true" ? "is null" : "is not null"
              filter_symbol = ""
            else
              raise ArgumentError.new("Invalid operator code '#{operator_code}' on '#{filter_attribute}' filter")
          end
          filter_column = modified_filter_column || filter_column
          condition = "#{filter_column} #{operator}"
          condition << " :#{filter_symbol}" unless filter_symbol_already_embedded or filter_symbol.blank?
          all_conditions << condition
          filter_params["#{filter_symbol}"] = criterion unless filter_symbol.blank?
          filter_array << {
            column: filter_attribute,
            operator: operator,
            value: criterion,
            symbol: filter_symbol
          }
        end
      end

      filter_string = ""
      filter_string = "where " + all_conditions.join("\n and ") unless all_conditions.empty?

      {
        filter_string: filter_string,
        filter_params: filter_params,
        filter_array: filter_array
      }

    end
  end
end
