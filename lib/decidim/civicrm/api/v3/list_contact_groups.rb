# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V3
        class ListContactGroups < Base::V3::ListQuery
          def initialize(id, query = nil)
            @request = Base::V3::Request.get(
              {
                entity: "GroupContact",
                contact_id: id,
                json: json_params(query || default_query)
              }
            )

            store_result
          end

          def default_query
            {
              select: "group_id"
            }
          end

          def self.parse_item(item)
            item["group_id"].to_i
          end
        end
      end
    end
  end
end
