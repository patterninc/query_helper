module QueryHelper
  class QueryString

    attr_accessor :query_string, :where_filters, :having_filters, :sorts, :page, :per_page, :alias_map

    # I've opted to make several methods class methods
    # in order to utilize them in other parts of the gem

    def self.remove_comments(query)
      # Remove sql comments
      query.gsub(/\/\*(.*?)\*\//, '').gsub(/--(.*)$/, '')
    end

    def self.white_out_query(query)
      # Replace everything between () and '' and "" to find indexes.
      # This will allow us to ignore subqueries and common table expressions when determining injection points
      white_out = query.dup
      while white_out.scan(/\"[^""]*\"|\'[^'']*\'|\([^()]*\)/).length > 0 do
        white_out.scan(/\"[^""]*\"|\'[^'']*\'|\([^()]*\)/).each { |s| white_out.gsub!(s,s.gsub(/./, '*')) }
      end
      white_out
    end

    def self.last_select_index(query)
      # space or new line at beginning of select
      # return index at the end of the word
      query.rindex(/( |^)[Ss][Ee][Ll][Ee][Cc][Tt] /) + query[/( |^)[Ss][Ee][Ll][Ee][Cc][Tt] /].size
    end

    def self.last_from_index(query)
      query.index(/ [Ff][Rr][Oo][Mm] /, last_select_index(query))
    end

    def self.last_where_index(query)
      query.index(/ [Ww][Hh][Ee][Rr][Ee] /, last_select_index(query))
    end

    def self.last_group_by_index(query)
      query.index(/ [Gg][Rr][Oo][Uu][Pp] [Bb][Yy] /, last_select_index(query))
    end

    def self.last_having_index(query)
      query.index(/ [Hh][Aa][Vv][Ii][Nn][Gg] /, last_select_index(query))
    end

    def self.last_order_by_index(query)
      query.index(/ [Oo][Rr][Dd][Ee][Rr] [Bb][Yy ]/, last_select_index(query))
    end

    def initialize(
      sql:,
      where_filters: [],
      having_filters: [],
      sorts: [],
      page: nil,
      per_page: nil
    )
      @sql = self.class.remove_comments(sql).squish
      @where_filters = where_filters
      @having_filters = having_filters
      @sorts = sorts
      @page = page.to_i if page # Turn into an integer to avoid any potential sql injection
      @per_page = per_page.to_i if per_page # Turn into an integer to avoid any potential sql injection
      calculate_indexes()
      true
    end

    def build
      modified_sql = @sql.dup
      modified_sql = modified_sql.slice(0, @last_order_by_index) if @order_by_included # Remove previous sorting if it exists
      modified_sql.insert(modified_sql.length, pagination_insert) if @page && @per_page
      modified_sql.insert(@insert_order_by_index, sort_insert) if @sorts && @sorts.length > 0
      modified_sql.insert(@insert_having_index, having_insert) if @having_filters && @having_filters.length > 0
      modified_sql.insert(@insert_where_index, where_insert) if @where_filters && @where_filters.length > 0
      modified_sql.insert(@insert_select_index, total_count_select_insert) if @page && @per_page
      modified_sql.squish
    end

    def update(
      where_filters: nil,
      having_filters: nil,
      sorts: nil,
      page: nil,
      per_page: nil
    )
      @where_filters = where_filters if where_filters
      @having_filters = having_filters if having_filters
      @sorts = sorts if sorts
      @page = page if page
      @per_page = per_page if per_page
    end

    private

    def calculate_indexes
      white_out_sql = self.class.white_out_query(@sql)

      @where_included = !self.class.last_where_index(white_out_sql).nil?
      @group_by_included = !self.class.last_group_by_index(white_out_sql).nil?
      @having_included = !self.class.last_having_index(white_out_sql).nil?
      @order_by_included = !self.class.last_order_by_index(white_out_sql).nil?

      @insert_where_index = self.class.last_group_by_index(white_out_sql) || self.class.last_order_by_index(white_out_sql) || white_out_sql.length
      @insert_having_index = self.class.last_order_by_index(white_out_sql) || white_out_sql.length
      @insert_order_by_index = white_out_sql.length
      @insert_join_index = self.class.last_where_index(white_out_sql) || self.class.last_group_by_index(white_out_sql) || self.class.last_order_by_index(white_out_sql) || white_out_sql.length
      @insert_select_index = self.class.last_from_index(white_out_sql)
    end

    def where_insert
      begin_string = @where_included ? "and" : "where"
      filter_string = @where_filters.join(" and ")
      "  #{begin_string} #{filter_string}  "
    end

    def having_insert
      raise ArgumentError.new("Cannot include a having filter unless there is a group by clause in the query") unless @group_by_included
      begin_string = @having_included ? "and" : "having"
      filter_string = @having_filters.join(" and ")
      "  #{begin_string} #{filter_string}  "
    end

    def sort_insert
      "  order by #{sorts.join(", ")}  "
    end

    def pagination_insert
      raise ArgumentError.new("page and per_page must be integers") unless @page.class == Integer && @per_page.class == Integer
      limit = @per_page
      offset = (@page - 1) * @per_page
      "  limit #{limit} offset #{offset}  "
    end

    def total_count_select_insert
      "  ,count(*) over () as _query_full_count "
    end


  end
end
