# frozen_string_literal: true

require "spec_helper"

RSpec.describe QueryHelper::SqlSort do
  let(:column_maps) do
    [
      QueryHelper::ColumnMap.new(alias_name: "id", sql_expression: "parents.id"),
      QueryHelper::ColumnMap.new(alias_name: "age", sql_expression: "parents.age")
    ]
  end
  let(:column_sort_order) { { column_name: "age", sort_values: [3, 1, 2], direction: "desc" } }
  let(:sql_sort) { described_class.new(column_maps: column_maps, column_sort_order: column_sort_order) }

  describe "#parse_custom_sort_string" do
    it "builds a case statement for a known column" do
      expect(sql_sort.parse_sort_string).to eq(["(CASE WHEN parents.age=3 THEN 0 WHEN parents.age=1 THEN 1 WHEN parents.age=2 THEN 2 END) desc"])
    end

    it "accepts string keys" do
      sql_sort.column_sort_order = { "column_name" => "age", "sort_values" => [1], "direction" => "asc" }
      expect(sql_sort.parse_sort_string).to eq(["(CASE WHEN parents.age=1 THEN 0 END) asc"])
    end

    it "defaults to ascending when no direction is given" do
      column_sort_order.delete(:direction)
      expect(sql_sort.parse_sort_string).to eq(["(CASE WHEN parents.age=3 THEN 0 WHEN parents.age=1 THEN 1 WHEN parents.age=2 THEN 2 END) asc"])
    end

    it "quotes string sort values" do
      column_sort_order[:sort_values] = ["1) desc; drop table parents; --"]
      expect(sql_sort.parse_sort_string).to eq(["(CASE WHEN parents.age='1) desc; drop table parents; --' THEN 0 END) desc"])
    end

    it "rejects non-scalar sort values" do
      column_sort_order[:sort_values] = [{ "a" => "b" }]
      expect { sql_sort.parse_sort_string }.to raise_error(QueryHelper::InvalidQueryError)
    end

    it "rejects columns that are not in the column maps" do
      column_sort_order[:column_name] = "password"
      expect { sql_sort.parse_sort_string }.to raise_error(QueryHelper::InvalidQueryError)
    end

    it "rejects sql in the column name" do
      column_sort_order[:column_name] = "(select password from users limit 1)"
      expect { sql_sort.parse_sort_string }.to raise_error(QueryHelper::InvalidQueryError)
    end

    it "rejects sql in the direction" do
      column_sort_order[:direction] = "desc, (select 1)"
      expect { sql_sort.parse_sort_string }.to raise_error(QueryHelper::InvalidQueryError)
    end

    it "uses the mapped sql for custom mapped columns" do
      column_maps << QueryHelper::ColumnMap.new(alias_name: "rank", sql_expression: "parents.age")
      column_sort_order[:column_name] = "rank"
      expect(sql_sort.parse_sort_string.first).to start_with("(CASE WHEN parents.age=3 THEN 0")
    end

    it "accepts a mapped sql expression" do
      column_sort_order[:column_name] = "parents.age"
      expect(sql_sort.parse_sort_string.first).to start_with("(CASE WHEN parents.age=3 THEN 0")
    end

    it "rejects a column_sort_order that is not a hash" do
      sql_sort.column_sort_order = "age"
      expect { sql_sort.parse_sort_string }.to raise_error(QueryHelper::InvalidQueryError)
    end
  end
end
