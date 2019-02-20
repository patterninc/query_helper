module PatternQueryHelper
  class Sql
    def self.sql_query(config)
      model = config[:model]
      query = config[:query]
      query_params = config[:query_params]
      pagination_params = config[:pagination_params]
      filter_string = config[:filter_string]
      filter_params = config[:filter_params]
      sort_string = config[:sort_string]

      query_params = query_params.merge(filter_params)

      count_sql = %(
          with query as (#{query})
          select count(*) as count
          from query
          where #{filter_string}
        )

      count = model.find_by_sql([count_sql, query_params]).first["count"]
      query_params[:limit] = pagination_params[:per_page]
      query_params[:offset] = (pagination_params[:page] - 1) * pagination_params[:per_page]
      limit = "limit :limit offset :offset"

      sorts = "order by #{@sorts}" if !@sorts.blank?

      sql = %(
          select *
          from (#{query}) as query
          where #{@filter_string}
          #{sorts}
          #{limit}
        )

      results = include_associations(model.find_by_sql([sql, query_params]), @associations)
    end
  end
end
