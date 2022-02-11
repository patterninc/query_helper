require 'active_support/concern'

class QueryHelper
  module QueryHelperConcern
    extend ActiveSupport::Concern

    included do
      def query_helper
        @query_helper
      end

      def query_helper_with_no_pagination
        QueryHelper.new(**query_helper_params_no_pagination)
      end

      def create_query_helper
        @query_helper = QueryHelper.new(**query_helper_params, api_payload: true)
      end

      def create_query_helper_with_no_pagination
        @query_helper = query_helper_with_no_pagination()
      end

      def reload_query_params(query_helper=@query_helper)
        query_helper.update(**query_helper_params)
      end 

      def create_query_helper_filter
        filter_values = params[:filter].permit!.to_h
        QueryHelper::SqlFilter.new(filter_values: filter_values)
      end

      def create_query_helper_sort
        QueryHelper::SqlSort.new(sort_string: params[:sort], sort_tiebreak: params[:sort_tiebreak], column_sort_order: params[:column_sort_order])
      end

      def create_query_helper_associations
        QueryHelper::Associations.process_association_params(params[:include])
      end

      def query_helper_params
        helpers = query_helper_params_no_pagination
        helpers[:page] = params[:page] if params[:page]
        helpers[:per_page] = params[:per_page] if params[:per_page]
        helpers
      end

      def query_helper_params_no_pagination
        helpers = {}
        helpers[:sql_filter] = create_query_helper_filter() if params[:filter]
        helpers[:sql_sort] = create_query_helper_sort() if params[:sort] || params[:sort_tiebreak]
        helpers[:associations] = create_query_helper_associations() if params[:include]
        helpers[:search_string] = params[:search_for] if params[:search_for]
        helpers
      end
    end
  end
end
