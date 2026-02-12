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
              select: %w(custom.* row_count),
              where: [["id", "=", @id]],
              limit:,
              offset:
            }
          end

          def self.first_item
            Request.post("Contact", { select: %w(custom.*), limit: 1 }, "get").response
          end

          def self.search_by(**fields)
            where = fields.map { |field, value| [field, "=", value] }
            Request.post("Contact", { select: %w(custom.*), where: where }, "get").response
          end

          def self.parse_item(item)
            item
          end
        end
      end
    end
  end
end
