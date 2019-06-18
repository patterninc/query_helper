require "spec_helper"

RSpec.describe PatternQueryHelper::QueryString do
  let(:complex_query) do
    query = %{
      with cte as (
        select * from table1
      ), cte1 as (
        select column1, column2 from table2
      )
      select a, b, c, d, sum(e)
      from table1
      join cte on cte.a = table1.a
      where string = string
      group by a,b,c,d
      having sum(e) > 1
      order by random_column
    }
    described_class.new(query)
  end

  let(:simple_query) do
    query = "select a from b"
    described_class.new(query)
  end

  let(:simple_group_by_query) do
    query = "select sum(a) from b group by c"
    described_class.new(query)
  end

  it "pending tests"
end
