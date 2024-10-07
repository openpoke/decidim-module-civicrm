# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  describe ContactForm do
    subject { described_class.from_params(attributes) }

    let(:attributes) do
      {
        "contact" => {
          "decidim_organization_id" => decidim_organization_id,
          "decidim_user_id" => decidim_user_id,
          "civicrm_contact_id" => civicrm_contact_id
        }
      }
    end
    let(:user) { create(:user) }
    let(:decidim_organization_id) { user.organization.id }
    let(:decidim_user_id) { user.id }
    let(:civicrm_contact_id) { 123 }

    context "when everything is OK" do
      it { is_expected.to be_valid }
    end

    context "when no organization" do
      let(:decidim_organization_id) { nil }

      it { is_expected.not_to be_valid }
    end

    context "when no user" do
      let(:decidim_user_id) { nil }

      it { is_expected.not_to be_valid }
    end

    context "when no civicrm" do
      let(:civicrm_contact_id) { nil }

      it { is_expected.not_to be_valid }
    end
  end
end
