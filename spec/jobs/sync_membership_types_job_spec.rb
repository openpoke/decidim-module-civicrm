# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim::Civicrm
  describe SyncMembershipTypesJob do
    subject { described_class }

    include_context "with stubs example api"

    let(:data) { JSON.parse(file_fixture("list_membership_types_valid_response.json").read) }
    let(:organization) { create(:organization) }

    it "creates membership types" do
      expect { subject.perform_now(organization.id) }.to change(MembershipType, :count).by(3)
      expect(MembershipType.pluck(:civicrm_membership_type_id)).to contain_exactly(1, 2, 3)
    end

    context "when there are membership types to delete" do
      let!(:membership_type) { create(:civicrm_membership_type, organization:, civicrm_membership_type_id: 4) }

      it "deletes the membership types" do
        expect(MembershipType.pluck(:civicrm_membership_type_id)).to contain_exactly(4)
        expect { subject.perform_now(organization.id) }.to change(MembershipType, :count).from(1).to(3)
        expect(MembershipType.pluck(:civicrm_membership_type_id)).to contain_exactly(1, 2, 3)
      end
    end

    context "when there are membership types from other organizations" do
      let(:other_organization) { create(:organization) }
      let!(:membership_type) { create(:civicrm_membership_type, organization: other_organization, civicrm_membership_type_id: 4, marked_for_deletion: true) }

      it "deletes only events from this organization" do
        expect(MembershipType.pluck(:civicrm_membership_type_id)).to contain_exactly(4)
        expect { subject.perform_now(organization.id) }.to change(MembershipType, :count).from(1).to(4)
        expect(MembershipType.pluck(:civicrm_membership_type_id)).to contain_exactly(1, 2, 3, 4)
      end
    end
  end
end
