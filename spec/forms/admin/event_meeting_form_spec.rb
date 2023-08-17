# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim::Civicrm
  module Admin
    describe EventMeetingForm do
      subject { described_class.from_params(attributes) }

      include_context "with stubs example api"

      let(:data) { JSON.parse(file_fixture("find_event_valid_response.json").read) }

      let(:attributes) do
        {
          "event_meeting" => {
            "decidim_meeting_id" => decidim_meeting_id,
            "civicrm_event_id" => event_id,
            "redirect_url" => redirect_url,
            "redirect_active" => active
          }
        }
      end
      let(:meeting) { create :meeting }
      let(:decidim_meeting_id) { meeting.id }
      let(:redirect_url) { ::Faker::Internet.url }
      let(:active) { true }
      let(:event_id) { 123 }

      context "when everything is OK" do
        it { is_expected.to be_valid }
      end

      context "when no meeting" do
        let(:decidim_meeting_id) { nil }

        it { is_expected.to be_invalid }
      end

      context "when no url" do
        let(:redirect_url) { nil }

        it { is_expected.to be_valid }

        context "and no civicrm_event_id" do
          let(:event_id) { nil }

          it { is_expected.to be_invalid }
        end
      end

      context "when no event_id" do
        let(:event_id) { nil }

        it { is_expected.to be_valid }

        context "and no url" do
          let(:redirect_url) { nil }

          it { is_expected.to be_invalid }
        end
      end

      context "when civicrm event does not exist" do
        let(:data) do
          {
            "values" => [],
            "is_error" => 1,
            "version" => 3,
            "count" => 0
          }
        end

        it { is_expected.to be_invalid }
      end
    end
  end
end
