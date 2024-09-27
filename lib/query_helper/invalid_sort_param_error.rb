class QueryHelper
  class InvalidSortParamError < StandardError

    attr_reader :sort_string

    def initialize(msg='Invalid sort param', sort_string='')
      @sort_string = sort_string
      super(msg)
    end
    
    def as_json
      {
        'error' => message,
        'sort_param' => sort_string
      }
    end
  end
end
