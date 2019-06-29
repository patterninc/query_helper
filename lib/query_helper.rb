require "active_record"

require "query_helper/version"
require "query_helper/filter"
require "query_helper/column_map"
require "query_helper/query_string"
require "query_helper/sql"
require "query_helper/active_record_query"
require "query_helper/query_filter"
require "query_helper/sort"
require "query_helper/associations"
require "query_helper/query_helper_concern"
require "query_helper/sql_parser"
require "query_helper/sql_manipulator"

module QueryHelper

  class << self
    attr_accessor :active_record_adapter
  end
end
