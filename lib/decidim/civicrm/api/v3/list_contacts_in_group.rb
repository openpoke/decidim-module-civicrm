# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V3
        class ListContactsInGroup < Base::V3::ListQuery
          def initialize(id, query = nil)
            @request = Base::V3::Request.get(
              {
                entity: "Contact",
                group: id,
                json: json_params(query || default_query)
              }
            )

            store_result
          end

          def default_query
            {
              return: "contact_id,display_name"
            }
          end

          def self.parse_item(item)
            {
              contact_id: item["contact_id"].to_i,
              display_name: item["display_name"]
            }
          end
        end
      end
    end
  end
end
