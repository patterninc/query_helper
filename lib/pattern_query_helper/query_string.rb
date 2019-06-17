module PatternQueryHelper
  class QueryString

    attr_accessor :query_string, :modified_query_string

    def initialize(query_string)
      @query_string = query_string.squish
      @modified_query_string = @query_string
      calculate_indexes()
      true

    end

    def calculate_indexes
      @last_select_index = modified_query_string.rindex(/[Ss][Ee][Ll][Ee][Cc][Tt]/)
      @last_where_index = modified_query_string.index(/[Ww][Hh][Ee][Rr][Ee]/, @last_select_index)
      @last_group_by_index = modified_query_string.index(/[Gg][Rr][Oo][Uu][Pp] [Bb][Yy]/, @last_select_index)
      @last_having_index = modified_query_string.index(/[Hh][Aa][Vv][Ii][Nn][Gg]/, @last_select_index)
      @last_order_by_index = modified_query_string.index(/[Oo][Rr][Dd][Ee][Rr] [Bb][Yy]/, @last_select_index)

      @where_included = !@last_where_index.nil?
      @group_by_included = !@last_group_by_index.nil?
      @having_included = !@last_having_index.nil?
      @order_by_included = !@last_order_by_index.nil?

      @insert_where_index = @last_group_by_index || @last_order_by_index || @modified_query_string.length
      @insert_having_index = @last_order_by_index || @modified_query_string.length
      @insert_order_by_index = @modified_query_string.length
    end

    def add_where_filters(filters)
      begin_string = @where_included ? "and" : "where"
      filter_string = filters.join(" and ")
      where_string = "  #{begin_string} #{filter_string}  " #included extra spaces at beginning and end to buffer insert with correct spacing
      @modified_query_string.insert(@insert_where_index, where_string).squish!
      calculate_indexes() # recalculate indexes now that the query has been modified
    end

    def add_having_filters(filters)
      raise ArgumentError.new("Cannot include a having filter unless there is a group by clause in the query") unless @group_by_included
      begin_string = @having_included ? "and" : "having"
      filter_string = filters.join(" and ")
      having_string = "  #{begin_string} #{filter_string}  " #included extra spaces at beginning and end to buffer insert with correct spacing
      @modified_query_string.insert(@insert_having_index, having_string).squish!
      calculate_indexes() # recalculate indexes now that the query has been modified
    end

    def add_sorting(sorts)
      @modified_query_string = @modified_query_string.slice(0, @last_order_by_index) if @order_by_included # Remove previous sorting if it exists
      calculate_indexes()
      sort_string = "  order by #{sorts.join(", ")}  " # included extra spaces at beginning and end to buffer insert with correct spacing
      @modified_query_string.insert(@insert_order_by_index, sort_string).squish!
      calculate_indexes() # recalculate indexes now that the query has been modified
    end

    def add_pagination(page, per_page)
      raise ArgumentError.new("page and per_page must be integers") unless page.class == Integer && per_page.class == Integer
      limit = per_page
      offset = (page - 1) * per_page
      pagination_string = "  limit #{limit} offset #{offset}  "
      @modified_query_string.insert(@modified_query_string.length, pagination_string).squish!
    end

    def modify_query(
      where_filters: nil,
      having_filters: nil,
      sorts: nil,
      page: nil,
      per_page: nil
    )
      add_pagination(page, per_page) if page && per_page
      add_having_filters(having_filters) if having_filters
      add_where_filters(where_filters) if where_filters
      add_sorting(sort) if sorts
    end

  end
end
