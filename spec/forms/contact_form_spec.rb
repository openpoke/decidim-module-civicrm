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

    context "with custom_fields" do
      let(:attributes) do
        {
          "contact" => {
            "decidim_organization_id" => decidim_organization_id,
            "decidim_user_id" => decidim_user_id,
            "civicrm_contact_id" => civicrm_contact_id,
            "custom_fields" => custom_fields
          }
        }
      end
      let(:custom_fields) { { "Dades_comunes.Identificador_fiscal" => "12345678X" } }

      it { is_expected.to be_valid }

      it "stores custom_fields with symbol keys" do
        expect(subject.custom_fields[:"Dades_comunes.Identificador_fiscal"]).to eq("12345678X")
      end
    end

    context "without custom_fields" do
      it "defaults to empty hash" do
        expect(subject.custom_fields).to eq({})
      end
    end
  end
end
