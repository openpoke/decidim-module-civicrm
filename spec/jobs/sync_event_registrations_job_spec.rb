# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim::Civicrm
  describe SyncEventRegistrationsJob do
    subject { described_class }

    include_context "with stubs example api"
    let(:return_data) do
      [{
        status: http_status,
        body: data1.to_json,
        headers: {}
      }, {
        status: http_status,
        body: data2.to_json,
        headers: {}
      }]
    end

    let(:data1) { JSON.parse(file_fixture("find_event_valid_response.json").read) }
    let(:data2) { JSON.parse(file_fixture("list_participants_valid_response.json").read) }
    let(:meeting) { create :meeting }
    let(:organization) { meeting.organization }
    let!(:event_meeting) { create :civicrm_event_meeting, civicrm_event_id: 73, meeting: meeting, organization: organization }

    it "creates event registrations" do
      expect { subject.perform_now(event_meeting.id) }.to change(EventRegistration, :count).by(2)
      expect(EventRegistration.all.map(&:civicrm_contact_id)).to match_array([1168, 505_761])
    end

    context "when there are event registrations to delete" do
      let(:user) { create :user, organization: organization }
      let(:registration) { create :registration, meeting: meeting, user: user }
      let!(:contact) { create :civicrm_contact, user: user, organization: organization, civicrm_contact_id: 789 }
      let!(:event_registration) { create :civicrm_event_registration, event_meeting: event_meeting, meeting_registration: registration, civicrm_event_registration_id: 123 }

      it "deletes the event registrations" do
        expect(EventRegistration.all.map(&:civicrm_contact_id)).to match_array([789])
        expect { subject.perform_now(event_meeting.id) }.to change(EventRegistration, :count).from(1).to(2)
        expect(EventRegistration.all.map(&:civicrm_contact_id)).to match_array([1168, 505_761])
      end

      context "and other event registrations are marked for deletion" do
        let(:other_user) { create :user, organization: organization }
        let(:other_registration) { create :registration, meeting: other_meeting, user: other_user }
        let(:other_meeting) { create :meeting, component: meeting.component }
        let!(:other_contact) { create :civicrm_contact, user: other_user, organization: organization, civicrm_contact_id: 678 }
        let!(:other_event_meeting) { create :civicrm_event_meeting, civicrm_event_id: 74, meeting: other_meeting, organization: organization }
        let!(:other_event_registration) { create :civicrm_event_registration, event_meeting: other_event_meeting, meeting_registration: other_registration, civicrm_event_registration_id: 123, marked_for_deletion: true }

        it "deletes only the event registrations that are not marked for deletion" do
          expect(EventRegistration.all.map(&:civicrm_contact_id)).to match_array([789, 678])
          expect { subject.perform_now(event_meeting.id) }.to change(EventRegistration, :count).from(2).to(3)
          expect(EventRegistration.all.map(&:civicrm_contact_id)).to match_array([678, 1168, 505_761])
        end
      end
    end

    context "when there are event registrations from other organizations" do
      let(:other_meeting) { create :meeting }
      let(:other_organization) { other_meeting.organization }
      let(:other_user) { create :user, organization: other_organization }
      let(:other_registration) { create :registration, meeting: other_meeting, user: other_user }
      let!(:other_contact) { create :civicrm_contact, user: other_user, organization: other_organization, civicrm_contact_id: 789 }
      let!(:other_event_meeting) { create :civicrm_event_meeting, civicrm_event_id: 74, meeting: other_meeting, organization: other_organization }
      let!(:other_event_registration) { create :civicrm_event_registration, event_meeting: other_event_meeting, meeting_registration: other_registration, civicrm_event_registration_id: 123 }

      it "deletes only events from this organization" do
        expect(EventRegistration.all.map(&:civicrm_contact_id)).to match_array([789])
        expect { subject.perform_now(event_meeting.id) }.to change(EventRegistration, :count).from(1).to(3)
        expect(EventRegistration.all.map(&:civicrm_contact_id)).to match_array([789, 1168, 505_761])
      end
    end
  end
end
