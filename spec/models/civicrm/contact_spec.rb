# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  describe Contact do
    subject { described_class.new(organization: organization, user: user, civicrm_contact_id: 1) }

    let!(:organization) { create(:organization) }
    let!(:user) { create(:user, organization: organization) }

    it { is_expected.to be_valid }

    context "when civicrm_contact_id is already taken" do
      context "when contact belongs to the same organization" do
        let!(:contact) { create(:civicrm_contact, organization: organization, civicrm_contact_id: 1) }

        it { is_expected.not_to be_valid }
      end

      context "when contact belongs to another organization" do
        let!(:contact) { create(:civicrm_contact, civicrm_contact_id: 1) }

        it { is_expected.to be_valid }
      end
    end

    context "when user is already taken" do
      context "when contact belongs to the same organization" do
        let!(:contact) { create(:civicrm_contact, organization: organization, user: user) }

        it { is_expected.not_to be_valid }
      end

      context "when contact belongs to another organization" do
        let!(:contact) { create(:civicrm_contact, user: user) }

        it { is_expected.not_to be_valid }
      end
    end
  end

  context "when rebuilding the contact" do
    include_context "with stubs example api"

    let(:data) { JSON.parse(file_fixture("find_contact_valid_response.json").read) }
    let(:organization) { create(:organization) }
    let(:user) { create(:user, organization: organization) }
    let!(:contact) { create :civicrm_contact, user: user, organization: organization, civicrm_contact_id: data["id"], membership_types: [1] }

    it "rebuilds the contact" do
      expect(contact.extra["display_name"]).not_to eq("Sir Arthur Dent")
      expect { contact.rebuild! }.to change(contact, :membership_types).to([2, 3])
      expect(contact.extra["display_name"]).to eq("Sir Arthur Dent")
    end
  end
end
