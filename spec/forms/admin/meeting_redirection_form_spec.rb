# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  module Admin
    describe MeetingRedirectionForm do
      subject { described_class.from_params(attributes) }

      let(:attributes) do
        {
          "meeting_redirection" => {
            "decidim_meeting_id" => decidim_meeting_id,
            "url" => url,
            "active" => active
          }
        }
      end
      let(:meeting) { create :meeting }
      let(:decidim_meeting_id) { meeting.id }
      let(:url) { ::Faker::Internet.url }
      let(:active) { true }

      context "when everything is OK" do
        it { is_expected.to be_valid }
      end

      context "when no meeting" do
        let(:decidim_meeting_id) { nil }

        it { is_expected.to be_invalid }
      end

      context "when no url" do
        let(:url) { nil }

        it { is_expected.to be_invalid }
      end
    end
  end
end
