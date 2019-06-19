module PatternQueryHelper
  class QueryString

    attr_accessor :query_string, :where_filters, :having_filters, :sorts, :page, :per_page

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
      @page = page
      @per_page = per_page
      calculate_indexes()
      true
    end

    def calculate_indexes
      # Replace everything between () to find indexes.
      # This will allow us to ignore subueries when determing indexes
      white_out_sql = @sql.dup
      while white_out_sql.scan(/\([^()]*\)/).length > 0 do
        white_out_sql.scan(/\([^()]*\)/).each { |s| white_out_sql.gsub!(s,s.gsub(/./, '*')) }
      end

      @last_select_index = white_out_sql.rindex(/(?<!\(|\( )[Ss][Ee][Ll][Ee][Cc][Tt]/)  # Last select that isn't a subquery (denoted by a '(' or '( ')
      @last_from_index = white_out_sql.rindex(/[Ff][Rr][Oo][Mm]/)
      @last_where_index = white_out_sql.index(/[Ww][Hh][Ee][Rr][Ee]/, @last_select_index)
      @last_group_by_index = white_out_sql.index(/[Gg][Rr][Oo][Uu][Pp] [Bb][Yy]/, @last_select_index)
      @last_having_index = white_out_sql.index(/[Hh][Aa][Vv][Ii][Nn][Gg]/, @last_select_index)
      @last_order_by_index = white_out_sql.index(/[Oo][Rr][Dd][Ee][Rr] [Bb][Yy]/, @last_select_index)

      @where_included = !@last_where_index.nil?
      @group_by_included = !@last_group_by_index.nil?
      @having_included = !@last_having_index.nil?
      @order_by_included = !@last_order_by_index.nil?

      @insert_where_index = @last_group_by_index || @last_order_by_index || white_out_sql.length
      @insert_having_index = @last_order_by_index || white_out_sql.length
      @insert_order_by_index = white_out_sql.length
      @insert_join_index = @last_where_index || @last_group_by_index || @last_order_by_index || white_out_sql.length
      @insert_select_index = @last_from_index
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
  end
end
