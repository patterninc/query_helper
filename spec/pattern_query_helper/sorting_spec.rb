require "spec_helper"

RSpec.describe PatternQueryHelper::Sorting do

  describe "parse_sorting_params" do
    it "parses params into sorting sql string" do
      sort_string = PatternQueryHelper::Sorting.parse_sorting_params("name:desc", ["name"])
      expect(sort_string).to eq("name desc")
    end

    it "lowercase if asked for" do
      sort_string = PatternQueryHelper::Sorting.parse_sorting_params("name:desc:lowercase", ["name"])
      expect(sort_string).to eq("lower(name) desc")
    end
  end
end
