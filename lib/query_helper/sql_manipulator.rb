require "query_helper/sql_parser"

class QueryHelper
  class SqlManipulator

    attr_accessor :sql

    def initialize(
      sql:,
      where_clauses: nil,
      having_clauses: nil,
      qualify_clauses: nil,
      order_by_clauses: nil,
      include_limit_clause: false,
      additional_select_clauses: []
    )
      sql = remove_qualified_count(sql.dup)
      @parser = SqlParser.new(sql)
      @sql = @parser.sql.dup
      @where_clauses = where_clauses
      @having_clauses = having_clauses
      @qualify_clauses = qualify_clauses
      @order_by_clauses = order_by_clauses
      @include_limit_clause = include_limit_clause
      @additional_select_clauses = additional_select_clauses
    end

    def build
      insert_having_clauses()
      insert_qualify_clauses()
      insert_where_clauses()

      if qualify_clause_applicable? || @qualify_present
        insert_order_by_and_limit_clause()
        insert_qualified_count_clauses() if @include_limit_clause
      else
        insert_select_clauses()
        insert_order_by_and_limit_clause()
      end

      @sql.squish
    end

    private

    def insert_select_clauses
      @additional_select_clauses << count_sql if @include_limit_clause
      @sql.insert(@parser.insert_select_index, " , #{@additional_select_clauses.join(", ")} ") if @additional_select_clauses.length > 0
    end

    def count_sql
      "count(*) over () as _query_full_count"
    end

    def qualify_clauses(index)
      if index == 0
        "qualified_results AS ( "
      else
        ", qualified_results AS ( "
      end
    end

    # If modifying something please check remove_qualified_count method too
    def insert_qualified_count_clauses
      @sql.insert(@parser.select_index, qualify_clauses(@parser.select_index))
      @sql.insert(@sql.length, ") SELECT qualified_results.*, #{count_sql} FROM qualified_results")
    end

    # If modifying something please check insert_qualified_count_clauses method too
    def remove_qualified_count(unparsed_sql)
      @qualify_present = unparsed_sql.include?("qualified_results")
      return unparsed_sql unless @qualify_present

      unparsed_sql.gsub!(/[\,\s]?qualified_results AS \( /, '')
      unparsed_sql.gsub!(") SELECT qualified_results.*, count(*) over () as _query_full_count FROM qualified_results", '')
      unparsed_sql
    end

    def insert_where_clauses
      return unless @where_clauses.length > 0
      begin_string = @parser.where_included? ? "and" : "where"
      filter_string = @where_clauses.join(" and ")
      @sql.insert(@parser.insert_where_index, " #{begin_string} #{filter_string} ")
    end

    def insert_qualify_clauses
      return unless qualify_clause_applicable?

      begin_string = @parser.qualify_included? ? "and" : "qualify"
      filter_string = @qualify_clauses.join(" and ")
      @sql.insert(@parser.insert_where_index, " #{begin_string} #{filter_string} ")
    end

    def qualify_clause_applicable?
      @qualify_clauses.length > 0
    end

    def insert_having_clauses
      return unless @having_clauses.length > 0
      begin_string = @parser.having_included? ? "and" : "having"
      filter_string = @having_clauses.join(" and ")
      @sql.insert(@parser.insert_having_index, " #{begin_string} #{filter_string} ")
    end

    def insert_order_by_and_limit_clause
      @sql.slice!(@parser.limit_clause) if @parser.limit_included? # remove existing limit clause
      @sql.slice!(@parser.order_by_clause) if @parser.order_by_included? && @order_by_clauses.length > 0 # remove existing order by clause
      @sql += " order by #{@order_by_clauses.join(", ")} " if @order_by_clauses.length > 0
      @sql += " limit :limit offset :offset " if @include_limit_clause
    end
  end
end
