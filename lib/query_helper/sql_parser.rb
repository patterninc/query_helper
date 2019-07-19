require "query_helper/invalid_query_error"
require "query_helper/column_map"

class QueryHelper
  class SqlParser

    attr_accessor :sql

    def initialize(sql)
      update(sql)
    end

    def update(sql)
      @sql = sql
      remove_comments()
      white_out()
    end

    def remove_comments
      # Remove SQL inline comments (/* */) and line comments (--)
      @sql = @sql.gsub(/\/\*(.*?)\*\//, '').gsub(/--(.*)$/, '')
      @sql.squish!
    end

    def white_out
      # Replace everything between () and '' and ""
      # This will allow us to ignore subqueries, common table expressions,
      # regex, custom strings, etc. when determining injection points
      # and performing other manipulations
      @white_out_sql = @sql.dup
      while @white_out_sql.scan(/\"[^""]*\"|\'[^'']*\'|\([^()]*\)/).length > 0 do
        @white_out_sql.scan(/\"[^""]*\"|\'[^'']*\'|\([^()]*\)/).each { |s| @white_out_sql.gsub!(s,s.gsub(/./, '*')) }
      end
    end

    def select_index(position=:start)
      regex = /( |^)[Ss][Ee][Ll][Ee][Cc][Tt] / # space or new line at beginning of select
      find_index(regex, position)
    end

    def from_index(position=:start)
      regex = / [Ff][Rr][Oo][Mm] /
      find_index(regex, position)
    end

    def where_index(position=:start)
      regex = / [Ww][Hh][Ee][Rr][Ee] /
      find_index(regex, position)
    end

    def group_by_index(position=:start)
      regex = / [Gg][Rr][Oo][Uu][Pp] [Bb][Yy] /
      find_index(regex, position)
    end

    def having_index(position=:start)
      regex = / [Hh][Aa][Vv][Ii][Nn][Gg] /
      find_index(regex, position)
    end

    def order_by_index(position=:start)
      regex = / [Oo][Rr][Dd][Ee][Rr] [Bb][Yy] /
      find_index(regex, position)
    end

    def limit_index(position=:start)
      regex = / [Ll][Ii][Mm][Ii][Tt] /
      find_index(regex, position)
    end

    def select_included?
      !select_index.nil?
    end

    def from_included?
      !from_index.nil?
    end

    def where_included?
      !where_index.nil?
    end

    def group_by_included?
      !group_by_index.nil?
    end

    def having_included?
      !having_index.nil?
    end

    def order_by_included?
      !order_by_index.nil?
    end

    def limit_included?
      !limit_index.nil?
    end

    def insert_select_index
      from_index() || where_index() || group_by_index() || order_by_index() || limit_index() || @sql.length
    end

    def insert_join_index
      where_index() || group_by_index() || order_by_index() || limit_index() || @sql.length
    end

    def insert_where_index
      group_by_index() || order_by_index() || limit_index() || @sql.length
    end

    def insert_having_index
      # raise InvalidQueryError.new("Cannot calculate insert_having_index because the query has no group by clause") unless group_by_included?
      order_by_index() || limit_index() || @sql.length
    end

    def insert_order_by_index
      # raise InvalidQueryError.new("This query already includes an order by clause") if order_by_included?
      limit_index() || @sql.length
    end

    def insert_limit_index
      # raise InvalidQueryError.new("This query already includes a limit clause") if limit_included?
      @sql.length
    end

    def select_clause
      @sql[select_index()..insert_select_index()].strip if select_included?
    end

    def from_clause
      @sql[from_index()..insert_join_index()].strip if from_included?
    end

    def where_clause
      @sql[where_index()..insert_where_index()].strip if where_included?
    end

    # def group_by_clause
    #   @sql[group_by_index()..insert_group_by_index()] if group_by_included?
    # end

    def having_clause
      @sql[having_index()..insert_having_index()].strip if having_included?
    end

    def order_by_clause
      @sql[order_by_index()..insert_order_by_index()].strip if order_by_included?
    end

    def limit_clause
      @sql[limit_index()..insert_limit_index()].strip if limit_included?
    end

    def find_aliases
      # Determine alias expression combos.  White out sql used in case there
      # are any custom strings or subqueries in the select clause
      white_out_selects = @white_out_sql[select_index(:end)..from_index()]
      selects = @sql[select_index(:end)..from_index()]
      comma_split_points = white_out_selects.each_char.with_index.map{|char, i| i if char == ','}.compact
      comma_split_points.unshift(-1) # We need the first select clause to start out with a 'split'
      column_maps = white_out_selects.split(",").each_with_index.map do |x,i|
        sql_alias = x.squish.split(" as ")[1] || x.squish.split(" AS ")[1] || x.squish.split(".")[1] # look for custom defined aliases or table.column notation
        # sql_alias = nil unless /^[a-zA-Z_]+$/.match?(sql_alias) # only allow aliases with letters and underscores
        sql_expression = if x.split(" as ")[1]
          expression_length = x.split(" as ")[0].length
          selects[comma_split_points[i] + 1, expression_length]
        elsif x.squish.split(" AS ")[1]
          expression_length = x.split(" AS ")[0].length
          selects[comma_split_points[i] + 1, expression_length]
        elsif x.squish.split(".")[1]
          selects[comma_split_points[i] + 1, x.length]
        end
        ColumnMap.new(
          alias_name: sql_alias,
          sql_expression: sql_expression.squish,
          aggregate: /(array_agg|avg|bit_and|bit_or|bool_and|bool_or|count|every|json_agg|jsonb_agg|json_object_agg|jsonb_object_agg|max|min|string_agg|sum|xmlagg)\((.*)\)/.match?(sql_expression)
        ) if sql_alias
      end
      column_maps.compact
    end

    private

    def find_index(regex, position=:start)
      start_position = @white_out_sql.rindex(regex)
      return position == :start ? start_position : start_position + @white_out_sql[regex].size()
    end
  end
end
