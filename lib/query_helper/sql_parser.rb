module QueryHelper
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
      # raise ArgumentError.new("Cannot calculate insert_having_index because the query has no group by clause") unless group_by_included?
      order_by_index() || limit_index() || @sql.length
    end

    def insert_order_by_index
      # ArgumentError.new("This query already includes an order by clause") if order_by_included?
      limit_index() || @sql.length
    end

    def insert_limit_index
      # ArgumentError.new("This query already includes a limit clause") if limit_included?
      @sql.length
    end

    def select_clause
      @sql[select_index()..insert_select_index()] if select_included?
    end

    def from_clause
      @sql[from_index()..insert_join_index()] if from_included?
    end

    def where_clause
      @sql[where_index()..insert_where_index()] if where_included?
    end

    # def group_by_clause
    #   @sql[group_by_index()..insert_group_by_index()] if group_by_included?
    # end

    def having_clause
      @sql[having_index()..insert_having_index()] if having_included?
    end

    def order_by_clause
      @sql[order_by_index()..insert_order_by_index()] if order_by_included?
    end

    def limit_clause
      @sql[limit_index()..insert_limit_index()] if limit_included?
    end

    private

    def find_index(regex, position=:start)
      start_position = @white_out_sql.rindex(regex)
      return position == :start ? start_position : start_position + @white_out_sql[regex].size()
    end
  end
end
