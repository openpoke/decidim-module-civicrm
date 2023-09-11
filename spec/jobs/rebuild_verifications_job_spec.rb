# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim::Civicrm
  describe RebuildVerificationsJob do
    subject { described_class }

    include_context "with stubs example api"

    let(:data) { JSON.parse(file_fixture("find_user_valid_response.json").read) }
    let(:user) { create :user, organization: organization }
    let!(:identity) { create :identity, user: user, provider: Decidim::Civicrm::OMNIAUTH_PROVIDER_NAME, uid: uid }
    let(:organization) { create :organization }
    let!(:group) { create :civicrm_group, organization: organization }
    let!(:membership_type1) { create :civicrm_membership_type, organization: user.organization, civicrm_membership_type_id: 1 }
    let!(:membership_type2) { create :civicrm_membership_type, organization: user.organization, civicrm_membership_type_id: 2 }
    let!(:membership_type3) { create :civicrm_membership_type, organization: user.organization, civicrm_membership_type_id: 3 }
    let!(:contact) { create :civicrm_contact, user: user, organization: organization, civicrm_contact_id: contact_id, membership_types: [2, 3] }
    let!(:membership) { create :civicrm_group_membership, group: group, contact: contact, civicrm_contact_id: contact_id }
    let(:uid) { data["id"] }
    let(:contact_id) { "9999" }

    shared_examples "destroys and rebuilds verification" do
      it "creates the verification" do
        expect(Decidim::Verifications::AuthorizeUser).to receive(:call).with(an_instance_of(klass), organization).and_call_original

        subject.perform_now(workflow_name, organization.id)

        expect(Decidim::Authorization.find_by(user: user, name: workflow_name)).to be_present
      end

      it "rebuids the verification" do
        create :authorization, name: workflow_name, user: user, created_at: 1.day.ago
        expect(Decidim::Authorization.where(user: user, name: workflow_name).count).to eq(1)
        expect { subject.perform_now(workflow_name, organization.id) }.to(change { Decidim::Authorization.find_by(user: user, name: workflow_name).created_at })
        expect(Decidim::Authorization.where(user: user, name: workflow_name).count).to eq(1)
      end

      context "when other authorizations exist" do
        let!(:dummy_authorization_handler) { create :authorization, user: user, name: "dummy_authorization_handler" }

        it "does not destroy the other authorization" do
          expect(Decidim::Authorization.where(user: user, name: workflow_name).count).to eq(0)
          expect { subject.perform_now(workflow_name, organization.id) }.not_to(change { Decidim::Authorization.where(user: user, name: "dummy_authorization_handler").count })
          expect(Decidim::Authorization.where(user: user, name: workflow_name).count).to eq(1)
        end
      end

      context "when authorizations from other organizations exist" do
        let!(:other_user) { create :user }
        let!(:other_authorization) { create :authorization, user: other_user, name: workflow_name }

        it "does not destroy the other authorization" do
          expect(Decidim::Authorization.where(name: workflow_name).count).to eq(1)
          expect { subject.perform_now(workflow_name, organization.id) }.not_to(change { Decidim::Authorization.find_by(user: other_user, name: workflow_name).created_at })
          expect(Decidim::Authorization.where(name: workflow_name).count).to eq(2)
        end
      end
    end

    it_behaves_like "destroys and rebuilds verification" do
      let(:klass) { Decidim::Civicrm::Verifications::Civicrm }
      let(:workflow_name) { :civicrm }
    end

    it_behaves_like "destroys and rebuilds verification" do
      let(:klass) { Decidim::Civicrm::Verifications::CivicrmGroups }
      let(:workflow_name) { :civicrm_groups }
    end

    it_behaves_like "destroys and rebuilds verification" do
      let(:klass) { Decidim::Civicrm::Verifications::CivicrmMembershipTypes }
      let(:workflow_name) { :civicrm_membership_types }

      it "has metadata" do
        subject.perform_now(workflow_name, organization.id)
        expect(Decidim::Authorization.find_by(user: user, name: workflow_name).metadata).to eq({ "contact_id" => 9999, "membership_types_ids" => [2, 3], "uid" => 42 })
      end
    end

    context "when contact has been updated" do
      let(:workflow_name) { :civicrm_membership_types }
      let(:contact_data) do
        { contact: { id: 42, display_name: "Lady Trillian" }, memberships: [1] }
      end

      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Decidim::Civicrm::Api::FindContact).to receive(:result).and_return(contact_data)
        # rubocop:enable RSpec/AnyInstance
      end

      it "creates the verification with the new data" do
        subject.perform_now(workflow_name, organization.id)
        expect(Decidim::Authorization.where(user: user, name: workflow_name).count).to eq(1)
        expect(Decidim::Authorization.find_by(user: user, name: workflow_name).metadata).to eq({ "contact_id" => 9999, "membership_types_ids" => [1], "uid" => 42 })
      end
    end

    context "when the workflow_name is not a civicrm authorization" do
      let(:workflow_name) { :dummy_authorization_handler }

      it "does not create the verification" do
        expect(Decidim::Verifications::AuthorizeUser).not_to receive(:call)

        subject.perform_now(workflow_name, organization.id)

        expect(Decidim::Authorization.find_by(user: user, name: workflow_name)).not_to be_present
      end
    end
  end
end
