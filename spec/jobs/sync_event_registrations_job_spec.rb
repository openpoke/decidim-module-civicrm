# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim::Civicrm
  describe SyncEventRegistrationsJob do
    subject { described_class }

    include_context "with stubs example api v4"
    let(:api_returns) do
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

    let(:data1) { JSON.parse(file_fixture("v4/find_event_valid_response.json").read) }
    let(:data2) { JSON.parse(file_fixture("v4/list_participants_valid_response.json").read) }
    let(:meeting) { create(:meeting) }
    let(:organization) { meeting.organization }
    let!(:event_meeting) { create(:civicrm_event_meeting, civicrm_event_id: 73, meeting:, organization:) }

    before do
      allow(Decidim::Civicrm).to receive(:api_rate_limit_delay).and_return(0.seconds)
    end

    it "creates event registrations" do
      expect { subject.perform_now(event_meeting.id) }.to change(EventRegistration, :count).by(2)
      expect(EventRegistration.all.map(&:civicrm_contact_id)).to contain_exactly(15_070, 15_071)
    end

    context "when there are event registrations to delete" do
      let(:user) { create(:user, organization:) }
      let(:registration) { create(:registration, meeting:, user:) }
      let!(:contact) { create(:civicrm_contact, user:, organization:, civicrm_contact_id: 789) }
      let!(:event_registration) { create(:civicrm_event_registration, event_meeting:, meeting_registration: registration, civicrm_event_registration_id: 123) }

      it "deletes the event registrations" do
        expect(EventRegistration.all.map(&:civicrm_contact_id)).to contain_exactly(789)
        expect { subject.perform_now(event_meeting.id) }.to change(EventRegistration, :count).from(1).to(2)
        expect(EventRegistration.all.map(&:civicrm_contact_id)).to contain_exactly(15_070, 15_071)
      end

      context "and other event registrations are marked for deletion" do
        let(:other_user) { create(:user, organization:) }
        let(:other_registration) { create(:registration, meeting: other_meeting, user: other_user) }
        let(:other_meeting) { create(:meeting, component: meeting.component) }
        let!(:other_contact) { create(:civicrm_contact, user: other_user, organization:, civicrm_contact_id: 678) }
        let!(:other_event_meeting) { create(:civicrm_event_meeting, civicrm_event_id: 74, meeting: other_meeting, organization:) }
        let!(:other_event_registration) { create(:civicrm_event_registration, event_meeting: other_event_meeting, meeting_registration: other_registration, civicrm_event_registration_id: 123, marked_for_deletion: Time.current) }

        it "deletes only the event registrations that are not marked for deletion" do
          expect(EventRegistration.all.map(&:civicrm_contact_id)).to contain_exactly(789, 678)
          expect { subject.perform_now(event_meeting.id) }.to change(EventRegistration, :count).from(2).to(3)
          expect(EventRegistration.all.map(&:civicrm_contact_id)).to contain_exactly(678, 15_070, 15_071)
        end
      end
    end

    context "when there are event registrations from other organizations" do
      let(:other_meeting) { create(:meeting) }
      let(:other_organization) { other_meeting.organization }
      let(:other_user) { create(:user, organization: other_organization) }
      let(:other_registration) { create(:registration, meeting: other_meeting, user: other_user) }
      let!(:other_contact) { create(:civicrm_contact, user: other_user, organization: other_organization, civicrm_contact_id: 789) }
      let!(:other_event_meeting) { create(:civicrm_event_meeting, civicrm_event_id: 74, meeting: other_meeting, organization: other_organization) }
      let!(:other_event_registration) { create(:civicrm_event_registration, event_meeting: other_event_meeting, meeting_registration: other_registration, civicrm_event_registration_id: 123) }

      it "deletes only events from this organization" do
        expect(EventRegistration.all.map(&:civicrm_contact_id)).to contain_exactly(789)
        expect { subject.perform_now(event_meeting.id) }.to change(EventRegistration, :count).from(1).to(3)
        expect(EventRegistration.all.map(&:civicrm_contact_id)).to contain_exactly(789, 15_070, 15_071)
      end
    end

    context "with pagination" do
      let(:page_size) { 1 }
      let(:api_returns) do
        [
          { status: 200, body: data1.to_json, headers: {} },
          { status: 200, body: first_page_participants.to_json, headers: {} },
          { status: 200, body: second_page_participants.to_json, headers: {} }
        ]
      end

      let(:first_page_participants) do
        {
          "values" => [data2["values"].first],
          "entity" => "Participant",
          "action" => "get",
          "count" => 2,
          "countFetched" => 1,
          "countMatched" => 2
        }
      end

      let(:second_page_participants) do
        {
          "values" => [data2["values"][1]],
          "entity" => "Participant",
          "action" => "get",
          "count" => 2,
          "countFetched" => 1,
          "countMatched" => 2
        }
      end

      before do
        allow(Decidim::Civicrm).to receive(:api_records_by_page).and_return(page_size)
        stub_request(:post, /api\.example\.org/)
          .with(body: hash_including("params" => hash_including("offset" => 0)))
          .to_return(status: 200, body: first_page_participants.to_json, headers: {})
        stub_request(:post, /api\.example\.org/)
          .with(body: hash_including("params" => hash_including("offset" => 1)))
          .to_return(status: 200, body: second_page_participants.to_json, headers: {})
      end

      it "processes first page and schedules next page" do
        expect { subject.perform_now(event_meeting.id, page: 0) }.to change(EventRegistration, :count).by(1)
        expect(EventRegistration.all.map(&:civicrm_contact_id)).to contain_exactly(15_070)
        expect(subject).to have_been_enqueued.with(event_meeting.id, page: 1, sync_id: a_kind_of(ActiveSupport::TimeWithZone)).on_queue("default")
      end
    end
  end
end
