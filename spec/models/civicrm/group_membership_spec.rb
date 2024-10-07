# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  describe GroupMembership do
    subject { group_membership }

    let!(:organization) { create(:organization) }
    let(:group) { create(:civicrm_group, civicrm_group_id: 123, organization:) }
    let(:contact) { create(:civicrm_contact, organization:) }
    let(:another_contact) { create(:civicrm_contact) }
    let!(:group_membership) { create(:civicrm_group_membership, contact:, group:) }

    it { is_expected.to be_valid }

    context "when there's no model contact yet" do
      let!(:group_membership) { create(:civicrm_group_membership, contact: nil, civicrm_contact_id: civi_id, group:) }
      let(:civi_id) { 1234 }

      it { is_expected.to be_valid }

      context "and civi_id is already taken" do
        subject { another_group_membership }

        let(:another_group_membership) { build(:civicrm_group_membership, contact: nil, civicrm_contact_id: civi_id, group: another_group) }
        let(:another_group) { group }

        it { is_expected.not_to be_valid }

        context "when group is different" do
          let(:another_group) { create(:civicrm_group, civicrm_group_id: 234, organization:) }

          it { is_expected.to be_valid }
        end
      end
    end

    context "when contact and group are already taken" do
      subject { another_group_membership }

      context "when they belong to the same organization" do
        let(:another_group_membership) { build(:civicrm_group_membership, contact:, group:) }

        it { is_expected.not_to be_valid }
      end

      context "when contact and group belong to different organizations" do
        let(:another_group_membership) { build(:civicrm_group_membership, contact: another_contact, group:) }

        it { is_expected.not_to be_valid }
      end
    end
  end
end
