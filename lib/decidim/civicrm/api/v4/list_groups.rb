# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class ListGroups < Base::V4::ListQuery
          def request(offset, query = nil)
            Base::V4::Request.post(
              "Group",
              query || default_query(offset),
              "get"
            )
          end

          def default_query(offset)
            {
              select: %w(row_count group_id name title description group_type),
              offset: offset
            }
          end

          def self.parse_item(item)
            FindGroup.parse_item(item)
          end
        end
      end
    end
  end
end
