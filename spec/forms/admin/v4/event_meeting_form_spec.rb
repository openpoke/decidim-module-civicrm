# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim::Civicrm
  module Admin
    describe EventMeetingForm do
      subject { described_class.from_params(attributes) }

      include_context "with stubs example api #{Decidim::Civicrm::Api.available_versions[:v4]}"

      let(:data) { JSON.parse(file_fixture("v4/event_valid_response.json").read) }

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
            "entity" => "Event",
            "action" => "get",
            "version" => 4,
            "count" => 0,
            "countFetched" => 0,
            "countMatched" => 0
          }
        end

        it { is_expected.to be_invalid }
      end
    end
  end
end
