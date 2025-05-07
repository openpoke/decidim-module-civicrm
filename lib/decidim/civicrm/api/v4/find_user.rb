# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class FindUser < FindQuery
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
              select: %w(uf_match.uf_id uf_match.contact_id display_name email_primary.email membership.membership_type_id),
              join: [["UFMatch AS uf_match", "LEFT"], ["Membership AS membership", "LEFT"]],
              where: [["uf_match.uf_id", "=", id]]
            }
          end

          def self.parse_item(item)
            {
              user: {
                id: item["id"],
                name: item["name"],
                email: item["email_primary.email"],
                contact_id: item["uf_match.contact_id"]
              },
              contact: {
                id: item["uf_match.contact_id"],
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
