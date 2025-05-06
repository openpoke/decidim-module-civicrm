# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V3
        class ListMembershipTypes < Base::V3::ListQuery
          def initialize(query = nil)
            @request = Base::V3::Request.get(
              {
                entity: "MembershipType",
                json: json_params(query || default_query)
              }
            )
            store_result
          end

          def default_query
            {
              options: { limit: 0 },
              return: "name"
            }
          end

          def self.parse_item(item)
            {
              id: item["id"].to_i,
              name: item["name"]
            }
          end
        end
      end
    end
  end
end
