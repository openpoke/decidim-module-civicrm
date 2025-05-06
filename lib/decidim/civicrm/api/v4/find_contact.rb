# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class FindContact < Base::V4::FindQuery
          def initialize(id, query = nil)
            @request = Base::V4::Request.post(
              "Contact",
              query || default_query(id),
              "get"
            )

            store_result
          end

          def default_query(id)
            {
              select: %w(id membership.membership_type_id display_name),
              join: [["Membership AS membership", "LEFT"]],
              where: [["id", "=", id]]
            }
          end

          def self.parse_item(item)
            contact = {
              id: item["id"],
              display_name: item["display_name"]
            }

            {
              contact: contact,
              memberships: Array(item["membership.membership_type_id"])
            }
          end
        end
      end
    end
  end
end
