# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      class FindUser < Base::FindQuery
        def initialize(id, query = nil)
          @request = Base::Request.get(
            {
              entity: "User",
              id:,
              json: json_params(query || default_query)
            }
          )

          store_result
        end

        def default_query
          {
            "api.Contact.get" => {
              return: "display_name"
            },
            "api.Membership.get": {
              contact_id: "$value.contact_id",
              return: "membership_type_id"
            }
          }
        end

        def self.parse_item(item)
          user = item
          contact = user.delete("api.Contact.get")["values"].first
          memberships = user.delete("api.Membership.get")["values"]

          {
            user: {
              id: user["id"].to_i,
              name: user["name"],
              email: user["email"],
              contact_id: user["contact_id"].to_i
            },
            contact: {
              id: user["contact_id"].to_i,
              display_name: contact["display_name"]
            },
            memberships: memberships.map { |m| ListContactMemberships.parse_item(m) }
          }
        end
      end
    end
  end
end
