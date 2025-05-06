# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V3
        class ListContactMemberships < Base::V3::ListQuery
          def initialize(id, query = nil)
            @request = Base::V3::Request.get(
              {
                entity: "Membership",
                contact_id: id,
                json: json_params(query || default_query)
              }
            )

            store_result
          end

          def default_query
            {
              return: "membership_type_id"
            }
          end

          def self.parse_item(item)
            item["membership_type_id"].to_i
          end
        end
      end
    end
  end
end
