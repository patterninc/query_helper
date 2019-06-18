require 'rails'
require 'active_support/dependencies'
require 'active_support/concern'

module PatternQueryHelper
  module QueryHelperConcern
    extend ActiveSupport::Concern

    included do
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
