# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module Base
        module V4
          class FindQuery < BaseQuery
            protected

            def parsed_response
              self.class.parse_item(response["values"].first)
            end
          end
        end
      end
    end
  end
end
