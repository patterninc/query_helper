# frozen_string_literal: true

require "spec_helper"

RSpec.describe QueryHelper::Associations do
  describe ".validate_associations!" do
    let(:allowed) { [:parent, { children: [:toys, { friends: :parent }] }] }

    it "allows listed associations" do
      expect(described_class.validate_associations!([:parent, "children"], allowed)).to eq([:parent, "children"])
    end

    it "allows listed nested associations" do
      requested = { "children" => ["toys", { "friends" => "parent" }] }
      expect { described_class.validate_associations!(requested, allowed) }.not_to raise_error
    end

    it "rejects associations that are not listed" do
      expect { described_class.validate_associations!([:api_tokens], allowed) }
        .to raise_error(QueryHelper::InvalidQueryError, "Including 'api_tokens' is not allowed")
    end

    it "rejects nested associations that are not listed" do
      expect { described_class.validate_associations!({ children: [:secrets] }, allowed) }
        .to raise_error(QueryHelper::InvalidQueryError, "Including 'children.secrets' is not allowed")
    end
  end
end

RSpec.describe QueryHelper::Associations do
  describe ".load_associations" do
    around do |example|
      Child.filter_attributes = [:age]
      Parent.filter_attributes = [:name]
      example.run
    ensure
      Child.remove_instance_variable(:@filter_attributes)
      Parent.remove_instance_variable(:@filter_attributes)
    end

    let(:parents) { Parent.limit(2).to_a }

    it "removes sensitive attributes from included records at every level" do
      json = described_class.load_associations(payload: parents, associations: [{ children: [:parent] }])
      child = json.first["children"].first
      expect(child).not_to have_key("age")
      expect(child["parent"]).to include("id", "age")
      expect(child["parent"]).not_to have_key("name")
    end

    it "leaves the top level records alone" do
      json = described_class.load_associations(payload: parents, associations: [:children])
      expect(json.first).to have_key("name")
    end

    it "keeps attributes when the caller passes its own as_json include" do
      as_json_options = { include: [:children] }
      json = described_class.load_associations(payload: parents, associations: [:children], as_json_options: as_json_options)
      expect(json.first["children"].first).to have_key("age")
    end

    it "doesn't modify the caller's as_json options" do
      as_json_options = { only: [:id] }
      described_class.load_associations(payload: parents, associations: [:children], as_json_options: as_json_options)
      expect(as_json_options).to eq({ only: [:id] })
    end
  end
end
