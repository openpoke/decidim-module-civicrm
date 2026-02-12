# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  describe SyncAllEventRegistrationsJob do
    subject { described_class }

    let(:meeting) { create(:meeting) }
    let(:organization) { meeting.organization }
    let!(:event) { create(:civicrm_event_meeting, meeting:, organization:) }

    before do
      allow(SyncEventRegistrationsJob).to receive(:perform_now)
      allow(subject).to receive(:sleep)
    end

    it "performs individual jobs" do
      subject.perform_now(organization)
      expect(SyncEventRegistrationsJob).to have_received(:perform_now).with(event.id)
    end

    context "when other organizations event" do
      let(:other_meeting) { create(:meeting) }
      let(:other_organization) { other_meeting.organization }
      let!(:other_event) { create(:civicrm_event_meeting, meeting: other_meeting, organization: other_organization) }

      it "does not perform jobs for other organization" do
        subject.perform_now(organization)
        expect(SyncEventRegistrationsJob).not_to have_received(:perform_now).with(other_event.id)
      end
    end
  end
end
