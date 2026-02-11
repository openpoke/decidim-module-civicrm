# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class ListGroupContacts < ListQuery
          def request(offset, query = nil)
            Request.post(
              "Contact",
              query || default_query(offset),
              "get"
            )
          end

          def default_query(offset)
            {
              select: %w(id display_name row_count),
              offset:,
              limit:,
              where: [["groups", "IN", @id]]
            }
          end

          def self.parse_item(item)
            {
              contact_id: item["id"],
              display_name: item["display_name"]
            }
          end
        end
      end
    end
  end
end
