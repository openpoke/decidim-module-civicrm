# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim::Civicrm
  describe EventSyncJob do
    subject { described_class }

    include_context "with stubs example api"
    let(:data) { JSON.parse(file_fixture("find_event_valid_response.json").read) }
    let(:post_data) do
      {
        is_error: 0,
        id: 73
      }
    end
    let(:event_name) { "decidim.events.meetings.meeting_created" }
    let(:meeting) { create :meeting }
    let(:organization) { meeting.organization }
    let(:event_data) do
      {
        resource: meeting,
        affected_users: affected_users
      }
    end
    let(:user) { create :user, organization: organization }
    let(:affected_users) { [user] }
    let(:publish_meetings_as_events) { true }
    let(:publish_meeting_registrations) { true }

    before do
      allow(Decidim::Civicrm::Api).to receive(:url).and_return(url)
      stub_request(:post, /api\.example\.org/)
        .to_return(status: 200, body: post_data.to_json, headers: {})
      allow(Decidim::Civicrm).to receive(:publish_meetings_as_events).and_return(publish_meetings_as_events)
      allow(Decidim::Civicrm).to receive(:publish_meeting_registrations).and_return(publish_meeting_registrations)
    end

    it "creates an event meeting" do
      expect { subject.perform_now(event_name, event_data) }.to change(EventMeeting, :count).by(1)
      expect(EventMeeting.last.civicrm_event_id).to eq(73)
    end

    context "when publish meetings is disabled" do
      let(:publish_meetings_as_events) { false }

      it "does not create an event meeting" do
        expect { subject.perform_now(event_name, event_data) }.not_to change(EventMeeting, :count)
      end
    end

    context "when parser is invalid" do
      let(:event_name) { "decidim.events.meetings.meeting_created" }
      let(:event_data) do
        {
          resource: nil,
          affected_users: affected_users
        }
      end

      it "does not create an event meeting" do
        expect { subject.perform_now(event_name, event_data) }.not_to change(EventMeeting, :count)
      end
    end

    context "when response with error" do
      let(:post_data) do
        {
          is_error: 1
        }
      end

      it "does not create an event meeting" do
        expect { subject.perform_now(event_name, event_data) }.not_to change(EventMeeting, :count)
      end
    end

    context "when event registration event" do
      let(:event_name) { "decidim.events.meetings.meeting_registration_confirmed" }
      let!(:registration) { create :registration, user: user, meeting: meeting }
      let!(:event_meeting) { create :civicrm_event_meeting, organization: organization, meeting: meeting, civicrm_event_id: 73 }
      let!(:authorization) { create :authorization, user: user, name: "civicrm", metadata: { contact_id: 123 } }

      it "does not create an event meeting" do
        expect { subject.perform_now(event_name, event_data) }.not_to change(EventMeeting, :count)
      end

      it "creates an event registration" do
        expect { subject.perform_now(event_name, event_data) }.to change(EventRegistration, :count).by(1)
        expect(EventRegistration.last.civicrm_event_registration_id).to eq(73)
      end

      context "when publish meeting registrations is disabled" do
        let(:publish_meeting_registrations) { false }

        it "does not create an event registration" do
          expect { subject.perform_now(event_name, event_data) }.not_to change(EventRegistration, :count)
        end
      end
    end
  end
end
