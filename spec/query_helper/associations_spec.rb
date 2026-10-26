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
