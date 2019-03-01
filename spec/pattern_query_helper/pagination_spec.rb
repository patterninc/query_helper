require "spec_helper"

RSpec.describe PatternQueryHelper::Pagination do
  before(:each) do
    @per_page = Faker::Number.between(5,15)
    @page = Faker::Number.between(2,5)
  end

  describe "parse_pagination_params" do

    it "creates pagination params from url params" do
      pagination_params = PatternQueryHelper::Pagination.parse_pagination_params(@page, @per_page)
      expect(pagination_params[:per_page]).to eq(@per_page)
      expect(pagination_params[:page]).to eq(@page)
    end

    it "fails if page <= 0" do
      expect { PatternQueryHelper::Pagination.parse_pagination_params(0, @per_page) }.to raise_error(RangeError)
    end

    it "fails if per_page <= 0" do
      expect { PatternQueryHelper::Pagination.parse_pagination_params(@page, 0) }.to raise_error(RangeError)
    end

    it "default per page is 20" do
      pagination_params = PatternQueryHelper::Pagination.parse_pagination_params(@page, nil)
      expect(pagination_params[:per_page]).to eq(20)
    end

    it "default page is 1" do
      pagination_params = PatternQueryHelper::Pagination.parse_pagination_params(nil, @per_page)
      expect(pagination_params[:page]).to eq(1)
    end

  end

  describe "create_pagination_payload" do

    before(:each) do
      @pagination_params = PatternQueryHelper::Pagination.parse_pagination_params(@page, @per_page)
      @count = Faker::Number.between(100, 500)
      @pagination_payload = PatternQueryHelper::Pagination.create_pagination_payload(@count, @pagination_params)
      expect(@pagination_payload[:previous_page]).to eq(@page - 1)
      expect(@pagination_payload[:next_page]).to eq(@page + 1)
    end

    it "calculate total_pages correctly" do
      expect(@pagination_payload[:total_pages]).to eq((@count/@per_page.to_f).ceil)
    end

    it "next_page is null if on last page" do
      @pagination_params[:page] = @pagination_payload[:total_pages]
      @pagination_payload = PatternQueryHelper::Pagination.create_pagination_payload(@count, @pagination_params)
      expect(@pagination_payload[:next_page]).to eq(nil)
      expect(@pagination_payload[:last_page]).to eq(true)
    end

    it "previous_page is null if on first page" do
      @pagination_params[:page] = 1
      @pagination_payload = PatternQueryHelper::Pagination.create_pagination_payload(@count, @pagination_params)
      expect(@pagination_payload[:previous_page]).to eq(nil)
      expect(@pagination_payload[:first_page]).to eq(true)
    end

    it "out_of_range determined correctly" do
      @pagination_params[:page] = @pagination_payload[:total_pages] + 1
      @pagination_payload = PatternQueryHelper::Pagination.create_pagination_payload(@count, @pagination_params)
      expect(@pagination_payload[:out_of_range]).to eq(true)
    end

  end

  describe "paginate_active_record_query" do

    before(:each) do
      @pagination_params = PatternQueryHelper::Pagination.parse_pagination_params(@page, @per_page)
      @results = PatternQueryHelper::Pagination.paginate_active_record_query(Parent.all, @pagination_params)
    end

    it "return the correct number of records per page" do
      expect(@results.length).to eq(@per_page)
    end

  end

end
