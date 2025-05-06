# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module Base
        module V4
          class ListQuery < BaseQuery
            protected

            def initialize(id = nil, query = nil)
              results = []
              offset = 0
              @id = id
              @request = request(offset, query)

              store_result
              results << @result[:values]
              offset += self.class.records_by_page
              while offset < @result[:count_matched]
                @request = request(offset, query)

                store_result
                results << @result[:values]
                offset += self.class.records_by_page
              end
              @result = results.flatten
            end

            def parsed_response
              {
                count_matched: response["countMatched"],
                values: response["values"].map { |item| self.class.parse_item(item) }
              }
            end

            class << self
              def records_by_page
                200
              end
            end
          end
        end
      end
    end
  end
end
