require 'active_record'
require 'kaminari'

module PatternQueryHelper
  class Pagination
    def self.parse_pagination_params(params)
      if params[:per_page] == 'all'
        pagination_params = {
          include_all: true
        }
      else
        if params[:page]
          page = params[:page].to_i
        else
          page = 1
        end
        if params[:per_page]
          per_page = params[:per_page].to_i
        else
          per_page = 20
        end
        raise RangeError.new("page must be greater than 0") unless page > 0
        raise RangeError.new("per_page must be greater than 0") unless per_page > 0
        pagination_params = {
          page: page.to_i,
          per_page: per_page.to_i
        }
      end

      pagination_params

    end

    def self.create_pagination_payload(count, pagination_params)
      page = pagination_params[:page]
      per_page = pagination_params[:per_page]
      total_pages = (count/(per_page.nonzero? || 1).to_f).ceil
      next_page = page + 1 if page.between?(1, total_pages - 1)
      previous_page = page - 1 if page.between?(2, total_pages)
      first_page = page == 1
      last_page = page == total_pages
      out_of_range = !page.between?(1,total_pages)

      {
        count: count,
        current_page: page,
        next_page: next_page,
        previous_page: previous_page,
        total_pages: total_pages,
        per_page: per_page,
        first_page: first_page,
        last_page: last_page,
        out_of_range: out_of_range
      }
    end

    def self.paginate_active_record_query(active_record_call, pagination_params)
      page = pagination_params[:page]
      per_page = pagination_params[:per_page]
      active_record_call.page(page).per(per_page)
    end
  end
end
