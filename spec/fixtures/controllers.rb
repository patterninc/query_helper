class ApplicationController < ActionController::API
  include Rails.application.routes.url_helpers
  include QueryHelper::QueryHelperConcern
  before_action :query_helper
end

class ParentsController < ApplicationController
  def index
    byebug
  end

  def show
    byebug
  end
end
