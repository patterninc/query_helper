# frozen_string_literal: true

require "spec_helper"

RSpec.describe QueryHelper::Filter do
  def build_filter(operator_code, criterion)
    described_class.new(operator_code: operator_code, criterion: criterion, comparate: "parents.age")
  end

  it "accepts scalar criteria" do
    expect(build_filter("eql", "20").sql_string).to match(/\Aparents.age = :[a-z]+\z/)
  end

  it "accepts a list of scalars for in" do
    filter = build_filter("in", ["1", "2"])
    expect(filter.sql_string).to match(/\Aparents.age in \(:[a-z]+\)\z/)
  end

  it "rejects hash criteria" do
    expect { build_filter("eql", { "a" => "b" }) }.to raise_error(QueryHelper::InvalidQueryError)
  end

  it "rejects array criteria for scalar operators" do
    expect { build_filter("eql", ["1", "2"]) }.to raise_error(QueryHelper::InvalidQueryError)
  end

  it "rejects nested values in an in list" do
    expect { build_filter("in", [["1"], { "a" => "b" }]) }.to raise_error(QueryHelper::InvalidQueryError)
  end
end

RSpec.describe QueryHelper::SqlFilter do
  let(:column_maps) { [QueryHelper::ColumnMap.new(alias_name: "age", sql_expression: "parents.age")] }

  it "rejects filter values that are not operator/criterion pairs" do
    sql_filter = described_class.new(filter_values: { "age" => "20" }, column_maps: column_maps)
    expect { sql_filter.create_filters }.to raise_error(QueryHelper::InvalidQueryError)
  end
end

RSpec.describe QueryHelper do
  describe "pagination params" do
    it "rejects a page below 1" do
      expect { described_class.new(model: Parent, query: "select * from parents", page: "0", per_page: "10") }
        .to raise_error(QueryHelper::InvalidQueryError)
      expect { described_class.new(model: Parent, query: "select * from parents", page: "-1", per_page: "10") }
        .to raise_error(QueryHelper::InvalidQueryError)
    end

    it "rejects a negative per_page" do
      expect { described_class.new(model: Parent, query: "select * from parents", page: "1", per_page: "-5") }
        .to raise_error(QueryHelper::InvalidQueryError)
    end

    it "rejects a bad page on update" do
      query_helper = described_class.new(model: Parent, query: "select * from parents")
      expect { query_helper.update(page: "-2") }.to raise_error(QueryHelper::InvalidQueryError)
    end
  end
end
