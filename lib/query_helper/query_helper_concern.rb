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
        # Here we get dynamic filter variable and hence we can't define permit.
        filter_values = params[:filter].to_unsafe_h
        QueryHelper::SqlFilter.new(filter_values: filter_values)
      end

      def create_query_helper_sort
        QueryHelper::SqlSort.new(sort_string: params[:sort], sort_tiebreak: params[:sort_tiebreak], column_sort_order: params[:column_sort_order])
      end

      # Define query_helper_allowed_includes in a controller to list which associations
      # the include param can load, e.g. [:parent, { children: [:toys] }]
      def create_query_helper_associations
        associations = QueryHelper::Associations.process_association_params(params[:include])
        if respond_to?(:query_helper_allowed_includes, true)
          QueryHelper::Associations.validate_associations!(associations, query_helper_allowed_includes)
        elsif QueryHelper.allow_unlisted_includes
          associations
        else
          raise QueryHelper::InvalidQueryError.new("Including associations is not allowed. Define query_helper_allowed_includes in #{self.class.name}")
        end
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
        helpers[:sql_sort] = create_query_helper_sort() if params[:sort] || params[:sort_tiebreak] || params[:custom_sort]
        helpers[:associations] = create_query_helper_associations() if params[:include]
        helpers[:search_string] = params[:search_for] if params[:search_for]
        helpers
      end
    end
  end
end
