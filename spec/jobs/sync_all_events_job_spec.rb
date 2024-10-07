# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim::Civicrm
  describe SyncAllEventsJob do
    subject { described_class }

    include_context "with stubs example api"

    let(:data) { JSON.parse(file_fixture("list_events_valid_response.json").read) }
    let(:meeting) { create(:meeting) }
    let(:organization) { meeting.organization }

    it "creates event meetings" do
      expect { subject.perform_now(organization.id) }.to change(EventMeeting, :count).from(0).to(3)
      expect(EventMeeting.pluck(:civicrm_event_id)).to contain_exactly(11, 12, 13)
    end

    context "when there are events to delete" do
      let!(:event) { create(:civicrm_event_meeting, meeting:, organization:, civicrm_event_id: 15) }

      it "deletes the events" do
        expect(EventMeeting.pluck(:civicrm_event_id)).to contain_exactly(15)
        expect { subject.perform_now(organization.id) }.to change(EventMeeting, :count).from(1).to(3)
        expect(EventMeeting.pluck(:civicrm_event_id)).to contain_exactly(11, 12, 13)
      end
    end

    context "when there are events from other organizations" do
      let(:other_meeting) { create(:meeting) }
      let!(:event) { create(:civicrm_event_meeting, meeting:, organization:, civicrm_event_id: 15) }
      let!(:other_event) { create(:civicrm_event_meeting, meeting: other_meeting, organization: other_meeting.organization, civicrm_event_id: 16, marked_for_deletion: true) }

      it "deletes only events from this organization" do
        expect(EventMeeting.pluck(:civicrm_event_id)).to contain_exactly(15, 16)
        expect { subject.perform_now(organization.id) }.to change(EventMeeting, :count).from(2).to(4)
        expect(EventMeeting.pluck(:civicrm_event_id)).to contain_exactly(11, 12, 13, 16)
      end
    end
  end
end
