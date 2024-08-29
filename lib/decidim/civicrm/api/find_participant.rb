# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      class FindParticipant < Base::FindQuery
        def initialize(id, query = nil)
          @request = Base::Request.get(
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

        private

        def parsed_response
          {
            participant: response["values"].first
          }
        end
      end
    end
  end
end
