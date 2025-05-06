# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class FindGroup < Base::V4::FindQuery
          def initialize(id, query = nil)
            @request = Base::V4::Request.post(
              "Group",
              query || default_query(id),
              "get"
            )

            store_result
          end

          def default_query(id)
            {
              select: %w(group_id name title description group_type),
              where: [["id", "=", id]]
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
