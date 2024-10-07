# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  describe EventMeeting do
    subject { described_class.new(organization:, meeting:, redirect_url: url, redirect_active: active, civicrm_event_id: event_id) }

    let!(:meeting) { create(:meeting) }
    let(:organization) { meeting.organization }
    let(:url) { ::Faker::Internet.url }
    let(:active) { true }
    let(:event_id) { 1234 }

    it { is_expected.to be_valid }

    context "when no organization" do
      let(:organization) { nil }

      it { is_expected.not_to be_valid }
    end

    context "when no event_id" do
      let(:event_id) { nil }

      it { is_expected.to be_valid }

      context "and there's no redirect_url" do
        let(:url) { nil }

        it { is_expected.not_to be_valid }
      end
    end

    context "when no meeting" do
      let(:meeting) { nil }
      let(:organization) { create(:organization) }

      it { is_expected.to be_valid }
    end

    context "when no meeting and no event_id" do
      let(:event_id) { nil }
      let(:meeting) { nil }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_valid }

      context "and there's no redirect_url" do
        let(:url) { nil }

        it { is_expected.not_to be_valid }
      end
    end

    context "when meeting organization is different than organization" do
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_valid }
    end

    shared_examples "duplicated event" do
      it { is_expected.not_to be_valid }

      it "can't be created" do
        expect { subject.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    shared_examples "saved event" do
      it { is_expected.to be_valid }

      it "can be created" do
        expect { subject.save! }.not_to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when event exists" do
      let(:event_organization) { organization }
      let!(:event) { create(:civicrm_event_meeting, organization: event_organization, meeting:, redirect_url: url, redirect_active: active, civicrm_event_id: event_id) }

      it_behaves_like "duplicated event"

      context "and no meeting" do
        let(:meeting) { nil }
        let(:organization) { create(:organization) }

        it_behaves_like "duplicated event"

        context "and another organization" do
          let(:meeting) { nil }
          let(:event_organization) { create(:organization) }

          it_behaves_like "saved event"
        end
      end
    end
  end
end
