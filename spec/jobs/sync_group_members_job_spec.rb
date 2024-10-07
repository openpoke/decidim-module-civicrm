# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim::Civicrm
  describe SyncGroupMembersJob do
    subject { described_class }

    include_context "with stubs example api"

    let(:return_data) do
      [{
        status: http_status,
        body: data1.to_json,
        headers: {}
      }, {
        status: http_status,
        body: data2.to_json,
        headers: {}
      }]
    end

    let(:data1) { JSON.parse(file_fixture("find_group_valid_response.json").read) }
    let(:data2) { JSON.parse(file_fixture("list_contacts_in_group_valid_response.json").read) }
    let!(:group) { create(:civicrm_group, civicrm_group_id: 1, organization:) }
    let(:organization) { create(:organization) }

    it "creates group memberships" do
      expect { subject.perform_now(group.id) }.to change(GroupMembership, :count).by(3)
      expect(GroupMembership.pluck(:civicrm_contact_id)).to contain_exactly(9999, 777, 6)
    end

    context "when there are group memberships to delete" do
      let(:contact) { create(:civicrm_contact, organization:, civicrm_contact_id: 10_001) }
      let!(:group_membership) { create(:civicrm_group_membership, group:, contact:, civicrm_contact_id: 10_001) }

      it "deletes group memberships" do
        expect { subject.perform_now(group.id) }.to change(GroupMembership, :count).from(1).to(3)
        expect(GroupMembership.pluck(:civicrm_contact_id)).to contain_exactly(9999, 777, 6)
      end

      context "and other group memberships are marked for deletion" do
        let(:other_group) { create(:civicrm_group, civicrm_group_id: 2, organization:) }
        let!(:other_group_membership) { create(:civicrm_group_membership, group: other_group, contact:, civicrm_contact_id: 10_002, marked_for_deletion: true) }

        it "deletes only group memberships not marked for deletion" do
          expect { subject.perform_now(group.id) }.to change(GroupMembership, :count).from(2).to(4)
          expect(GroupMembership.pluck(:civicrm_contact_id)).to contain_exactly(9999, 777, 6, 10_002)
        end
      end
    end

    context "when there are group memberships from other organizations" do
      let(:contact) { create(:civicrm_contact, organization:, civicrm_contact_id: 10_001) }
      let!(:group_membership) { create(:civicrm_group_membership, group:, contact:, civicrm_contact_id: 10_001) }
      let(:other_organization) { create(:organization) }
      let(:other_group) { create(:civicrm_group, civicrm_group_id: 1, organization: other_organization) }
      let(:other_contact) { create(:civicrm_contact, organization: other_organization, civicrm_contact_id: 10_002) }
      let!(:other_group_membership) { create(:civicrm_group_membership, group: other_group, contact: other_contact, civicrm_contact_id: 10_002) }

      it "deletes only events from this organization" do
        expect { subject.perform_now(group.id) }.to change(GroupMembership, :count).from(2).to(4)
        expect(GroupMembership.pluck(:civicrm_contact_id)).to contain_exactly(9999, 777, 6, 10_002)
      end
    end
  end
end
