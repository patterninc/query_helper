module QueryHelper
  class ActiveRecordQuery < Sql

    def initialize(
      active_record_call:, # the active_record_query to be executed
      query_params: {}, # a list of bind variables to be embedded into the query
      column_mappings: {}, # A hash that translates aliases to sql expressions
      filters: {}, # a list of filters in the form of {"comparate_alias"=>{"operator_code"=>"value"}}.  i.e. {"age"=>{"lt"=>100}, "children_count"=>{"gt"=>0}}
      sorts: "", # a comma separated string with a list of sort values i.e "age:desc,name:asc:lowercase"
      page: nil, # define the page you want returned
      per_page: nil, # define how many results you want per page
      single_record: false, # whether or not you expect the record to return a single result, if toggled, only the first result will be returned
      associations: [], # a list of activerecord associations you'd like included in the payload
      as_json_options: {}, # a list of as_json options you'd like run before returning the payload
      run: true # whether or not you'd like to run the query on initilization
    )

      super(
        model: active_record_call.model,
        query:  active_record_call.to_sql,
        query_params: query_params,
        column_mappings: column_mappings,
        filters: filters,
        sorts: sorts,
        page: page,
        per_page: per_page,
        single_record: single_record,
        associations: associations,
        as_json_options: as_json_options,
        run: run
      )
    end
  end
end
