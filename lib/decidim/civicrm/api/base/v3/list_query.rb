# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module Base
        module V3
          class ListQuery < BaseQuery
            protected

            def json_params(params)
              params.deep_merge(
                sequential: 1,
                options: { limit: 0 }
              ).to_json
            end

            def parsed_response
              response["values"].map { |item| self.class.parse_item(item) }
            end
          end
        end
      end
    end
  end
end
