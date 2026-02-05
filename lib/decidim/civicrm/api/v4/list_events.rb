# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      module V4
        class ListEvents < ListQuery
          def request(offset, query = nil)
            Request.post(
              "Event",
              query || default_query(offset),
              "get"
            )
          end

          def default_query(offset)
            {
              select: %w(id title event_title summary event_description description event_type_id participant_listing_id is_public start_date event_start_date end_date
                         event_end_date is_online_registration is_online_registration registration_start_date registration_end_date registration_link_text max_participants
                         event_full_text is_monetary contribution_type_id is_map is_active is_show_location default_role_id confirm_title is_email_confirm thankyou_title
                         is_pay_later is_partial_payment is_multiple_registrations max_additional_participants allow_same_participant_emails has_waitlist requires_approval
                         allow_selfcancelxfer selfcancelxfer_time approval_req_text is_template created_id created_date is_share is_confirm_enabled is_billing_required),
              offset:,
              limit:
            }
          end

          def self.parse_item(item)
            FindEvent.parse_item(item)
          end
        end
      end
    end
  end
end
