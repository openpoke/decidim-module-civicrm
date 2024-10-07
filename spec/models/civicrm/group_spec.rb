# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  describe Group do
    subject { described_class.new(organization:, civicrm_group_id: 1, title: "Group") }

    let!(:organization) { create(:organization) }

    it { is_expected.to be_valid }

    context "when civicrm_group_id is already taken" do
      context "when group belongs to the same organization" do
        let!(:group) { create(:civicrm_group, organization:, civicrm_group_id: 1) }

        it { is_expected.not_to be_valid }
      end

      context "when group belongs to another organization" do
        let!(:group) { create(:civicrm_group, civicrm_group_id: 1) }

        it { is_expected.to be_valid }
      end
    end
  end
end
