class ApplicationController < ActionController::API
  include QueryHelperConcern
  before_action :query_helper
end
