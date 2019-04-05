require "spec_helper"

RSpec.describe PatternQueryHelper::Associations do

  describe "process_association_params" do
    it "parses association params" do
      associations = PatternQueryHelper::Associations.process_association_params("parent")
      expect(associations).to eq([:parent])
    end
  end

  describe "load_associations" do
    it "loads associations" do
      associations = PatternQueryHelper::Associations.process_association_params("parent")
      payload = Child.all
      results = PatternQueryHelper::Associations.load_associations(payload, associations, nil)
      results.each do |child|
        expect(child["parent_id"]).to eq(child["parent"]["id"])
      end
    end
  end

  describe 'json_associations' do
    subject { described_class.json_associations(associations) }

    context 'nested associations' do
      let(:associations) do
        [:parent,
         children: [:grand_children],
         pets: :grand_pets,
         messages: { author: [:avatar, :profile] }]
      end

      it 'translates to as_json format' do
        expect(subject).to eq([:parent, children: { include: [:grand_children] },
                                        pets: { include: [:grand_pets] },
                                        messages: { include: [ author: { include: [:avatar, :profile] }]}])
      end
    end
  end
end
