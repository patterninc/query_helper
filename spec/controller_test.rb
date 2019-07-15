require 'fixtures/application'
require 'fixtures/controllers'
# require 'fixtures/routes'
require 'rspec/rails'

 RSpec.describe ParentsController, type: :controller do
  describe '#index' do
    it "text" do
      get :index
      byebug
      # ...
    end

  end
end

# RSpec.describe 'Requests', type: :request do
#   it "text" do
#     get '/parents'
#     byebug
#   end
# end
