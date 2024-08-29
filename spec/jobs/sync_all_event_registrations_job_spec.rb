# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  describe SyncAllEventRegistrationsJob do
    subject { described_class }

    let(:meeting) { create(:meeting) }
    let(:organization) { meeting.organization }
    let!(:event) { create(:civicrm_event_meeting, meeting:, organization:) }

    it "enqueues individual jobs" do
      expect { subject.perform_now(organization) }.to have_enqueued_job(SyncEventRegistrationsJob).with(event.id)
    end

    context "when other organizations event" do
      let(:other_meeting) { create(:meeting) }
      let(:other_organization) { other_meeting.organization }
      let!(:other_event) { create(:civicrm_event_meeting, meeting: other_meeting, organization: other_organization) }

      it "does not enqueue jobs" do
        expect { subject.perform_now(organization) }.not_to have_enqueued_job(SyncEventRegistrationsJob).with(other_event.id)
      end
    end
  end
end
