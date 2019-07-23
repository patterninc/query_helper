require 'active_support/concern'
require "query_helper/sql_filter"

class QueryHelper
  module QueryHelperConcern
    extend ActiveSupport::Concern

    included do
      def query_helper
        @query_helper
      end

      def create_query_helper
        @query_helper = QueryHelper.new(**query_helper_params, api_payload: true)
      end

      def create_query_helper_filter
        filter_values = params[:filter].permit!.to_h
        QueryHelper::SqlFilter.new(filter_values: filter_values)
      end

      def create_query_helper_sort
        QueryHelper::SqlSort.new(sort_string: params[:sort])
      end

      def create_query_helper_associations

      end

      def query_helper_params
        helpers = {}
        helpers[:page] = params[:page] if params[:page]
        helpers[:per_page] = params[:per_page] if params[:per_page]
        helpers[:sql_filter] = create_query_helper_filter() if params[:filter]
        helpers[:sql_sort] = create_query_helper_sort() if params[:sort]
        helpers[:associations] = create_query_helper_associations() if params[:include]
        helpers
      end
    end
  end
end
