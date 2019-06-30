require 'active_support/concern'
require "query_helper/sql_filter"

module QueryHelper
  module QueryHelperConcern
    extend ActiveSupport::Concern

    included do
      def sql_filter
        SqlFilter.new(filter_values: filters, column_maps: @column_maps)
      end

      def sql_sort

      end
      def query_helper_params
        helpers = {}
        helpers[:filters] = params[:filter] if params[:filter]
        helpers[:sorts] = params[:sort] if params[:sort]
        helpers[:page] = params[:page] if params[:page]
        helpers[:per_page] = params[:per_page] if params[:per_page]
        helpers[:associations] = params[:include] if params[:include]
        helpers
      end
    end
  end
end
