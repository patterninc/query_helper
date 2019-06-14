module PatternQueryHelper
  class ColumnMap

    attr_accessor :alias_name, :sql_expression, :aggregate

    def initialize(
      alias_name:,
      sql_expression:,
      aggregate: false
    )
      @alias_name = alias_name
      @sql_expression = sql_expression
      @aggregate = aggregate
    end

    def self.create_from_hash(hash)
      map = []
      hash.each do |k,v|
        alias_name = k
        aggregate = false
        if v.class == String
          sql_expression = v
        elsif v.class == Hash
          sql_expression = v[:sql_expression]
          aggregate = v[:aggregate]
        end
        map << self.new(
          alias_name: alias_name,
          sql_expression: sql_expression,
          aggregate: aggregate
        )
      end
      map
    end

  end
end
