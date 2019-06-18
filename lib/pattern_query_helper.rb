require "pattern_query_helper/version"
require "pattern_query_helper/filter"
require "pattern_query_helper/column_map"
require "pattern_query_helper/query_string"
require "pattern_query_helper/sql_query"
require "pattern_query_helper/query_filter"
require "pattern_query_helper/sort"
require "pattern_query_helper/associations"

module PatternQueryHelper

  class << self
    attr_accessor :active_record_adapter
  end
end
