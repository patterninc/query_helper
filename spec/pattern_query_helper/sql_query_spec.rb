require "spec_helper"

RSpec.describe PatternQueryHelper::SqlQuery do
  let(:query) do
    %{
      select parents.name, count(children.id) as children_count
      from parents
      join children on parents.id = children.parent_id
      group by parents.id
    }
  end

  let(:column_mappings) do
    {
      "children_count" => {sql_expression: "count(children.id)", aggregate: true},
      "name" => "parents.name",
      "age" => "parents.age"
    }
  end

  let(:filters) do
    {"age"=>{"lt"=>100}, "children_count"=>{"gt"=>0}}
  end

  it "first test" do
    sql_query = described_class.new(
      model: Parent,
      query: query,
      column_mappings: column_mappings,
      filters: filters,
      page: 1,
      per_page: 5
    )
    results = sql_query.execute_query
    expected_results = Parent.all.to_a.select{ |p| p.children.length > 1 && p.age < 100 }
  end
end
