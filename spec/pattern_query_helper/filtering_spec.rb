require "spec_helper"

RSpec.describe PatternQueryHelper::Filtering do

  describe "parse_pagination_params" do
    it "create filters" do
      filters = PatternQueryHelper::Filtering.create_filters({
        "id" => {
          "gte" => 20,
          "lt" => 40,
          "in" => "20,25,30",
          "null" => false
        },
        "name" => {
          "like" => "my_name%"
        }
      }, {"id" => "id", "name" => "name"})
      expect(filters[:filter_string]).to eq("1 = 1 and id >= :id_gte and id < :id_lt and id in (:id_in) and id is not null and lower(name) like :name_like")
      expect(filters[:filter_params]).to eq({"id_gte"=>20, "id_in"=>["20","25","30"], "id_lt"=>40, "name_like"=>"my_name%"})
      expect(filters[:filter_array]).to eq([
        {:column=>"id", :operator=>">=", :value=>20, :symbol=>"id_gte"},
        {:column=>"id", :operator=>"<", :value=>40, :symbol=>"id_lt"},
        {:column=>"id", :operator=>"in (:id_in)", :value=>["20","25","30"], :symbol=>"id_in"},
        {:column=>"id", :operator=>"is not null", :value=>false, :symbol=>""},
        {:column=>"name", :operator=>"like", :value=>"my_name%", :symbol=>"name_like"},
      ])
    end
  end
end
