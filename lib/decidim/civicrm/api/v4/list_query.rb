# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class ListQuery < BaseQuery
          attr_reader :count

          def initialize(id = nil, fetch_all: false, page: 0)
            results = []
            offset = page * limit
            @id = id
            @request = request(offset)
            store_result
            @count = @result[:count]
            results << @result[:values]

            if fetch_all
              offset += limit
              while offset < @count
                @request = request(offset)

                store_result
                results << @result[:values]
                offset += limit
              end
            end

            @result = results.flatten
          end

          def parsed_response
            {
              count: (response["count"] || response["countMatched"] || response["countFetched"]).to_i,
              values: response["values"].map { |item| self.class.parse_item(item) }
            }
          end

          def limit
            Decidim::Civicrm.api_records_by_page
          end
        end
      end
    end
  end
end
