module PatternQueryHelper
  class Sql
    def self.sql_query(config)
      model = config[:model]
      query = config[:query]
      query_params = config[:query_params] || {}
      page = config[:page]
      per_page = config[:per_page]
      filter_string = config[:filter_string]
      filter_params = config[:filter_params] || {}
      sort_string = config[:sort_string]

      if page && per_page
        query_params[:limit] = per_page
        query_params[:offset] = (page - 1) * per_page
        limit = "limit :limit offset :offset"
      end

      query_params = query_params.merge(filter_params).symbolize_keys
      sort_string = "order by #{sort_string}" if !sort_string.blank?
      filter_string = "where #{filter_string}" if !filter_string.blank?

      sql = %(
          with query as (#{query})
          select *
          from query
          #{filter_string}
          #{sort_string}
          #{limit}
        )

      model.find_by_sql([sql, query_params])
    end

    def self.sql_query_count(config)
      model = config[:model]
      query = config[:query]
      query_params = config[:query_params] || {}
      filter_string = config[:filter_string]
      filter_params = config[:filter_params] || {}

      query_params = query_params.merge(filter_params).symbolize_keys
      filter_string = "where #{filter_string}" if !filter_string.blank?

      count_sql = %(
          with query as (#{query})
          select count(*) as count
          from query
          #{filter_string}
        )

      model.find_by_sql([count_sql, query_params]).first["count"]
    end

  end
end
