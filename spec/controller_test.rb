require 'fixtures/application'
require 'fixtures/controllers'
require 'fixtures/models'
require 'rspec/rails'

 RSpec.describe ParentsController, type: :controller do
  describe '#index' do
    url_params = {
      filter: {
        "id" => {
          "gte" => 20,
          "lt" => 40
        }
      },
      page: Faker::Number.between(5,15).to_s,
      per_page: Faker::Number.between(2,5).to_s,
      sort: "name:desc",
      include: "parent"
    }

    it "text" do
      get :index, params: url_params
      byebug
    end
  end
end

# RSpec.describe 'Requests', type: :request do
#   it "text" do
#     get '/parents'
#     byebug
#   end
# end
