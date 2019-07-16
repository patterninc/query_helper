require 'fixtures/application'
require 'fixtures/controllers'
require 'fixtures/models'
require 'fixtures/example_queries'
require 'rspec/rails'

 RSpec.describe ParentsController, type: :controller do
  describe '#index' do
    # url_params = {
    #   filter: {
    #     "id" => {
    #       "gte" => 20,
    #       "lt" => 40
    #     }
    #   },
    #   page: Faker::Number.between(5,15).to_s,
    #   per_page: Faker::Number.between(2,5).to_s,
    #   sort: "name:desc",
    #   include: "parent"
    # }
    #
    # it "text" do
    #   get :index, params: url_params
    #   byebug
    # end

    it "test example queries" do
      ExampleQueries::SQL_QUERIES.each_with_index do |q, index|

        q[:expected_sorts].each do |sort|
          sort_direction = ["asc","desc"].sample

          url_params = {
            page: Faker::Number.between(5,15).to_s,
            per_page: Faker::Number.between(2,5).to_s,
            sort: "#{sort}:#{sort_direction}",
            test_number: index
          }

          puts "INDEX: #{index} --- QUERY: #{q[:query].squish} --- SORT: #{sort}"

          get :test, params: url_params

          rsp = JSON.parse(response.body)
          data = rsp["data"]
          pagination = rsp["pagination"]

          previous_value = nil
          data.each_with_index do |d, index|
            if index > 0
              if sort_direction == "desc"
                expect(d[sort] <= previous_value).to eql(true)
              else
                expect(d[sort] >= previous_value).to eql(true)
              end
            end
            previous_value = d[sort]
          end

        end

        # q[:expected_filters].each do |filter|
        #   # filter = {
        #   #     "id" => {
        #   #       "gte" => 20,
        #   #       "lt" => 40
        #   #     }
        #   #   },
        #   filter[:operator_codes].each do |oc|
        #     filter_value = case filter[:class]
        #     when Integer
        #       Faker::Number.between(0,100).to_s
        #     when String
        #       case oc
        #       when "in", "notin"
        #
        #       end
        #     end
        #     filter = {
        #       filter[:alias] => {
        #         oc => filter_value
        #       }
        #     }
        #   end
        #   url_params = {
        #     page: Faker::Number.between(5,15).to_s,
        #     per_page: Faker::Number.between(2,5).to_s,
        #     sort: "#{sort}:#{sort_direction}",
        #     test_number: index
        #   }
        #
        #   puts "INDEX: #{index} --- QUERY: #{q[:query].squish} --- filter: #{filter}"
        # end if q[:expected_filters]

      end
    end
  end
end

# RSpec.describe 'Requests', type: :request do
#   it "text" do
#     get '/parents'
#     byebug
#   end
# end
