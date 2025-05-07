# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class FindContact < FindQuery
          def initialize(id, query = nil)
            @request = Request.post(
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
            {
              contact: {
                id: item["id"],
                display_name: item["display_name"]
              }
            }
          end

          def parsed_response
            self.class.parse_item(response["values"].first).tap do |resp|
              resp[:memberships] = response["values"].pluck("membership.membership_type_id")&.map(&:to_i)
            end
          end
        end
      end
    end
  end
end
