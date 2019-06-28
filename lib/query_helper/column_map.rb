module QueryHelper
  class ColumnMap

    def self.create_column_mappings(custom_mappings:, query:)
      default = find_aliases_in_query(query)
      maps = create_from_hash(custom_mappings)

      default.each do |m|
        maps << m if maps.select{|x| x.alias_name == m.alias_name}.empty?
      end

      maps
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

    def self.find_aliases_in_query(query)
      # Determine alias expression combos.  White out sql used in case there
      # are any custom strings or subqueries in the select clause
      select_index = QueryHelper::QueryString.last_select_index(query)
      from_index = QueryHelper::QueryString.last_from_index(query)
      white_out_select = QueryHelper::QueryString.white_out_query(query)[select_index..from_index]
      select_clause = query[select_index..from_index]
      comma_split_points = white_out_select.each_char.with_index.map{|char, i| i if char == ','}.compact
      comma_split_points.unshift(-1) # We need the first select clause to start out with a 'split'
      column_maps = white_out_select.split(",").each_with_index.map do |x,i|
        sql_alias = x.squish.split(" as ")[1] || x.squish.split(" AS ")[1] || x.squish.split(".")[1] # look for custom defined aliases or table.column notation
        sql_alias = nil unless /^[a-zA-Z_]+$/.match?(sql_alias) # only allow aliases with letters and underscores
        sql_expression = if x.split(" as ")[1]
          expression_length = x.split(" as ")[0].length
          select_clause[comma_split_points[i] + 1, expression_length]
        elsif x.squish.split(" AS ")[1]
          expression_length = x.split(" AS ")[0].length
          select_clause[comma_split_points[i] + 1, expression_length]
        elsif x.squish.split(".")[1]
          select_clause[comma_split_points[i] + 1, x.length]
        end
        QueryHelper::ColumnMap.new(
          alias_name: sql_alias,
          sql_expression: sql_expression.squish,
          aggregate: /(array_agg|avg|bit_and|bit_or|bool_and|bool_or|count|every|json_agg|jsonb_agg|json_object_agg|jsonb_object_agg|max|min|string_agg|sum|xmlagg)\((.*)\)/.match?(sql_expression)
        ) if sql_alias
      end
      column_maps.compact
    end

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

  end
end
