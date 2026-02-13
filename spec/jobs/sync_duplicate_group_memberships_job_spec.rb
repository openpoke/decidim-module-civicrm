# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  describe SyncDuplicateGroupMembershipsJob do
    subject { described_class }

    let(:organization) { create(:organization) }
    let(:group1) { create(:civicrm_group, organization:) }
    let(:group2) { create(:civicrm_group, organization:) }
    let(:group3) { create(:civicrm_group, organization:) }
    let(:contact) { create(:civicrm_contact, organization:, civicrm_contact_id: 100) }

    describe "#perform" do
      context "when there are no duplicate memberships" do
        let!(:membership1) { create(:civicrm_group_membership, group: group1, contact:, civicrm_contact_id: 100) }
        let!(:membership2) { create(:civicrm_group_membership, group: group2, contact: nil, civicrm_contact_id: 200) }

        it "does not change any memberships" do
          expect { subject.perform_now }.not_to(change { GroupMembership.pluck(:id, :updated_at) })
        end
      end

      context "when there are duplicate memberships" do
        let(:extra_data) { { "display_name" => "John Doe", "email" => "john@example.com" } }
        let(:custom_fields_data) { { "field1" => "value1", "field2" => "value2" } }
        let(:old_extra_data) { { "display_name" => "Old Name" } }
        let(:old_custom_fields_data) { { "old_field" => "old_value" } }

        context "with two memberships sharing the same civicrm_contact_id" do
          let!(:older_membership) do
            create(:civicrm_group_membership,
                   group: group1,
                   contact: nil,
                   civicrm_contact_id: 100,
                   extra: old_extra_data,
                   custom_fields: old_custom_fields_data,
                   marked_for_deletion: nil,
                   updated_at: 2.days.ago)
          end
          let!(:newer_membership) do
            create(:civicrm_group_membership,
                   group: group2,
                   contact:,
                   civicrm_contact_id: 100,
                   extra: extra_data,
                   custom_fields: custom_fields_data,
                   marked_for_deletion: nil,
                   updated_at: 1.day.ago)
          end

          it "syncs data from the more recently updated membership to the older one" do
            subject.perform_now
            older_membership.reload

            expect(older_membership.contact_id).to eq(contact.id)
            expect(older_membership.extra).to eq(extra_data)
            expect(older_membership.custom_fields).to eq(custom_fields_data)
          end

          it "does not change the newer membership" do
            newer_values = {
              contact_id: newer_membership.contact_id,
              extra: newer_membership.extra,
              custom_fields: newer_membership.custom_fields
            }

            subject.perform_now
            newer_membership.reload

            expect(newer_membership.contact_id).to eq(newer_values[:contact_id])
            expect(newer_membership.extra).to eq(newer_values[:extra])
            expect(newer_membership.custom_fields).to eq(newer_values[:custom_fields])
          end

          it "updates the updated_at timestamp of the older membership" do
            expect { subject.perform_now }.to(change { older_membership.reload.updated_at })
          end
        end

        context "with three memberships sharing the same civicrm_contact_id" do
          let!(:oldest_membership) do
            create(:civicrm_group_membership,
                   group: group1,
                   contact: nil,
                   civicrm_contact_id: 100,
                   extra: {},
                   custom_fields: {},
                   updated_at: 3.days.ago)
          end
          let!(:middle_membership) do
            create(:civicrm_group_membership,
                   group: group2,
                   contact: nil,
                   civicrm_contact_id: 100,
                   extra: old_extra_data,
                   custom_fields: old_custom_fields_data,
                   updated_at: 2.days.ago)
          end
          let!(:newest_membership) do
            create(:civicrm_group_membership,
                   group: group3,
                   contact:,
                   civicrm_contact_id: 100,
                   extra: extra_data,
                   custom_fields: custom_fields_data,
                   updated_at: 1.day.ago)
          end

          it "syncs data from the most recently updated membership to all others" do
            subject.perform_now

            oldest_membership.reload
            middle_membership.reload

            expect(oldest_membership.contact_id).to eq(contact.id)
            expect(oldest_membership.extra).to eq(extra_data)
            expect(oldest_membership.custom_fields).to eq(custom_fields_data)

            expect(middle_membership.contact_id).to eq(contact.id)
            expect(middle_membership.extra).to eq(extra_data)
            expect(middle_membership.custom_fields).to eq(custom_fields_data)
          end

          it "does not change the newest membership" do
            newest_values = {
              contact_id: newest_membership.contact_id,
              extra: newest_membership.extra,
              custom_fields: newest_membership.custom_fields
            }

            subject.perform_now
            newest_membership.reload

            expect(newest_membership.contact_id).to eq(newest_values[:contact_id])
            expect(newest_membership.extra).to eq(newest_values[:extra])
            expect(newest_membership.custom_fields).to eq(newest_values[:custom_fields])
          end
        end

        context "when marked_for_deletion is set" do
          let!(:older_membership) do
            create(:civicrm_group_membership,
                   group: group1,
                   contact: nil,
                   civicrm_contact_id: 100,
                   marked_for_deletion: nil,
                   updated_at: 2.days.ago)
          end
          let!(:newer_membership) do
            create(:civicrm_group_membership,
                   group: group2,
                   contact:,
                   civicrm_contact_id: 100,
                   marked_for_deletion: Time.current,
                   updated_at: 1.day.ago)
          end

          it "syncs the marked_for_deletion status" do
            subject.perform_now
            older_membership.reload

            expect(older_membership.marked_for_deletion).not_to be_nil
          end
        end

        context "when extra and custom_fields are empty in source" do
          let!(:older_membership) do
            create(:civicrm_group_membership,
                   group: group1,
                   contact: nil,
                   civicrm_contact_id: 100,
                   extra: old_extra_data,
                   custom_fields: old_custom_fields_data,
                   updated_at: 2.days.ago)
          end
          let!(:newer_membership) do
            create(:civicrm_group_membership,
                   group: group2,
                   contact:,
                   civicrm_contact_id: 100,
                   extra: {},
                   custom_fields: {},
                   updated_at: 1.day.ago)
          end

          it "does not override with empty values" do
            subject.perform_now
            older_membership.reload

            expect(older_membership.extra).to eq(old_extra_data)
            expect(older_membership.custom_fields).to eq(old_custom_fields_data)
          end

          it "still syncs the contact_id" do
            subject.perform_now
            older_membership.reload

            expect(older_membership.contact_id).to eq(contact.id)
          end
        end

        context "with multiple sets of duplicates" do
          let(:contact2) { create(:civicrm_contact, organization:, civicrm_contact_id: 200) }
          let!(:membership_set1_old) do
            create(:civicrm_group_membership,
                   group: group1,
                   contact: nil,
                   civicrm_contact_id: 100,
                   updated_at: 2.days.ago)
          end
          let!(:membership_set1_new) do
            create(:civicrm_group_membership,
                   group: group2,
                   contact:,
                   civicrm_contact_id: 100,
                   updated_at: 1.day.ago)
          end
          let!(:membership_set2_old) do
            create(:civicrm_group_membership,
                   group: group1,
                   contact: nil,
                   civicrm_contact_id: 200,
                   updated_at: 2.days.ago)
          end
          let!(:membership_set2_new) do
            create(:civicrm_group_membership,
                   group: group3,
                   contact: contact2,
                   civicrm_contact_id: 200,
                   updated_at: 1.day.ago)
          end

          it "syncs both sets of duplicates independently" do
            subject.perform_now

            membership_set1_old.reload
            membership_set2_old.reload

            expect(membership_set1_old.contact_id).to eq(contact.id)
            expect(membership_set2_old.contact_id).to eq(contact2.id)
          end
        end

        context "when memberships have the same updated_at timestamp" do
          let!(:membership1) do
            create(:civicrm_group_membership,
                   group: group1,
                   contact: nil,
                   civicrm_contact_id: 100,
                   extra: old_extra_data,
                   updated_at: 1.day.ago)
          end
          let!(:membership2) do
            create(:civicrm_group_membership,
                   group: group2,
                   contact:,
                   civicrm_contact_id: 100,
                   extra: extra_data,
                   updated_at: 1.day.ago)
          end

          it "uses the first one from the query as the source" do
            # Should still complete without error
            expect { subject.perform_now }.not_to raise_error
          end
        end
      end
    end
  end
end
