# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim::Civicrm
  describe SyncMembershipTypesJob do
    subject { described_class }

    include_context "with stubs example api v4"

    let(:data) { JSON.parse(file_fixture("v4/list_membership_types_valid_response.json").read) }
    let(:organization) { create(:organization) }

    it "creates membership types" do
      expect { subject.perform_now(organization.id) }.to change(MembershipType, :count).by(4)
      expect(MembershipType.pluck(:civicrm_membership_type_id)).to contain_exactly(1, 2, 3, 4)
    end

    context "when there are membership types to delete" do
      let!(:membership_type) { create(:civicrm_membership_type, organization:, civicrm_membership_type_id: 4) }

      it "deletes the membership types" do
        expect(MembershipType.pluck(:civicrm_membership_type_id)).to contain_exactly(4)
        expect { subject.perform_now(organization.id) }.to change(MembershipType, :count).from(1).to(4)
        expect(MembershipType.pluck(:civicrm_membership_type_id)).to contain_exactly(1, 2, 3, 4)
      end
    end

    context "when there are membership types from other organizations" do
      let(:other_organization) { create(:organization) }
      let!(:membership_type) { create(:civicrm_membership_type, organization: other_organization, civicrm_membership_type_id: 5, marked_for_deletion: true) }

      it "deletes only events from this organization" do
        expect(MembershipType.pluck(:civicrm_membership_type_id)).to contain_exactly(5)
        expect { subject.perform_now(organization.id) }.to change(MembershipType, :count).from(1).to(5)
        expect(MembershipType.pluck(:civicrm_membership_type_id)).to contain_exactly(1, 2, 3, 4, 5)
      end
    end

    context "with pagination" do
      let(:page_size) { 2 }
      let(:first_page_data) do
        {
          "values" => data["values"][0..1],
          "entity" => "MembershipType",
          "action" => "get",
          "count" => 4,
          "countFetched" => 2,
          "countMatched" => 4
        }
      end

      let(:api_returns) do
        [
          {
            status: 200,
            body: first_page_data.to_json,
            headers: {}
          }
        ]
      end

      before do
        allow(Decidim::Civicrm).to receive(:api_records_by_page).and_return(page_size)
      end

      it "processes first page and schedules next page" do
        expect { subject.perform_now(organization.id, page: 0) }.to change(MembershipType, :count).by(2)
        expect(MembershipType.pluck(:civicrm_membership_type_id)).to contain_exactly(1, 2)
        expect(subject).to have_been_enqueued.with(organization.id, page: 1).on_queue("default")
      end
    end
  end
end
