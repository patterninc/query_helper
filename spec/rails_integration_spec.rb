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

        q[:expected_filters].each do |filter|
          filter[:operator_codes].each do |oc|
            filter_value = if filter[:class] == Integer
              Faker::Number.between(0,100).to_s
            elsif filter[:class] == String
              case oc
              when "in", "notin"
                "#{q[:model].all.pluck(:name).sample},#{q[:model].all.pluck(:name).sample},#{q[:model].all.pluck(:name).sample}"
              when "like"
                q[:model].all.pluck(:name).sample[0..4]
              end
            elsif filter[:class] == TrueClass
              case oc
              when "null"
                ['true', 'false'].sample
              end
            end
            filter_url_param = {
              filter[:alias] => {
                oc => filter_value
              }
            }

            url_params = {
              page: Faker::Number.between(5,15).to_s,
              per_page: Faker::Number.between(2,5).to_s,
              filter: filter_url_param,
              test_number: index
            }

            puts "INDEX: #{index} --- QUERY: #{q[:query].squish} --- filter: #{filter_url_param}"

            get :test, params: url_params

            # TODO: Add some sort of expectation
            # Perhaps expect the result to be filtered (have less values than previously)

          end
        end if q[:expected_filters]

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
