require "pattern_query_helper/version"
require "pattern_query_helper/pagination"
require "pattern_query_helper/filtering"
require "pattern_query_helper/associations"
require "pattern_query_helper/sorting"
require "pattern_query_helper/sql"

module PatternQueryHelper
  def self.paginated_sql_query(model, query, query_params, url_params)
    query_helpers = parse_params(url_params)

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
    data = PatternQueryHelper::Associations.load_associations(data, query_helpers[:associations])
    count = PatternQueryHelper::Sql.sql_query_count(query_config)
    pagination = PatternQueryHelper::Pagination.create_pagination_payload(count, query_helpers[:pagination])

    {
      pagination: pagination,
      data: data
    }
  end

  def self.sql_query(model, query, query_params, url_params)
    query_helpers = parse_params(url_params)

    query_config = {
      model: model,
      query: query,
      query_params: query_params,
      filter_string: query_helpers[:filters][:filter_string],
      filter_params: query_helpers[:filters][:filter_params],
      sort_string: query_helpers[:sorting],
    }

    data = PatternQueryHelper::Sql.sql_query(query_config)
    data = PatternQueryHelper::Associations.load_associations(data, query_helpers[:associations])

    {
      data: data
    }
  end

  def self.single_record_sql_query(model, query, query_params, url_params)
    query_helpers = parse_params(url_params)

    query_config = {
      model: model,
      query: query,
      query_params: query_params,
      filter_string: query_helpers[:filters][:filter_string],
      filter_params: query_helpers[:filters][:filter_params],
      sort_string: query_helpers[:sorting],
    }

    data = PatternQueryHelper::Sql.single_record_query(query_config)
    data = PatternQueryHelper::Associations.load_associations(data, query_helpers[:associations])

    {
      data: data
    }
  end

  def self.active_record_query(active_record_call, url_params)
    query_helpers = parse_params(url_params)
    filtered_query = PatternQueryHelper::Filtering.filter_active_record_query(active_record_call, query_helpers[:filters])
    sorted_query = PatternQueryHelper::Sorting.sort_active_record_query(active_record_call, query_helpers[:sorting])
    with_associations = PatternQueryHelper::Associations.load_associations(sorted_query, query_helpers[:associations])
    {
      data: with_associations
    }
  end

  def self.paginated_active_record_query(active_record_call, url_params)
    query_helpers = parse_params(url_params)
    filtered_query = PatternQueryHelper::Filtering.filter_active_record_query(active_record_call, query_helpers[:filters])
    sorted_query = PatternQueryHelper::Sorting.sort_active_record_query(active_record_call, query_helpers[:sorting])
    paginated_query = PatternQueryHelper::Pagination.paginate_active_record_query(sorted_query, query_helpers[:pagination])
    with_associations = PatternQueryHelper::Associations.load_associations(paginated_query, query_helpers[:associations])
    pagination = PatternQueryHelper::Pagination.create_pagination_payload(sorted_query.count, query_helpers[:pagination])
    {
      pagination: pagination,
      data: with_associations
    }
  end

  def self.single_record_active_record_query
    # TODO: Add Logic to this method
  end

  def self.parse_params(params)
    filtering = PatternQueryHelper::Filtering.create_filters(params)
    sorting = PatternQueryHelper::Sorting.parse_sorting_params(params)
    associations = PatternQueryHelper::Associations.process_association_params(params)
    pagination = PatternQueryHelper::Pagination.parse_pagination_params(params)

    {
      filters: filtering,
      sorting: sorting,
      associations: associations,
      pagination: pagination
    }
  end

  class << self
    attr_accessor :active_record_adapter
  end
end
