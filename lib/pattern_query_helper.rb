require "pattern_query_helper/version"
require "pattern_query_helper/pagination"
require "pattern_query_helper/filtering"
require "pattern_query_helper/associations"
require "pattern_query_helper/sorting"
require "pattern_query_helper/sql"

module PatternQueryHelper
  # Your code goes here...

  class << self
    attr_accessor :active_record_adapter
  end
end
