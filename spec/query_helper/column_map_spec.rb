require "spec_helper"

RSpec.describe QueryHelper::ColumnMap do
  let(:valid_operator_codes) {["gte", "lte", "gt", "lt", "eql", "noteql", "in", "notin", "null"]}

  describe ".create_from_hash" do
    let(:hash) do
      {
        "column1" => "table.column1",
        "column2" => "table.column2",
        "column3" => {sql_expression: "sum(table.column3)", aggregate: true},
        "column4" => {sql_expression: "sum(table.column4)", aggregate: true},
      }
    end

    it "creates an array of column maps" do
      map = described_class.create_from_hash(hash)
      expect(map.length).to eq(hash.keys.length)
      expect(map.first.alias_name).to eq(hash.keys.first)
      expect(map.first.sql_expression).to eq(hash.values.first)
      expect(map.last.alias_name).to eq(hash.keys.last)
      expect(map.last.sql_expression).to eq(hash.values.last[:sql_expression])
      expect(map.last.aggregate).to be true
    end
  end
end
