require "spec_helper"

RSpec.describe PatternQueryHelper::Associations do

  describe "process_association_params" do
    it "parses association params" do
      associations = PatternQueryHelper::Associations.process_association_params(@url_params)
      expect(associations).to eq([:parent])
    end
  end

  describe "load_associations" do
    it "loads associations" do
      associations = PatternQueryHelper::Associations.process_association_params(@url_params)
      payload = Child.all
      results = PatternQueryHelper::Associations.load_associations(payload, associations)
      results.each do |child|
        expect(child["parent_id"]).to eq(child["parent"]["id"])
      end
    end
  end
end
