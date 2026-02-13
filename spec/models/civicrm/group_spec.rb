# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  describe Group do
    subject { described_class.new(organization:, civicrm_group_id: 1, title: "Group") }

    let!(:organization) { create(:organization) }

    it { is_expected.to be_valid }

    describe "#last_sync" do
      let!(:group) { create(:civicrm_group, organization: organization) }

      context "when group has memberships" do
        # rubocop:disable Rails/SkipsModelValidations
        let!(:old_membership) do
          create(:civicrm_group_membership, group: group, contact: nil,
                                            civicrm_contact_id: 1).tap { |m| m.update_column(:updated_at, 2.days.ago) }
        end
        let!(:new_membership) do
          create(:civicrm_group_membership, group: group, contact: nil,
                                            civicrm_contact_id: 2).tap { |m| m.update_column(:updated_at, 1.hour.ago) }
        end
        # rubocop:enable Rails/SkipsModelValidations

        it "returns the most recent updated_at" do
          expect(group.last_sync).to be_within(1.second).of(1.hour.ago)
        end
      end

      context "when group has no memberships" do
        it "returns nil" do
          expect(group.last_sync).to be_nil
        end
      end
    end

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
