# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V3
        class FindParticipant < FindQuery
          def initialize(id, query = nil)
            @request = Request.get(
              {
                entity: "Participant",
                id:,
                json: json_params(query || default_query)
              }
            )

            store_result
          end

          def default_query
            {
              return: "contact_id,display_name,participant_status,id,participant_fee_amount,participant_fee_level,participant_fee_currency"
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
                status: item["participant_status"],
                fee_level: item["participant_fee_level"],
                fee_amount: item["participant_fee_amount"],
                fee_currency: item["participant_fee_currency"]
              }
            }
          end
        end
      end
    end
  end
end
