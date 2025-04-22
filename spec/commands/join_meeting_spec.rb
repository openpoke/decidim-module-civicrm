# frozen_string_literal: true

require "spec_helper"

module Decidim::Meetings
  describe JoinMeeting do
    subject { described_class.new(meeting, registration_form) }

    let(:organization) { create(:organization) }
    let(:participatory_process) { create(:participatory_process, organization:) }
    let(:component) { create(:component, manifest_name: :meetings, participatory_space: participatory_process) }

    let(:registrations_enabled) { true }

    let(:meeting) do
      create(:meeting,
             component:,
             registrations_enabled:,
             available_slots: 0,
             questionnaire: nil)
    end

    let(:user_group) { create(:user_group) }

    let(:form_params) do
      {
        user_group_id: user_group.id
      }
    end

    let(:user) { create(:user, :confirmed, organization:, notifications_sending_frequency: "real_time") }
    let(:registration_form) do
      Decidim::Meetings::JoinMeetingForm.from_params(
        form_params
      ).with_context(
        current_user: user
      )
    end

    context "when everything is ok" do
      it "broadcasts ok" do
        expect { subject.call }.to broadcast(:ok)
      end

      it "sends an email confirming the registration" do
        perform_enqueued_jobs { subject.call }

        expect(ActionMailer::Base.deliveries.count).to eq(3)
        email = emails.first
        email_body = email_body(emails.first)
        last_registration = Registration.last
        expect(email.subject).to include("Confirmation instructions")
        expect(email_body).to include(last_registration.code)

        attachment = email.attachments.first
        expect(attachment.read.length).to be_positive
        expect(attachment.mime_type).to eq("text/calendar")
        expect(attachment.filename).to match(/meeting-calendar-info.ics/)
      end
    end

    context "when notifications are disabled" do
      before do
        allow(Decidim::Civicrm).to receive(:send_meeting_registration_notifications).and_return(false)
      end

      it "broadcasts ok" do
        expect { subject.call }.to broadcast(:ok)
      end

      it "do not send an email confirming the registration" do
        perform_enqueued_jobs { subject.call }

        expect(ActionMailer::Base.deliveries.count).to eq(2)
      end
    end
  end
end
