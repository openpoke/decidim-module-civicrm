# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module Base
        module V3
          class FindQuery < BaseQuery
            protected

            def json_params(params)
              params.deep_merge(
                sequential: 1
              ).to_json
            end

            def parsed_response
              self.class.parse_item(response["values"].first)
            end
          end
        end
      end
    end
  end
end
