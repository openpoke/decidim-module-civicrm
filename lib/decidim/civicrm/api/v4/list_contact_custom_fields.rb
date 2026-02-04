# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class ListContactCustomFields < ListQuery
          def request(offset, query = nil)
            Request.post(
              "CustomField",
              query || default_query(offset),
              "get"
            )
          end

          def default_query(offset)
            {
              select: %w(row_count id name label data_type custom_group_id),
              where: [["is_active", "=", true]],
              offset: offset
            }
          end

          def self.parse_item(item)
            {
              id: item["id"].to_i,
              name: item["name"],
              label: item["label"],
              data_type: item["data_type"],
              custom_group_id: item["custom_group_id"]&.to_i
            }
          end
        end
      end
    end
  end
end
