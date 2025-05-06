# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class ListContactGroups < Base::V4::ListQuery
          def request(offset, query = nil)
            Base::V4::Request.post(
              "GroupContact",
              query || default_query(offset),
              "get"
            )
          end

          def default_query(offset)
            {
              select: %w(row_count group_id),
              where: [["contact_id", "=", @id]],
              offset: offset
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
