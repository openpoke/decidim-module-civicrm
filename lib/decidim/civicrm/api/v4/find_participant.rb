# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class FindParticipant < FindQuery
          def initialize(id, query = nil)
            @request = Request.post(
              "Participant",
              query || default_query(id),
              "get"
            )

            store_result
          end

          def default_query(id)
            {
              select: %w(contact_id contact_id.display_name status_id status_id:label id fee_amount fee_level fee_currency),
              where: [["id", "=", id]]
            }
          end

          def self.parse_item(item)
            {
              contact: {
                id: item["contact_id"],
                display_name: item["display_name"]
              },
              participant: {
                id: item["id"],
                status: item["status"],
                fee_level: item["fee_level"],
                fee_amount: item["fee_amount"],
                fee_currency: item["fee_currency"]
              }
            }
          end
        end
      end
    end
  end
end
