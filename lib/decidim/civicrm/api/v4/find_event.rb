# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class FindEvent < Base::V4::FindQuery
          def initialize(id, query = nil)
            @request = Base::V4::Request.post(
              "Event",
              query || default_query(id),
              "get"
            )

            store_result
          end

          def default_query(id)
            {
              select: %w(event_id title event_title event_type start_date event_start_date end_date event_end_date),
              where: [["id", "=", id]]
            }
          end

          private

          def parsed_response
            response_hash = response["values"].first
            if response_hash
              response_hash["event_title"] = response_hash["title"]
              response_hash["event_start_date"] = response_hash["start_date"]
              response_hash["event_end_date"] = response_hash["end_date"]
            end
            {
              event: response_hash
            }
          end
        end
      end
    end
  end
end
