# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  describe EventRegistration do
    subject { described_class.new(meeting_registration: registration, event_meeting: event, civicrm_event_registration_id: registration_id) }

    let(:event) { create(:civicrm_event_meeting, meeting:, organization: meeting.organization) }
    let(:registration) { create(:registration, meeting:) }
    let(:meeting) { create(:meeting) }
    let(:registration_id) { 1234 }

    it { is_expected.to be_valid }

    context "when no registration" do
      let(:registration) { nil }

      it { is_expected.to be_valid }
    end

    context "when no registration_id" do
      let(:registration_id) { nil }

      it { is_expected.not_to be_valid }
    end

    context "when no event" do
      let(:event) { nil }
      let(:registration) { create(:registration) }

      it { is_expected.not_to be_valid }
    end

    context "when event registration is in a different event" do
      let(:registration) { create(:registration) }

      it { is_expected.not_to be_valid }
    end
  end
end
