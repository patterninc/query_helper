# frozen_string_literal: true

require "spec_helper"

RSpec.describe QueryHelper::ColumnMap do
  describe ".create_column_mappings" do
    around do |example|
      Parent.filter_attributes = [:age]
      example.run
    ensure
      Parent.remove_instance_variable(:@filter_attributes)
    end

    def alias_names(query)
      described_class.create_column_mappings(query: query, custom_mappings: {}, model: Parent).map(&:alias_name)
    end

    it "leaves out model attributes that match filter_attributes" do
      expect(alias_names("select * from parents")).to contain_exactly("id", "name")
    end

    it "keeps sensitive attributes the query selects explicitly" do
      expect(alias_names("select parents.age as age from parents")).to include("age")
    end

    it "keeps sensitive attributes that are custom mapped" do
      maps = described_class.create_column_mappings(query: "select * from parents", custom_mappings: { "age" => "parents.age" }, model: Parent)
      expect(maps.map(&:alias_name)).to include("age")
    end

    it "rejects filtering on a hidden attribute" do
      query_helper = QueryHelper.new(
        model: Parent,
        query: "select * from parents",
        sql_filter: QueryHelper::SqlFilter.new(filter_values: { "age" => { "gte" => "20" } })
      )
      expect { query_helper.build_query }.to raise_error(QueryHelper::InvalidQueryError)
    end
  end
end
