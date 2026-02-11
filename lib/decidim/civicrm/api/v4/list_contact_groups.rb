# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class ListContactGroups < ListQuery
          def request(offset, query = nil)
            Request.post(
              "GroupContact",
              query || default_query(offset),
              "get"
            )
          end

          def default_query(offset)
            {
              select: %w(group_id row_count),
              where: [["contact_id", "=", @id]],
              offset:,
              limit:
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
