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

    describe "scopes" do
      let(:contact2) { create(:civicrm_contact, organization:) }
      let!(:membership_with_custom_fields) { create(:civicrm_group_membership, group:, contact: nil, civicrm_contact_id: 111, custom_fields: { "field1" => "value1" }) }
      let!(:membership_without_custom_fields) { create(:civicrm_group_membership, group:, contact: nil, civicrm_contact_id: 222, custom_fields: {}) }
      let!(:membership_with_contact) { create(:civicrm_group_membership, group:, contact: contact2) }
      let!(:membership_without_contact) { create(:civicrm_group_membership, group:, contact: nil, civicrm_contact_id: 999) }

      describe ".with_custom_fields" do
        it "returns memberships with populated custom fields" do
          expect(described_class.with_custom_fields).to include(membership_with_custom_fields)
          expect(described_class.with_custom_fields).not_to include(membership_without_custom_fields)
        end
      end

      describe ".without_custom_fields" do
        it "returns memberships without custom fields" do
          expect(described_class.without_custom_fields).to include(membership_without_custom_fields)
          expect(described_class.without_custom_fields).not_to include(membership_with_custom_fields)
        end
      end

      describe ".with_decidim_user" do
        it "returns memberships with contact" do
          expect(described_class.with_decidim_user).to include(membership_with_contact)
          expect(described_class.with_decidim_user).not_to include(membership_without_contact)
        end
      end

      describe ".without_decidim_user" do
        it "returns memberships without contact" do
          expect(described_class.without_decidim_user).to include(membership_without_contact)
          expect(described_class.without_decidim_user).not_to include(membership_with_contact)
        end
      end

      describe ".id_or_name_cont" do
        let!(:membership_by_id) { create(:civicrm_group_membership, group:, contact: nil, civicrm_contact_id: 12_345) }
        let!(:membership_by_name) { create(:civicrm_group_membership, group:, contact: nil, civicrm_contact_id: 54_321, extra: { "display_name" => "John Doe" }) }

        context "when searching by numeric ID" do
          it "finds by exact civicrm_contact_id" do
            expect(described_class.id_or_name_cont("12345")).to include(membership_by_id)
            expect(described_class.id_or_name_cont("12345")).not_to include(membership_by_name)
          end
        end

        context "when searching by name" do
          it "finds by display_name pattern" do
            expect(described_class.id_or_name_cont("John")).to include(membership_by_name)
            expect(described_class.id_or_name_cont("John")).not_to include(membership_by_id)
          end
        end
      end
    end

    describe "#compact_custom_fields" do
      context "when custom_fields has blank values" do
        let!(:group_membership) { create(:civicrm_group_membership, group:, contact: nil, civicrm_contact_id: 555, custom_fields: { "field1" => "value1", "field2" => "", "field3" => nil }) }

        it "returns only non-blank values" do
          expect(group_membership.compact_custom_fields).to eq({ "field1" => "value1" })
        end
      end
    end
  end
end
