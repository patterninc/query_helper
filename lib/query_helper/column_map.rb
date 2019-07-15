require "query_helper/sql_parser"

class QueryHelper
  class ColumnMap

    def self.create_column_mappings(custom_mappings:, query:, model:)
      parser = SqlParser.new(query)
      maps = create_from_hash(custom_mappings)

      parser.find_aliases.each do |m|
        maps << m if maps.select{|x| x.alias_name == m.alias_name}.empty?
      end

      model.attribute_names.each do |attribute|
        if maps.select{|x| x.alias_name == attribute}.empty?
          maps << ColumnMap.new(alias_name: attribute, sql_expression: "#{model.to_s.downcase.pluralize}.#{attribute}")
        end
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
