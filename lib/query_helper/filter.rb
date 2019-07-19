require "query_helper/invalid_query_error"

class QueryHelper
  class Filter

    attr_accessor :operator, :criterion, :comparate, :operator_code, :bind_variable, :aggregate

    def initialize(
      operator_code:,
      criterion:,
      comparate:,
      aggregate: false
    )
      @operator_code = operator_code
      @criterion = criterion # Converts to a string to be inserted into sql.
      @comparate = comparate
      @aggregate = aggregate
      @bind_variable = ('a'..'z').to_a.shuffle[0,20].join.to_sym

      translate_operator_code()
      mofify_criterion()
      modify_comparate()
      validate_criterion()
    end

    def sql_string
      case operator_code
      when "in", "notin"
        "#{comparate} #{operator} (:#{bind_variable})"
      when "null"
        "#{comparate} #{operator}"
      else
        "#{comparate} #{operator} :#{bind_variable}"
      end

    end

    private

    def translate_operator_code
      @operator = case operator_code
        when "gte"
          ">="
        when "lte"
          "<="
        when "gt"
          ">"
        when "lt"
          "<"
        when "eql"
          "="
        when "noteql"
          "!="
        when "in"
          "in"
        when "like"
          "like"
        when "notin"
          "not in"
        when "null"
          if criterion.to_s == "true"
            "is null"
          else
            "is not null"
          end
        else
          raise InvalidQueryError.new("Invalid operator code: '#{operator_code}'")
      end
    end

    def mofify_criterion
      # lowercase strings for comparison
      @criterion.downcase! if criterion.class == String && criterion.scan(/[a-zA-Z]/).any?

      # turn the criterion into an array for in and notin comparisons
      @criterion = criterion.split(",") if ["in", "notin"].include?(operator_code) && criterion.class == String
    end

    def modify_comparate
      # lowercase strings for comparison
      @comparate = "lower(#{@comparate})" if criterion.class == String && criterion.scan(/[a-zA-Z]/).any? && !["true", "false"].include?(criterion)
    end

    def validate_criterion
      case operator_code
        when "gte", "lte", "gt", "lt"
          begin
            Time.parse(criterion.to_s)
          rescue
            begin
              Date.parse(criterion.to_s)
            rescue
              begin
                Float(criterion.to_s)
              rescue
                invalid_criterion_error()
              end
            end
          end
        when "in", "notin"
          invalid_criterion_error() unless criterion.class == Array
        when "null"
          invalid_criterion_error() unless ["true", "false"].include?(criterion.to_s)
      end
      true
    end

    def invalid_criterion_error
      raise InvalidQueryError.new("'#{criterion}' is not a valid criterion for the '#{@operator}' operator")
    end
  end
end
