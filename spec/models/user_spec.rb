# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe User do
    let!(:user) { create(:user) }
    let!(:organization) { user.organization }

    describe "#civicrm_identity?" do
      subject { user.civicrm_identity? }

      context "when user has a civicrm-provided identity" do
        let!(:identity) { create(:identity, user:, provider: Decidim::Civicrm::OMNIAUTH_PROVIDER_NAME) }

        it { is_expected.to be_truthy }
      end

      context "when user doesn't have a civicrm-provided identity" do
        let!(:identity) { create(:identity, user:, provider: "other") }

        it { is_expected.to be_falsey }
      end

      context "when user doesn't have an identity" do
        it { is_expected.to be_falsey }
      end
    end

    describe "#civicrm_identity" do
      subject { user.civicrm_identity }

      context "when user has a civicrm-provided identity" do
        let!(:identity) { create(:identity, user:, provider: Decidim::Civicrm::OMNIAUTH_PROVIDER_NAME) }

        it { is_expected.to be_a Decidim::Identity }
      end

      context "when user doesn't have a civicrm-provided identity" do
        let!(:identity) { create(:identity, user:, provider: "other") }

        it { is_expected.to be_nil }
      end

      context "when user doesn't have an identity" do
        it { is_expected.to be_nil }
      end
    end

    describe "#contact" do
      subject { user.contact }

      context "when user has a related civicrm contact" do
        let!(:contact) { create(:civicrm_contact, organization:, user:) }

        it { is_expected.to be_a Decidim::Civicrm::Contact }
      end
    end
  end
end
