require "pattern_query_helper/version"
require "pattern_query_helper/filter"
require "pattern_query_helper/column_map"
require "pattern_query_helper/query_string"
require "pattern_query_helper/sql"
require "pattern_query_helper/active_record"
require "pattern_query_helper/query_filter"
require "pattern_query_helper/sort"
require "pattern_query_helper/associations"
require "pattern_query_helper/query_helper_concern"

module PatternQueryHelper

  class << self
    attr_accessor :active_record_adapter
  end
end
