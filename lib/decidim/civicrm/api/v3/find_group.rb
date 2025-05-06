# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V3
        class FindGroup < Base::V3::FindQuery
          def initialize(id, query = nil)
            @request = Base::V3::Request.get(
              {
                entity: "Group",
                group_id: id,
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
            {
              id: item["id"].to_i,
              name: item["name"],
              title: item["title"],
              description: item["description"],
              group_type: item["group_type"].respond_to?(:map) ? item["group_type"].map(&:to_i) : [item["group_type"].to_i]
            }
          end
        end
      end
    end
  end
end
