module PatternQueryHelper
  class Sql
    def self.sql_query(config)
      model = config[:model]
      query_params = config[:query_params] || {}
      page = config[:page]
      per_page = config[:per_page]
      filter_params = config[:filter_params] || {}
      sort_string = config[:sort_string]

      if page && per_page
        query_params[:limit] = per_page
        query_params[:offset] = (page - 1) * per_page
        limit = "limit :limit offset :offset"
      end

      query_params = query_params.merge(filter_params).symbolize_keys
      sort_string = "order by #{sort_string}" if !sort_string.blank?

      sql = %(
        with filtered_query as (#{filtered_query(config)})
        select *
        from filtered_query
        join (select count(*) as full_count from filtered_query) as filtered_query_count on true
        #{sort_string}
        #{limit}
      )

      model.find_by_sql([sql, query_params])
    end

    def self.sql_query_count(config)
      results = sql_query(config)
      count = results.empty? ?  0 : results.first["full_count"]
    end

    def self.single_record_query(config)
      results = sql_query(config)
      results.first
    end

    private

    def self.filtered_query(config)
      query = config[:query]
      filter_string = config[:filter_string]
      filter_string = "where #{filter_string}" if !filter_string.blank?

      sql = %(
          with query as (#{query})
          select *
          from query
          #{filter_string}
        )
    end
  end
end
