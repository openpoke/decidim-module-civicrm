# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  describe SyncEventRegistrationJob do
    subject { described_class }

    let(:meeting) { create(:meeting) }
    let(:organization) { meeting.organization }
    let!(:event_meeting) { create(:civicrm_event_meeting, civicrm_event_id: 73, meeting:, organization:) }
    let(:participant_id) { 15_070 }
    let(:participant_data) do
      {
        participant: { id: participant_id, status: "Registered" },
        contact: { id: 100, display_name: "John Doe" }
      }
    end

    it "creates an event registration" do
      expect do
        subject.perform_now(participant_id, event_meeting_id: event_meeting.id, participant_data: participant_data)
      end.to change(EventRegistration, :count).by(1)

      registration = EventRegistration.last
      expect(registration.civicrm_event_registration_id).to eq(participant_id)
      expect(registration.event_meeting).to eq(event_meeting)
      expect(registration.extra).to eq(participant_data.deep_stringify_keys)
    end

    context "when registration already exists" do
      let(:user) { create(:user, organization: organization) }
      let(:meeting_registration) { create(:registration, meeting: meeting, user: user) }
      let!(:existing_registration) do
        create(:civicrm_event_registration,
               civicrm_event_registration_id: participant_id,
               event_meeting: event_meeting,
               meeting_registration: meeting_registration)
      end

      it "updates the existing registration" do
        expect do
          subject.perform_now(participant_id, event_meeting_id: event_meeting.id, participant_data: participant_data)
        end.not_to change(EventRegistration, :count)

        existing_registration.reload
        expect(existing_registration.extra).to eq(participant_data.deep_stringify_keys)
        expect(existing_registration.marked_for_deletion).to be_nil
      end
    end

    context "when event_meeting is not found" do
      it "logs a warning and returns" do
        expect(Rails.logger).to receive(:warn).with(/EventMeeting not found/)
        expect do
          subject.perform_now(participant_id, event_meeting_id: 99_999, participant_data: participant_data)
        end.not_to change(EventRegistration, :count)
      end
    end

    context "when participant_data is nil" do
      it "does not create registration" do
        expect do
          subject.perform_now(participant_id, event_meeting_id: event_meeting.id, participant_data: nil)
        end.not_to change(EventRegistration, :count)
      end
    end
  end
end
