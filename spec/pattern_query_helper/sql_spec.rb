require "spec_helper"

RSpec.describe PatternQueryHelper::Sql do

  describe "sql_query" do
    it "query returns the same number of results as designated by per_page" do
      per_page = Faker::Number.between(2,10)
      results = PatternQueryHelper::Sql.sql_query(
        model: Child,
        query: "select * from children c join parents p on p.id = c.parent_id",
        page: Faker::Number.between(1,10),
        per_page: per_page
      )

      expect(results.length).to eq(per_page)
    end

    it "query sorts correctly" do
      sort_string = PatternQueryHelper::Sorting.parse_sorting_params("id:desc", ["id"])
      results = PatternQueryHelper::Sql.sql_query(
        model: Child,
        query: "select * from children c join parents p on p.id = c.parent_id",
        page: 1,
        per_page: 500,
        sort_string: sort_string
      )
      previous_id = 1000000000
      results.each do |result|
        expect(result.id).to be < previous_id
        previous_id = result.id
      end
    end

    it "query filters correctly" do
      filters = PatternQueryHelper::Filtering.create_filters({
        "id" => {
          "gte" => 20,
          "lt" => 40
        }
      })
      results = PatternQueryHelper::Sql.sql_query(
        model: Child,
        query: "select * from children c join parents p on p.id = c.parent_id",
        page: 1,
        per_page: 500,
        filter_string: filters[:filter_string],
        filter_params: filters[:filter_params]
      )
      results.each do |result|
        expect(result.id).to be >= 20
        expect(result.id).to be < 40
      end
    end

    it "query returns all results if no pagination info" do
      results = PatternQueryHelper::Sql.sql_query(
        model: Child,
        query: "select * from children c join parents p on p.id = c.parent_id",
      )
      expect(results.length).to eq(Child.all.length)
    end
  end

  describe "sql_query_count" do
    it "should count the number of rows correctly" do
      results = PatternQueryHelper::Sql.sql_query(
        model: Child,
        query: "select * from children c join parents p on p.id = c.parent_id",
        page: 1
      )
      count = PatternQueryHelper::Sql.sql_query_count(results)
      expect(count).to eq(Child.all.length)
    end

    it "should support common table expressions" do
      result = ActiveRecord::Base.connection.select_value('with testing_cte as (select 1 as example_col) SELECT * from testing_cte')
      expect(result).to eq(1)
    end

    it "should count the number of rows correctly with filters in place" do
      filters = PatternQueryHelper::Filtering.create_filters({
        "id" => {
          "gte" => 20,
          "lt" => 40
        }
      })
      results = PatternQueryHelper::Sql.sql_query(
        model: Child,
        query: "select * from children c join parents p on p.id = c.parent_id",
        filter_string: filters[:filter_string],
        filter_params: filters[:filter_params],
        page: 1,
      )
      count = PatternQueryHelper::Sql.sql_query_count(results)
      expect(count).to eq(Child.all.where("id >= 20 and id < 40").length)
    end
  end

  describe "single_record_query" do
    it "returns one result" do
      result = PatternQueryHelper::Sql.single_record_query(
        model: Child,
        query: "select * from children c join parents p on p.id = c.parent_id where c.id = 1",
      )
      expect(result.class).to eq(Child)
    end
  end
end
