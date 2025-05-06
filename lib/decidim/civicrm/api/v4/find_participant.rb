# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class FindParticipant < Base::V4::FindQuery
          def initialize(id, query = nil)
            @request = Base::V4::Request.post(
              "Participant",
              query || default_query(id),
              "get"
            )

            store_result
          end

          def default_query(id)
            {
              select: %w(contact_id contact_id.display_name status_id:label id fee_amount fee_level fee_currency),
              where: [["id", "=", id]]
            }
          end

          private

          def parsed_response
            response_hash = response["values"].first
            if response_hash
              response_hash["display_name"] = response_hash.delete("contact_id.display_name")
              response_hash["participant_status"] = response_hash.delete("status_id:label")
              response_hash["participant_fee_level"] = response_hash.delete("fee_level")
              response_hash["participant_fee_amount"] = response_hash.delete("fee_amount")
              response_hash["participant_fee_currency"] = response_hash.delete("fee_currency")
              response_hash["participant_id"] = response_hash["id"]
            end
            {
              participant: response_hash
            }
          end
        end
      end
    end
  end
end
