# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class ListContactCustomFields < ListQuery
          def request(offset, query = nil)
            Request.post(
              "Contact",
              query || default_query(offset),
              "get"
            )
          end

          def default_query(offset)
            {
              select: %w(custom.*),
              where: [["id", "=", @id]],
              offset:
            }
          end

          def self.parse_item(item)
            item
          end
        end
      end
    end
  end
end
