RSpec.describe PatternQueryHelper do
  it "has a version number" do
    expect(PatternQueryHelper::VERSION).not_to be nil
  end

  it "sets up the test database correctly" do
    expect(Parent.all.count).to eq(100)
    # Every parent has between 2 and 6 children
    expect(Child.all.count).to be_between(200, 600).inclusive
  end
end
