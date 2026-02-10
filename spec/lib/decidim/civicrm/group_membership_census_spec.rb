# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe Civicrm::GroupMembership do
    let!(:organization) { create(:organization) }
    let!(:participatory_process) { create(:participatory_process, organization:) }
    let!(:elections_component) { create(:elections_component, participatory_space: participatory_process) }
    let!(:group) { create(:civicrm_group, organization:, civicrm_group_id: 100) }

    let(:census_settings) do
      {
        "civicrm_group_id" => group.civicrm_group_id,
        "verification_fields" => ["user_id"]
      }
    end

    let!(:election) do
      create(:election, component: elections_component, census_manifest: "civicrm_groups", census_settings:)
    end

    let(:manifest) { Decidim::Elections.census_registry.find(:civicrm_groups) }

    describe "#users" do
      context "when group has members with and without Decidim accounts" do
        let!(:contact) { create(:civicrm_contact, organization:) }
        let!(:membership_with_account) { create(:civicrm_group_membership, group:, contact:) }
        let!(:membership_without_account) do
          create(:civicrm_group_membership, group:, contact: nil, civicrm_contact_id: 9999,
                                            extra: { "display_name" => "External Person", "email" => "external@example.org" })
        end

        it "includes all group members in the count" do
          result = manifest.users(election, 0, 100)
          expect(result.count).to eq(2)
        end

        it "includes members with Decidim accounts" do
          result = manifest.users(election, 0, 100)
          expect(result).to include(membership_with_account)
        end

        it "includes members without Decidim accounts" do
          result = manifest.users(election, 0, 100)
          expect(result).to include(membership_without_account)
        end

        it "returns GroupMembership records" do
          result = manifest.users(election, 0, 100)
          expect(result.first).to be_a(Decidim::Civicrm::GroupMembership)
        end
      end

      context "when group has only members without Decidim accounts" do
        let!(:membership1) do
          create(:civicrm_group_membership, group:, contact: nil, civicrm_contact_id: 1001,
                                            extra: { "display_name" => "Person A", "email" => "a@example.org" })
        end
        let!(:membership2) do
          create(:civicrm_group_membership, group:, contact: nil, civicrm_contact_id: 1002,
                                            extra: { "display_name" => "Person B", "email" => "b@example.org" })
        end

        it "includes all members" do
          result = manifest.users(election, 0, 100)
          expect(result.count).to eq(2)
        end
      end

      context "when members belong to a different group" do
        let!(:other_group) { create(:civicrm_group, organization:, civicrm_group_id: 200) }
        let!(:membership_in_group) { create(:civicrm_group_membership, group:, contact: nil, civicrm_contact_id: 3001) }
        let!(:membership_in_other_group) { create(:civicrm_group_membership, group: other_group, contact: nil, civicrm_contact_id: 3002) }

        it "only includes members from the configured group" do
          result = manifest.users(election, 0, 100)
          expect(result.count).to eq(1)
          expect(result).to include(membership_in_group)
          expect(result).not_to include(membership_in_other_group)
        end
      end

      context "when no group_id is configured" do
        let(:census_settings) { {} }

        it "returns an empty relation" do
          result = manifest.users(election, 0, 100)
          expect(result).to be_empty
        end
      end

      context "when configured group does not exist locally" do
        let(:census_settings) do
          {
            "civicrm_group_id" => 99_999,
            "verification_fields" => ["user_id"]
          }
        end

        it "returns an empty relation" do
          result = manifest.users(election, 0, 100)
          expect(result).to be_empty
        end
      end
    end

    describe "#count" do
      let!(:contact) { create(:civicrm_contact, organization:) }
      let!(:membership_with_account) { create(:civicrm_group_membership, group:, contact:) }
      let!(:membership_without_account) do
        create(:civicrm_group_membership, group:, contact: nil, civicrm_contact_id: 5001,
                                          extra: { "display_name" => "No Account", "email" => "noaccount@example.org" })
      end

      it "returns the total number of group members including those without Decidim accounts" do
        expect(manifest.count(election)).to eq(2)
      end
    end

    describe "GroupMembership presenter compatibility" do
      let!(:contact) { create(:civicrm_contact, organization:) }
      let!(:membership_with_account) { create(:civicrm_group_membership, group:, contact:) }
      let!(:membership_without_account) do
        create(:civicrm_group_membership, group:, contact: nil, civicrm_contact_id: 7001,
                                          extra: { "display_name" => "External User", "email" => "ext@example.org" })
      end

      it "provides name for members with Decidim accounts" do
        expect(membership_with_account.name).to eq(contact.user.name)
      end

      it "provides name for members without Decidim accounts via extra data" do
        expect(membership_without_account.name).to eq("External User")
      end

      it "provides email for members with Decidim accounts" do
        expect(membership_with_account.email).to eq(contact.user.email)
      end

      it "provides email for members without Decidim accounts via extra data" do
        expect(membership_without_account.email).to eq("ext@example.org")
      end

      it "provides created_at timestamp" do
        expect(membership_without_account.created_at).to be_present
      end
    end
  end
end
