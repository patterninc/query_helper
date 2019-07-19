require "query_helper/sql_parser"

class QueryHelper
  class SqlManipulator

    attr_accessor :sql

    def initialize(
      sql:,
      where_clauses: nil,
      having_clauses: nil,
      order_by_clauses: nil,
      include_limit_clause: false
    )
      @parser = SqlParser.new(sql)
      @sql = @parser.sql.dup
      @where_clauses = where_clauses
      @having_clauses = having_clauses
      @order_by_clauses = order_by_clauses
      @include_limit_clause = include_limit_clause
    end

    def build
      insert_having_clauses()
      insert_where_clauses()
      insert_total_count_select_clause()
      insert_order_by_and_limit_clause()
      @sql.squish
    end

    private

    def insert_total_count_select_clause
      return unless @include_limit_clause
      total_count_clause = " ,count(*) over () as _query_full_count "
      @sql.insert(@parser.insert_select_index, total_count_clause)
      # Potentially update parser here
    end

    def insert_where_clauses
      return unless @where_clauses.length > 0
      begin_string = @parser.where_included? ? "and" : "where"
      filter_string = @where_clauses.join(" and ")
      "  #{begin_string} #{filter_string}  "
      @sql.insert(@parser.insert_where_index, " #{begin_string} #{filter_string} ")
    end

    def insert_having_clauses
      return unless @having_clauses.length > 0
      begin_string = @parser.having_included? ? "and" : "having"
      filter_string = @having_clauses.join(" and ")
      @sql.insert(@parser.insert_having_index, " #{begin_string} #{filter_string} ")
    end

    def insert_order_by_and_limit_clause
      @sql.slice!(@parser.limit_clause) if @parser.limit_included? # remove existing limit clause
      @sql.slice!(@parser.order_by_clause) if @parser.order_by_included? # remove existing order by clause
      @sql += " order by #{@order_by_clauses.join(", ")} " if @order_by_clauses.length > 0
      @sql += " limit :limit offset :offset " if @include_limit_clause
    end
  end
end
