# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  describe MembershipType do
    subject { described_class.new(organization:, civicrm_membership_type_id: 1) }

    let!(:organization) { create(:organization) }

    it { is_expected.to be_valid }

    context "when civicrm_membership_type_id is already taken" do
      context "when membership_type belongs to the same organization" do
        let!(:membership_type) { create(:civicrm_membership_type, organization:, civicrm_membership_type_id: 1) }

        it { is_expected.not_to be_valid }
      end

      context "when membership_type belongs to another organization" do
        let!(:membership_type) { create(:civicrm_membership_type, civicrm_membership_type_id: 1) }

        it { is_expected.to be_valid }
      end
    end
  end
end
