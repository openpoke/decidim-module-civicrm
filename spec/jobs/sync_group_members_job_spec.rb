# frozen_string_literal: true

require "spec_helper"
require "decidim/civicrm/test/v4/shared_contexts"

module Decidim::Civicrm
  describe SyncGroupMembersJob do
    subject { described_class }

    include_context "with stubs example api v4"

    let(:api_returns) do
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

    let(:data1) { JSON.parse(file_fixture("v4/find_group_valid_response.json").read) }
    let(:data2) { JSON.parse(file_fixture("v4/list_group_contacts_valid_response.json").read) }
    let!(:group) { create(:civicrm_group, civicrm_group_id: 1, organization:) }
    let(:organization) { create(:organization) }

    it "creates group memberships" do
      expect { subject.perform_now(group.id) }.to change(GroupMembership, :count).by(3)
      expect(GroupMembership.pluck(:civicrm_contact_id)).to contain_exactly(17, 18, 23)
    end

    it "preserves group title and description after sync" do
      group.update!(title: "Original Title", description: "Original Description")

      subject.perform_now(group.id)
      group.reload

      expect(group.title).to be_present
      expect(group.title).not_to be_nil
    end

    context "when there are group memberships to delete" do
      let(:contact) { create(:civicrm_contact, organization:, civicrm_contact_id: 10_001) }
      let!(:group_membership) { create(:civicrm_group_membership, group:, contact:, civicrm_contact_id: 10_001) }

      it "deletes group memberships" do
        expect { subject.perform_now(group.id) }.to change(GroupMembership, :count).from(1).to(3)
        expect(GroupMembership.pluck(:civicrm_contact_id)).to contain_exactly(17, 18, 23)
      end

      context "and other group memberships are marked for deletion" do
        let(:other_group) { create(:civicrm_group, civicrm_group_id: 2, organization:) }
        let!(:other_group_membership) { create(:civicrm_group_membership, group: other_group, contact:, civicrm_contact_id: 10_002, marked_for_deletion: true) }

        it "deletes only group memberships not marked for deletion" do
          expect { subject.perform_now(group.id) }.to change(GroupMembership, :count).from(2).to(4)
          expect(GroupMembership.pluck(:civicrm_contact_id)).to contain_exactly(17, 18, 23, 10_002)
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
        expect(GroupMembership.pluck(:civicrm_contact_id)).to contain_exactly(17, 18, 23, 10_002)
      end
    end

    context "with pagination" do
      let(:page_size) { 1 }
      let(:api_returns) do
        [
          { status: 200, body: data1.to_json, headers: {} },
          { status: 200, body: first_page_contacts.to_json, headers: {} },
          { status: 200, body: second_page_contacts.to_json, headers: {} }
        ]
      end

      let(:first_page_contacts) do
        {
          "values" => [data2["values"].first],
          "entity" => "Contact",
          "action" => "get",
          "count" => 3,
          "countFetched" => 1,
          "countMatched" => 3
        }
      end

      let(:second_page_contacts) do
        {
          "values" => [data2["values"][1]],
          "entity" => "Contact",
          "action" => "get",
          "count" => 3,
          "countFetched" => 1,
          "countMatched" => 3
        }
      end

      before do
        allow(Decidim::Civicrm).to receive(:api_records_by_page).and_return(page_size)
        stub_request(:post, /api\.example\.org/)
          .with(body: hash_including("params" => hash_including("offset" => 0)))
          .to_return(status: 200, body: first_page_contacts.to_json, headers: {})
        stub_request(:post, /api\.example\.org/)
          .with(body: hash_including("params" => hash_including("offset" => 1)))
          .to_return(status: 200, body: second_page_contacts.to_json, headers: {})
      end

      it "processes first page and schedules next page" do
        expect { subject.perform_now(group.id, page: 0) }.to change(GroupMembership, :count).by(1)
        expect(GroupMembership.pluck(:civicrm_contact_id)).to contain_exactly(17)
        expect(subject).to have_been_enqueued.with(group.id, page: 1).on_queue("default")
      end
    end

    context "with custom_fields" do
      let(:custom_fields_data) { JSON.parse(file_fixture("v4/list_contact_custom_fields_valid_response.json").read) }
      let(:api_returns) do
        [
          { status: 200, body: data1.to_json, headers: {} },
          { status: 200, body: data2.to_json, headers: {} },
          { status: 200, body: custom_fields_data.to_json, headers: {} },
          { status: 200, body: custom_fields_data.to_json, headers: {} },
          { status: 200, body: custom_fields_data.to_json, headers: {} }
        ]
      end

      it "fetches and stores custom_fields for each membership" do
        subject.perform_now(group.id)
        memberships = GroupMembership.all
        expect(memberships.count).to eq(3)
        memberships.each do |membership|
          expect(membership.custom_fields).not_to be_empty
          expect(membership.custom_fields["Dades_comunes.Identificador_fiscal"]).to eq("12345678X")
        end
      end

      context "when custom_fields API fails for one contact" do
        let(:api_returns) do
          [
            { status: 200, body: data1.to_json, headers: {} },
            { status: 200, body: data2.to_json, headers: {} },
            { status: 200, body: custom_fields_data.to_json, headers: {} },
            { status: 500, body: { error: "Server error" }.to_json, headers: {} },
            { status: 200, body: custom_fields_data.to_json, headers: {} }
          ]
        end

        it "continues processing other contacts" do
          subject.perform_now(group.id)
          memberships = GroupMembership.all.order(:civicrm_contact_id)
          expect(memberships.count).to eq(3)
          expect(memberships[0].custom_fields).not_to be_empty
          expect(memberships[1].custom_fields).to eq({}) # Failed to fetch
          expect(memberships[2].custom_fields).not_to be_empty
        end
      end
    end
  end
end
