# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class ParticipantsInEvent < Base::V4::ListQuery
          def request(offset, query = nil)
            Base::V4::Request.post(
              "Participant",
              query || default_query(offset),
              "get"
            )
          end

          def default_query(offset)
            {
              select: %w(row_count id contact_id contact_id.display_name status_id:name fee_amount fee_level fee_currency),
              offset: offset,
              where: [["event_id", "=", @id]]
            }
          end

          def self.parse_item(item)
            {
              contact_id: item["contact_id"].to_s,
              display_name: item["contact_id.display_name"],
              participant_id: item["id"].to_s,
              participant_fee_level: item["fee_level"],
              participant_fee_amount: item["fee_amount"],
              participant_fee_currency: item["fee_currency"],
              participant_status: item["status_id:name"],
              id: item["id"].to_s
            }
          end
        end
      end
    end
  end
end
