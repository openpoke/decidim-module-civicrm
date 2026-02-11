# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim::Civicrm
  describe SyncAllGroupsJob do
    subject { described_class }

    include_context "with stubs example api v4"

    let(:data) { JSON.parse(file_fixture("v4/list_groups_valid_response.json").read) }
    let(:organization) { create(:organization) }

    it "creates groups" do
      expect { subject.perform_now(organization.id) }.to change(Group, :count).by(2)
      expect(Group.pluck(:civicrm_group_id)).to contain_exactly(1, 2)
    end

    context "when there are groups to delete" do
      let!(:group) { create(:civicrm_group, organization:, civicrm_group_id: 3) }

      it "deletes the groups" do
        expect(Group.pluck(:civicrm_group_id)).to contain_exactly(3)
        expect { subject.perform_now(organization.id) }.to change(Group, :count).from(1).to(2)
        expect(Group.pluck(:civicrm_group_id)).to contain_exactly(1, 2)
      end
    end

    context "when there are groups from other organizations" do
      let(:other_organization) { create(:organization) }
      let!(:group) { create(:civicrm_group, organization:, civicrm_group_id: 3) }
      let!(:other_group) { create(:civicrm_group, organization: other_organization, civicrm_group_id: 4, marked_for_deletion: true) }

      it "deletes only events from this organization" do
        expect(Group.pluck(:civicrm_group_id)).to contain_exactly(3, 4)
        expect { subject.perform_now(organization.id) }.to change(Group, :count).from(2).to(3)
        expect(Group.pluck(:civicrm_group_id)).to contain_exactly(1, 2, 4)
      end
    end

    context "with pagination" do
      let(:page_size) { 1 }
      let(:first_page_data) do
        {
          "values" => [
            {
              "id" => "1",
              "name" => "Administrators",
              "title" => "Administrators",
              "description" => "The users in this group are assigned admin privileges.",
              "group_type" => ["1"]
            }
          ],
          "entity" => "Group",
          "action" => "get",
          "count" => 2,
          "countFetched" => 1,
          "countMatched" => 2
        }
      end

      let(:second_page_data) do
        {
          "values" => [
            {
              "id" => "2",
              "name" => "Another_Group",
              "title" => "Another Group",
              "description" => "...",
              "group_type" => ["2"]
            }
          ],
          "entity" => "Group",
          "action" => "get",
          "count" => 2,
          "countFetched" => 1,
          "countMatched" => 2
        }
      end

      before do
        allow(Decidim::Civicrm).to receive(:api_records_by_page).and_return(page_size)
        stub_request(:post, /api\.example\.org/)
          .with(body: hash_including("params" => hash_including("offset" => 0)))
          .to_return(status: 200, body: first_page_data.to_json, headers: {})
        stub_request(:post, /api\.example\.org/)
          .with(body: hash_including("params" => hash_including("offset" => 1)))
          .to_return(status: 200, body: second_page_data.to_json, headers: {})
      end

      it "processes first page and schedules next page" do
        expect { subject.perform_now(organization.id, page: 0) }.to change(Group, :count).by(1)
        expect(Group.pluck(:civicrm_group_id)).to contain_exactly(1)
        expect(subject).to have_been_enqueued.with(organization.id, page: 1).on_queue("default")
      end

      it "processes second page and completes cleanup" do
        create(:civicrm_group, organization:, civicrm_group_id: 1)
        expect { subject.perform_now(organization.id, page: 1) }.to change(Group, :count).by(1)
        expect(Group.pluck(:civicrm_group_id)).to contain_exactly(1, 2)
      end

      it "processes all pages sequentially" do
        subject.perform_now(organization.id, page: 0)
        subject.perform_now(organization.id, page: 1)
        expect(Group.count).to eq(2)
        expect(Group.pluck(:civicrm_group_id)).to contain_exactly(1, 2)
      end
    end
  end
end
