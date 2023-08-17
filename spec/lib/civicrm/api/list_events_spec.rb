# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim
  describe Civicrm::Api::ListEvents, type: :class do
    subject { described_class.new }

    include_context "with stubs example api"

    let(:data) { JSON.parse(file_fixture("list_events_valid_response.json").read) }

    describe "#result" do
      it "returns array of objects" do
        expect(subject.result).to be_a Array
        data["values"].each do |event|
          event = {
            id: event["id"].to_i,
            title: event["event_title"],
            description: event["description"],
            summary: event["summary"],
            allow_same_participant_emails: nil,
            allow_selfcancelxfer: nil,
            approval_req_text: nil,
            confirm_title: nil,
            contribution_type_id: event["contribution_type_id"].to_i,
            created_date: nil,
            created_id: 0,
            default_role_id: event["default_role_id"].to_i,
            end_date: event["end_date"].try(:to_time),
            event_full_text: event["event_full_text"],
            event_type_id: event["event_type_id"].to_i,
            has_waitlist: nil,
            is_active: event["is_active"].to_i == 1,
            is_billing_required: nil,
            is_confirm_enabled: nil,
            is_email_confirm: nil,
            is_map: event["is_map"].to_i == 1,
            is_monetary: event["is_monetary"].to_i == 1,
            is_multiple_registrations: nil,
            is_online_registration: event["is_online_registration"].to_i == 1,
            is_partial_payment: nil,
            is_pay_later: nil,
            is_public: event["is_public"].to_i == 1,
            is_share: nil,
            is_show_location: event["is_show_location"].to_i == 1,
            is_template: nil,
            max_additional_participants: event["max_additional_participants"].to_i,
            max_participants: event["max_participants"].to_i,
            participant_listing_id: event["participant_listing_id"].to_i,
            registration_end_date: event["registration_end_date"].try(:to_time),
            registration_link_text: nil,
            registration_start_date: event["registration_start_date"].try(:to_time),
            requires_approval: nil,
            start_date: event["start_date"].try(:to_time),
            thankyou_title: nil
          }
          expect(subject.result).to include(event)
        end
      end
    end
  end
end
