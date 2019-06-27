module PatternQueryHelper
  class QueryString

    attr_accessor :query_string, :where_filters, :having_filters, :sorts, :page, :per_page, :alias_map

    def initialize(
      sql:,
      where_filters: [],
      having_filters: [],
      sorts: [],
      page: nil,
      per_page: nil
    )
      @sql = sql.squish
      @where_filters = where_filters
      @having_filters = having_filters
      @sorts = sorts
      @page = page.to_i if page # Turn into an integer to avoid any potential sql injection
      @per_page = per_page.to_i if per_page # Turn into an integer to avoid any potential sql injection
      calculate_indexes()
      true
    end

    def calculate_indexes
      # Remove sql comments
      @sql.gsub!(/\/\*(.*?)\*\//, '')
      @sql.gsub!(/--(.*)$/, '')

      # Replace everything between () and '' and "" to find indexes.
      # This will allow us to ignore subqueries and common table expressions when determining injection points
      white_out_sql = @sql.dup
      while white_out_sql.scan(/\"[^""]*\"|\'[^'']*\'|\([^()]*\)/).length > 0 do
        white_out_sql.scan(/\"[^""]*\"|\'[^'']*\'|\([^()]*\)/).each { |s| white_out_sql.gsub!(s,s.gsub(/./, '*')) }
      end

      @last_select_index = white_out_sql.rindex(/( |^)[Ss][Ee][Ll][Ee][Cc][Tt] /) + white_out_sql[/( |^)[Ss][Ee][Ll][Ee][Cc][Tt] /].size # space or new line at beginning of select, return index at the end of the word
      @last_from_index = white_out_sql.index(/ [Ff][Rr][Oo][Mm] /, @last_select_index)
      @last_where_index = white_out_sql.index(/ [Ww][Hh][Ee][Rr][Ee] /, @last_select_index)
      @last_group_by_index = white_out_sql.index(/ [Gg][Rr][Oo][Uu][Pp] [Bb][Yy] /, @last_select_index)
      @last_having_index = white_out_sql.index(/ [Hh][Aa][Vv][Ii][Nn][Gg] /, @last_select_index)
      @last_order_by_index = white_out_sql.index(/ [Oo][Rr][Dd][Ee][Rr] [Bb][Yy ]/, @last_select_index)

      @where_included = !@last_where_index.nil?
      @group_by_included = !@last_group_by_index.nil?
      @having_included = !@last_having_index.nil?
      @order_by_included = !@last_order_by_index.nil?

      @insert_where_index = @last_group_by_index || @last_order_by_index || white_out_sql.length
      @insert_having_index = @last_order_by_index || white_out_sql.length
      @insert_order_by_index = white_out_sql.length
      @insert_join_index = @last_where_index || @last_group_by_index || @last_order_by_index || white_out_sql.length
      @insert_select_index = @last_from_index

      # Determine alias expression combos.  White out sql used in case there are any custom strings or subqueries in the select clause
      white_out_select = white_out_sql[@last_select_index..@last_from_index]
      select_clause = @sql[@last_select_index..@last_from_index]
      comma_split_points = white_out_select.each_char.with_index.map{|char, i| i if char == ','}.compact
      comma_split_points.unshift(-1) # We need the first select clause to start out with a 'split'
      @alias_map = white_out_select.split(",").each_with_index.map do |x,i|
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
        {
          alias_name: sql_alias,
          sql_expression: sql_expression.squish,
          aggregate: /(array_agg|avg|bit_and|bit_or|bool_and|bool_or|count|every|json_agg|jsonb_agg|json_object_agg|jsonb_object_agg|max|min|string_agg|sum|xmlagg)\((.*)\)/.match?(sql_expression)
        }
      end
      @alias_map.select!{|m| !m[:alias_name].nil?}
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
  end
end
