require "pattern_query_helper/version"
require "pattern_query_helper/pagination"
require "pattern_query_helper/filtering"
require "pattern_query_helper/associations"
require "pattern_query_helper/sorting"
require "pattern_query_helper/sql"

module PatternQueryHelper

  def self.run_sql_query(model, query, query_params, query_helpers, valid_columns=[], single_record=false)
    if single_record
      single_record_sql_query(model, query, query_params, query_helpers, valid_columns)
    elsif query_helpers[:per_page] || query_helpers[:page]
      paginated_sql_query(model, query, query_params, query_helpers, valid_columns)
    else
      sql_query(model, query, query_params, query_helpers, valid_columns)
    end
  end

  def self.run_active_record_query(active_record_call, query_helpers, valid_columns=[], single_record=false)
    run_sql_query(active_record_call.model, active_record_call.to_sql, {}, query_helpers, valid_columns, single_record)
  end

  private

  def self.paginated_sql_query(model, query, query_params, query_helpers, valid_columns)
    query_helpers = parse_helpers(query_helpers, valid_columns)

    query_config = {
      model: model,
      query: query,
      query_params: query_params,
      page: query_helpers[:pagination][:page],
      per_page: query_helpers[:pagination][:per_page],
      filter_string: query_helpers[:filters][:filter_string],
      filter_params: query_helpers[:filters][:filter_params],
      sort_string: query_helpers[:sorting],
    }

    data = PatternQueryHelper::Sql.sql_query(query_config)
    data = PatternQueryHelper::Associations.load_associations(data, query_helpers[:associations], query_helpers[:as_json])
    count = PatternQueryHelper::Sql.sql_query_count(data)
    data.map! { |d| d.except(PatternQueryHelper::Sql::QUERY_COUNT_COLUMN) } if query_config[:page] or query_config[:per_page]
    pagination = PatternQueryHelper::Pagination.create_pagination_payload(count, query_helpers[:pagination])

    {
      pagination: pagination,
      data: data
    }
  end

  def self.sql_query(model, query, query_params, query_helpers, valid_columns)
    query_helpers = parse_helpers(query_helpers, valid_columns)

    query_config = {
      model: model,
      query: query,
      query_params: query_params,
      filter_string: query_helpers[:filters][:filter_string],
      filter_params: query_helpers[:filters][:filter_params],
      sort_string: query_helpers[:sorting],
    }

    data = PatternQueryHelper::Sql.sql_query(query_config)
    data = PatternQueryHelper::Associations.load_associations(data, query_helpers[:associations], query_helpers[:as_json])

    {
      data: data
    }
  end

  def self.single_record_sql_query(model, query, query_params, query_helpers, valid_columns)
    query_helpers = parse_helpers(query_helpers, valid_columns)

    query_config = {
      model: model,
      query: query,
      query_params: query_params,
      filter_string: query_helpers[:filters][:filter_string],
      filter_params: query_helpers[:filters][:filter_params],
      sort_string: query_helpers[:sorting],
    }

    data = PatternQueryHelper::Sql.single_record_query(query_config)
    data = PatternQueryHelper::Associations.load_associations(data, query_helpers[:associations], query_helpers[:as_json])

    {
      data: data
    }
  end

  def self.parse_helpers(query_helpers, valid_columns)
    valid_columns_map = {}
    valid_columns.each do |c|
      valid_columns_map["#{c}"] = c
    end
    filtering = PatternQueryHelper::Filtering.create_filters(filters: query_helpers[:filter], valid_columns_map: valid_columns_map)
    sorting = PatternQueryHelper::Sorting.parse_sorting_params(query_helpers[:sort], valid_columns)
    associations = PatternQueryHelper::Associations.process_association_params(query_helpers[:include])
    pagination = PatternQueryHelper::Pagination.parse_pagination_params(query_helpers[:page], query_helpers[:per_page])
    as_json = query_helpers[:as_json]

    {
      filters: filtering,
      sorting: sorting,
      associations: associations,
      pagination: pagination,
      as_json: as_json
    }
  end

  class << self
    attr_accessor :active_record_adapter
  end
end
