# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class ListMembershipTypes < ListQuery
          def request(offset, query = nil)
            Request.post(
              "MembershipType",
              query || default_query(offset),
              "get"
            )
          end

          def default_query(offset)
            {
              select: %w(row_count name),
              offset: offset
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
