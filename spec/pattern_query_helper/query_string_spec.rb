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

  describe ".add_where_filters" do
    let(:where_filters) {["a = a", "b = b", "c = c"]}
    context "simple query" do
      it "correctly sets indexes" do
        simple_query.add_where_filters(where_filters)
        expected_result = simple_query.modified_query_string.include?("where #{where_filters.join(" and ")}")
        expect(expected_result).to be true
      end
    end
    context "complex query" do
      it "correctly sets indexes" do
        complex_query.add_where_filters(where_filters)
        expected_result = complex_query.modified_query_string.include?("where string = string and #{where_filters.join(" and ")}")
        expect(expected_result).to be true
      end
    end
  end

  describe ".add_sorting" do
    let(:sorts) {["a desc", "b asc"]}
    context "simple query" do
      it "correctly adds custom sorting" do
        simple_query.add_sorting(sorts)
        expected_result = simple_query.modified_query_string.include?("order by #{sorts.join(", ")}")
        expect(expected_result).to be true
      end
    end
    context "complex query" do
      it "correctly adds custom sorting" do
        complex_query.add_sorting(sorts)
        expected_result = complex_query.modified_query_string.include?("order by #{sorts.join(", ")}")
        expect(expected_result).to be true
      end
    end
  end

  describe ".add_having_filters" do
    let(:having_filters) {["count(a) > 0", "sum(b) < 100"]}
    context "simple query" do
      it "raises error when no group by clause" do
        expect{simple_query.add_having_filters(having_filters)}.to raise_error(ArgumentError)
      end
    end
    context "simple group by query" do
      it "correctly sets additional having filters" do
        simple_group_by_query.add_having_filters(having_filters)
        expected_result = simple_group_by_query.modified_query_string.include?("having #{having_filters.join(" and ")}")
        expect(expected_result).to be true
      end
    end
    context "complex query" do
      it "correctly sets additional having filters" do
        complex_query.add_having_filters(having_filters)
        expected_result = complex_query.modified_query_string.include?("having sum(e) > 1 and #{having_filters.join(" and ")}")
        expect(expected_result).to be true
      end
    end
  end

  describe ".add_pagination" do
    it "adds correct pagination to query" do
      complex_query.add_pagination(2,3)
      expected_result = complex_query.modified_query_string.include?("limit 3 offset 3")
      expect(expected_result).to be true
    end
  end
end
