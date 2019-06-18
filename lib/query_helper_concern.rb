require 'rails'
require 'active_support/dependencies'
require 'active_support/concern'

module QueryHelperConcern
  extend ActiveSupport::Concern

  included do
    def query_helper_params
      {
        filters: params[:filter],
        sorts: params[:sort],
        page: params[:page],
        per_page: params[:per_page],
        associations: params[:include]
      }
    end
  end
end
