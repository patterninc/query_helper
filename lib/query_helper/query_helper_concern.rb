require 'active_support/concern'
require "query_helper/sql_filter"

module QueryHelper
  module QueryHelperConcern
    extend ActiveSupport::Concern

    included do
      def query_helper
        @query_helper = QueryHelper.new(**query_helper_params)
      end

      def create_query_helper_filter

      end

      def create_query_helper_sort

      end

      def create_query_helper_associations

      end

      def query_helper_params
        helpers = {}
        helpers[:page] = params[:page] if params[:page]
        helpers[:per_page] = params[:per_page] if params[:per_page]
        helpers[:filters] = create_query_helper_filter() if params[:filter]
        helpers[:sorts] = create_query_helper_sort() if params[:sort]
        helpers[:associations] = create_query_helper_associations() if params[:include]
        helpers
      end
    end
  end
end
