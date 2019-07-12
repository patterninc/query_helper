require "spec_helper"

RSpec.describe QueryHelper::Filter do
  let(:valid_operator_codes) {["gte", "lte", "gt", "lt", "eql", "noteql", "in", "notin", "null"]}

  describe ".sql_string" do
    let(:filter) do
      described_class.new(
        operator_code: "gte",
        criterion: Time.now,
        comparate: "children.age"
      )
    end

    it "creates sql string" do
      sql_string = filter.sql_string()
      expect(sql_string).to eq("#{filter.comparate} #{filter.operator} :#{filter.bind_variable}")
    end

    it "creates array correctly for in/not in"
    it "lowercases text correctly"
    it "creates sql_string correctly for null/not null comparisions"
  end

  describe ".translate_operator_code" do

    # TODO: fix - Fails because criterion fails depending on the operator
    # context "valid operator codes" do
    #   it "translates operator code correctly" do
    #     valid_operator_codes.each do |code|
    #       filter = described_class.new(
    #         operator_code: code,
    #         criterion: Faker::Number.between(0, 100),
    #         comparate: "children.age"
    #       )
    #       expect(filter.operator).to_not be_nil
    #     end
    #   end
    # end

    context "invalid operator code" do
      it "raises an ArugmentError" do
        expect{
          described_class.new(
            operator_code: "fake_code",
            criterion: Faker::Number.between(0, 100),
            comparate: "children.age"
          )
        }.to raise_error(InvalidQueryError)
      end
    end
  end

  describe ".validate_criterion" do
    RSpec.shared_examples "validates criterion" do
      it "validates criterion" do
        expect(filter.send(:validate_criterion)).to be true
      end
    end

    RSpec.shared_examples "invalidates criterion" do
      it "validates criterion" do
        expect{filter.send(:validate_criterion)}.to raise_error(InvalidQueryError)
      end
    end

    context "valid numeric criterion (gte, lte, gt, lt)" do
      include_examples "validates criterion"

      let(:filter) do
        described_class.new(
          operator_code: "gte",
          criterion: Faker::Number.between(0, 100),
          comparate: "children.age"
        )
      end
    end

    context "valid date criterion (gte, lte, gt, lt)" do
      include_examples "validates criterion"

      let(:filter) do
        described_class.new(
          operator_code: "gte",
          criterion: Date.today,
          comparate: "children.age"
        )
      end
    end

    context "valid time criterion (gte, lte, gt, lt)" do
      include_examples "validates criterion"

      let(:filter) do
        described_class.new(
          operator_code: "gte",
          criterion: Time.now,
          comparate: "children.age"
        )
      end
    end

    context "invalid criterion (gte, lte, gt, lt)" do
      include_examples "invalidates criterion"

      let(:filter) do
        described_class.new(
          operator_code: "gte",
          criterion: "hello",
          comparate: "children.age"
        )
      end
    end

    context "valid array criterion (in, notin)" do
      include_examples "validates criterion"

      let(:filter) do
        described_class.new(
          operator_code: "in",
          criterion: [1,2,3,4],
          comparate: "children.age"
        )
      end
    end

    context "invalid criterion (in, notin)" do
      include_examples "invalidates criterion"

      let(:filter) do
        described_class.new(
          operator_code: "in",
          criterion: Date.today,
          comparate: "children.age"
        )
      end
    end

    context "valid 'true' boolean criterion (null)" do
      include_examples "validates criterion"

      let(:filter) do
        described_class.new(
          operator_code: "null",
          criterion: true,
          comparate: "children.age"
        )
      end
    end

    context "valid 'false' boolean criterion (null)" do
      include_examples "validates criterion"

      let(:filter) do
        described_class.new(
          operator_code: "null",
          criterion: false,
          comparate: "children.age"
        )
      end
    end

    context "invalid boolean (null)" do
      include_examples "invalidates criterion"

      let(:filter) do
        described_class.new(
          operator_code: "null",
          criterion: "stringything",
          comparate: "children.age"
        )
      end
    end
  end
end
