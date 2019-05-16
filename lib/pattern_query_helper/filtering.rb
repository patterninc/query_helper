module PatternQueryHelper
  class Filtering
    def self.create_filters(filters, valid_columns=nil, symbol_prefix="")
      filters ||= {}
      filter_string = "true = true"
      filter_params = {}
      filter_array = []
      filters.each do |filter_attribute, criteria|
        if valid_columns
          raise ArgumentError.new("Invalid filter '#{filter_attribute}'") unless valid_columns.include? filter_attribute
        end
        filter_column = filter_attribute
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
            when "likewilds"
              values = criterion
            when "likeprewild"
              pass
            when "likepostwild"
              pass
            when "in"
              values = criterion.split(",").map { |s| s.to_i }
              values = values.to_s.gsub("[","(").gsub("]",")")
              operator = "in #{values}"
              filter_symbol = ""
            when "notin"
              values = criterion.split(",").map { |s| s.to_i }
              values = values.to_s.gsub("[","(").gsub("]",")")
              operator = "not in #{values}"
              filter_symbol = ""
            when "null"
              if criterion = true || "true"
                operator = "is null"
              elsif criterion = false || "false"
                operator = "is not null"
              end
              filter_symbol = ""
            else
              raise ArgumentError.new("Invalid operator code '#{operator_code}' on '#{filter_attribute}' filter")
          end
          filter_symbol_embed = ":#{filter_symbol}" unless filter_symbol.blank?
          filter_string = "#{filter_string} and #{filter_column} #{operator} #{filter_symbol_embed}"
          filter_params["#{filter_symbol}"] = criterion
          filter_array << {
            column: filter_attribute,
            operator: operator,
            value: criterion,
            symbol: filter_symbol
          }
        end
      end

      {
        filter_string: filter_string,
        filter_params: filter_params,
        filter_array: filter_array
      }

    end
  end
end
