# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class ListContactsInGroup < Base::V4::ListQuery
          def request(offset, query = nil)
            Base::V4::Request.post(
              "Contact",
              query || default_query(offset),
              "get"
            )
          end

          def default_query(offset)
            {
              select: %w(row_count contact_id display_name),
              offset: offset,
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
