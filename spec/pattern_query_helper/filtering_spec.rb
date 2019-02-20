require "spec_helper"

RSpec.describe PatternQueryHelper::Filtering do

  describe "parse_pagination_params" do
    it "create filters" do
      filters = PatternQueryHelper::Filtering.parse_pagination_params(@url_params)
      filters = PatternQueryHelper::Filtering.create_filters(filters)
      expect(filters[:filter_string]).to eq("true = true and id >= :id_gte and id < :id_lt")
      expect(filters[:filter_params]).to eq({"id_gte"=>20, "id_lt"=>40})
      expect(filters[:filter_array]).to eq([{:column=>"id", :operator=>">=", :value=>20, :symbol=>"id_gte"}, {:column=>"id", :operator=>"<", :value=>40, :symbol=>"id_lt"}])
    end
  end
end
