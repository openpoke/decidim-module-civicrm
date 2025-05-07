# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class ListParticipantsInEvent < ListQuery
          def request(offset, query = nil)
            Request.post(
              "Participant",
              query || default_query(offset),
              "get"
            )
          end

          def default_query(offset)
            {
              select: %w(row_count id contact_id contact_id.display_name status_id:name fee_amount fee_level fee_currency),
              offset:,
              where: [["event_id", "=", @id]]
            }
          end

          def self.parse_item(item)
            FindParticipant.parse_item(item)
          end
        end
      end
    end
  end
end
