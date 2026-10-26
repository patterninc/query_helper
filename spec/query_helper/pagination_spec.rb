# frozen_string_literal: true

require "spec_helper"

RSpec.describe QueryHelper do
  describe "pagination params" do
    it "rejects a page below 1" do
      expect { described_class.new(model: Parent, query: "select * from parents", page: "0", per_page: "10") }
        .to raise_error(QueryHelper::InvalidQueryError)
      expect { described_class.new(model: Parent, query: "select * from parents", page: "-1", per_page: "10") }
        .to raise_error(QueryHelper::InvalidQueryError)
    end

    it "rejects a negative per_page" do
      expect { described_class.new(model: Parent, query: "select * from parents", page: "1", per_page: "-5") }
        .to raise_error(QueryHelper::InvalidQueryError)
    end

    it "rejects a bad page on update" do
      query_helper = described_class.new(model: Parent, query: "select * from parents")
      expect { query_helper.update(page: "-2") }.to raise_error(QueryHelper::InvalidQueryError)
    end
  end
end

RSpec.describe QueryHelper do
  describe "max_per_page" do
    let(:query) { "select * from parents" }

    it "clamps per_page to the class default" do
      expect(described_class.new(model: Parent, query: query, page: "1", per_page: "100000").per_page).to eq(1000)
    end

    it "clamps per_page to an instance limit" do
      expect(described_class.new(model: Parent, query: query, page: "1", per_page: "50", max_per_page: 20).per_page).to eq(20)
    end

    it "applies a limit passed to update" do
      query_helper = described_class.new(model: Parent, query: query, page: "1", per_page: "500")
      expect(query_helper.update(max_per_page: 50).per_page).to eq(50)
      expect(query_helper.bind_variables[:limit]).to eq(50)
    end

    it "can be disabled" do
      expect(described_class.new(model: Parent, query: query, page: "1", per_page: "5000", max_per_page: nil).per_page).to eq(5000)
    end

    it "leaves smaller values alone" do
      expect(described_class.new(model: Parent, query: query, page: "1", per_page: "25").per_page).to eq(25)
    end
  end
end
