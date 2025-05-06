# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V3
        class ListGroups < Base::V3::ListQuery
          def initialize(query = nil)
            @request = Base::V3::Request.get(
              {
                entity: "Group",
                is_active: 1, # esto sigue existiendo?
                json: json_params(query || default_query)
              }
            )

            store_result
          end

          def default_query
            {
              return: "group_id,name,title,description,group_type"
            }
          end

          def self.parse_item(item)
            FindGroup.parse_item(item)
          end
        end
      end
    end
  end
end
