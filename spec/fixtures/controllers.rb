require 'fixtures/application'
require 'fixtures/models'

class ApplicationController < ActionController::API
  include Rails.application.routes.url_helpers
  include QueryHelper::QueryHelperConcern
  before_action :create_query_helper
end

class ParentsController < ApplicationController
  def index
    @query_helper.query = Parent.all
    byebug
    render json: @query_helper.paginated_results()
  end

  def show
  end
end
