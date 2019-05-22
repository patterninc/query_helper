module PatternQueryHelper
  class Sql
    QUERY_COUNT_COLUMN = "_query_full_count".freeze
    def self.sql_query(config)
      model = config[:model]
      query_params = config[:query_params] || {}
      page = config[:page]
      per_page = config[:per_page]
      filter_params = config[:filter_params] || {}

      if page && per_page
        query_params[:limit] = per_page
        query_params[:offset] = (page - 1) * per_page
        limit = "limit :limit offset :offset"
      end

      full_count_join = "join (select count(*) as #{QUERY_COUNT_COLUMN} from filtered_query) as filtered_query_count on true" if page || per_page
      query_params = query_params.merge(filter_params).symbolize_keys

      sql = %(
        with filtered_query as (#{filtered_query(config)})
        select *
        from filtered_query
        #{full_count_join}
        #{limit}
      )

      model.find_by_sql([sql, query_params])
    end

    def self.sql_query_count(sql_query_results)
      sql_query_results.empty? ? 0 : sql_query_results.first[QUERY_COUNT_COLUMN]
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
      sort_string = config[:sort_string]
      sort_string = "order by #{sort_string}" if !sort_string.blank?

      sql = %(
          with query as (#{query})
          select *
          from query
          #{filter_string}
          #{sort_string}
        )
    end
  end
end
