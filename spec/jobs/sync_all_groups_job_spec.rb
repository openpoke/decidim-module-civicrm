# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim::Civicrm
  describe SyncAllGroupsJob do
    subject { described_class }

    include_context "with stubs example api"

    let(:data) { JSON.parse(file_fixture("list_groups_valid_response.json").read) }
    let(:organization) { create :organization }

    it "creates groups" do
      expect { subject.perform_now(organization.id) }.to change(Group, :count).by(2)
      expect(Group.pluck(:civicrm_group_id)).to match_array([1, 2])
    end

    context "when there are groups to delete" do
      let!(:group) { create :civicrm_group, organization: organization, civicrm_group_id: 3 }

      it "deletes the groups" do
        expect(Group.pluck(:civicrm_group_id)).to match_array([3])
        expect { subject.perform_now(organization.id) }.to change(Group, :count).from(1).to(2)
        expect(Group.pluck(:civicrm_group_id)).to match_array([1, 2])
      end
    end

    context "when there are groups from other organizations" do
      let(:other_organization) { create :organization }
      let!(:group) { create :civicrm_group, organization: organization, civicrm_group_id: 3 }
      let!(:other_group) { create :civicrm_group, organization: other_organization, civicrm_group_id: 4, marked_for_deletion: true }

      it "deletes only events from this organization" do
        expect(Group.pluck(:civicrm_group_id)).to match_array([3, 4])
        expect { subject.perform_now(organization.id) }.to change(Group, :count).from(2).to(3)
        expect(Group.pluck(:civicrm_group_id)).to match_array([1, 2, 4])
      end
    end
  end
end
