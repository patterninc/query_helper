require "spec_helper"

RSpec.describe PatternQueryHelper::SqlQuery do
  let(:query) do
    %{
      select parents.id, parents.name, count(children.id) as children_count
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

  let(:filters) { {"age"=>{"lt"=>100}, "children_count"=>{"gt"=>0}} }

  let(:sorts) {"name:asc:lowercase,age:desc"}

  let(:includes) {"children"}

  let(:as_json_options) {{ methods: [:favorite_star_wars_character] }}

  it "returns a payload" do
    sql_query = described_class.new(
      model: Parent,
      query: query,
      sorts: sorts,
      column_mappings: column_mappings,
      filters: filters,
      associations: includes,
      as_json_options: as_json_options,
      page: 1,
      per_page: 5
    )
    results = sql_query.payload()
    expected_results = Parent.all.to_a.select{ |p| p.children.length > 1 && p.age < 100 }
    expect(results[:pagination][:count]).to eq(expected_results.length)
    expect(results[:pagination][:per_page]).to eq(5)
    expect(results[:pagination][:current_page]).to eq(1)
    expect(results[:data].length).to eq(5)
  end
end
