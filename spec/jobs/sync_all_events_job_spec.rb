# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim::Civicrm
  describe SyncAllEventsJob do
    subject { described_class }

    include_context "with stubs example api v4"

    let(:data) { JSON.parse(file_fixture("v4/list_events_valid_response.json").read) }
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

    context "with pagination" do
      let(:page_size) { 1 }
      let(:first_page_data) do
        {
          "values" => [data["values"].first],
          "entity" => "Event",
          "action" => "get",
          "count" => 3,
          "countFetched" => 1,
          "countMatched" => 3
        }
      end

      let(:second_page_data) do
        {
          "values" => [data["values"][1]],
          "entity" => "Event",
          "action" => "get",
          "count" => 3,
          "countFetched" => 1,
          "countMatched" => 3
        }
      end

      before do
        allow(Decidim::Civicrm).to receive(:api_records_by_page).and_return(page_size)
        stub_request(:post, /api\.example\.org/)
          .with(body: hash_including("params" => hash_including("offset" => 0)))
          .to_return(status: 200, body: first_page_data.to_json, headers: {})
        stub_request(:post, /api\.example\.org/)
          .with(body: hash_including("params" => hash_including("offset" => 1)))
          .to_return(status: 200, body: second_page_data.to_json, headers: {})
      end

      it "processes first page and schedules next page" do
        expect { subject.perform_now(organization.id, page: 0) }.to change(EventMeeting, :count).by(1)
        expect(EventMeeting.pluck(:civicrm_event_id)).to contain_exactly(11)
        expect(subject).to have_been_enqueued.with(organization.id, page: 1).on_queue("default")
      end
    end
  end
end
