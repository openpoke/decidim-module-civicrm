# frozen_string_literal: true

module Decidim
  module Civicrm
    module Api
      class FindEvent < Base::FindQuery
        def initialize(id, query = nil)
          @request = Base::Request.get(
            {
              entity: "Event",
              id:,
              json: json_params(query || default_query)
            }
          )

          store_result
        end

        # rubocop:disable Layout/LineLength
        def default_query
          {
            return: "id,title,event_title,summary,event_description,description,event_type_id,participant_listing_id,is_public,start_date,event_start_date,end_date,event_end_date,is_online_registration,is_online_registration,registration_start_date,registration_end_date,registration_link_text,max_participants,event_full_text,is_monetary,contribution_type_id,is_map,is_active,is_show_location,default_role_id,confirm_title,is_email_confirm,thankyou_title,is_pay_later,is_partial_payment,is_multiple_registrations,max_additional_participants,allow_same_participant_emails,has_waitlist,requires_approval,allow_selfcancelxfer,selfcancelxfer_time,approval_req_text,is_template,created_id,created_date,is_share,is_confirm_enabled,is_billing_required"
          }
        end
        # rubocop:enable Layout/LineLength

        def self.parse_item(item)
          return {} unless item.is_a?(Hash)

          {
            id: item["id"].to_i,
            title: item["title"] || item["event_title"],
            description: item["description"] || item["event_description"],
            summary: item["summary"],
            event_type_id: item["event_type_id"].to_i,
            participant_listing_id: item["participant_listing_id"].to_i,
            is_public: to_bool(item["is_public"]),
            start_date: (item["start_date"] || item["event_start_date"]).try(:to_time),
            end_date: (item["end_date"] || item["event_end_date"]).try(:to_time),
            is_online_registration: to_bool(item["is_online_registration"]),
            registration_start_date: item["registration_start_date"].try(:to_time),
            registration_end_date: item["registration_end_date"].try(:to_time),
            registration_link_text: item["registration_link_text"],
            max_participants: item["max_participants"].to_i,
            event_full_text: item["event_full_text"],
            is_monetary: to_bool(item["is_monetary"]),
            contribution_type_id: item["contribution_type_id"].to_i,
            is_map: to_bool(item["is_map"]),
            is_active: to_bool(item["is_active"]),
            is_show_location: to_bool(item["is_show_location"]),
            default_role_id: item["default_role_id"].to_i,
            confirm_title: item["confirm_title"],
            is_email_confirm: to_bool(item["is_email_confirm"]),
            thankyou_title: item["thankyou_title"],
            is_pay_later: to_bool(item["is_pay_later"]),
            is_partial_payment: to_bool(item["is_partial_payment"]),
            is_multiple_registrations: to_bool(item["is_multiple_registrations"]),
            max_additional_participants: item["max_additional_participants"].to_i,
            allow_same_participant_emails: to_bool(item["allow_same_participant_emails"]),
            has_waitlist: to_bool(item["has_waitlist"]),
            requires_approval: to_bool(item["requires_approval"]),
            allow_selfcancelxfer: to_bool(item["allow_selfcancelxfer"]),
            approval_req_text: item["approval_req_text"],
            is_template: to_bool(item["is_template"]),
            created_id: item["created_id"].to_i,
            created_date: item["created_date"].try(:to_time),
            is_share: to_bool(item["is_share"]),
            is_confirm_enabled: to_bool(item["is_confirm_enabled"]),
            is_billing_required: to_bool(item["is_billing_required"])
          }
        end
      end
    end
  end
end
