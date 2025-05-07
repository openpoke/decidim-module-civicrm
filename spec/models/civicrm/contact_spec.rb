# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim::Civicrm
  describe Contact do
    subject { described_class.new(organization:, user:, civicrm_contact_id: 1) }

    let!(:organization) { create(:organization) }
    let!(:user) { create(:user, organization:) }

    it { is_expected.to be_valid }

    context "when civicrm_contact_id is already taken" do
      context "when contact belongs to the same organization" do
        let!(:contact) { create(:civicrm_contact, organization:, civicrm_contact_id: 1) }

        it { is_expected.not_to be_valid }
      end

      context "when contact belongs to another organization" do
        let!(:contact) { create(:civicrm_contact, civicrm_contact_id: 1) }

        it { is_expected.to be_valid }
      end
    end

    context "when user is already taken" do
      context "when contact belongs to the same organization" do
        let!(:contact) { create(:civicrm_contact, organization:, user:) }

        it { is_expected.not_to be_valid }
      end

      context "when contact belongs to another organization" do
        let!(:contact) { create(:civicrm_contact, user:) }

        it { is_expected.not_to be_valid }
      end
    end
  end

  context "when rebuilding the contact" do
    include_context "with stubs example api v4"

    let(:data) { JSON.parse(file_fixture("v4/find_contact_valid_response.json").read) }
    let(:organization) { create(:organization) }
    let(:user) { create(:user, organization:) }
    let!(:contact) { create(:civicrm_contact, user:, organization:, civicrm_contact_id: data["values"].first["id"], membership_types: [1]) }

    it "rebuilds the contact" do
      expect(contact.extra["display_name"]).not_to eq("Roberto Abela Serra")
      expect { contact.rebuild! }.to change(contact, :membership_types).to([3, 4])
      expect(contact.extra["display_name"]).to eq("Roberto Abela Serra")
    end
  end
end
