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
    render json: @query_helper.results()
  end

  def test
    test_query = ExampleQueries::SQL_QUERIES[params[:test_number].to_i]
    @query_helper.query = test_query[:query]
    @query_helper.model = test_query[:model]
    results = @query_helper.results()
    puts "EXECUTED QUERY: #{@query_helper.executed_query()}"
    render json: @query_helper.results()
  end
end
