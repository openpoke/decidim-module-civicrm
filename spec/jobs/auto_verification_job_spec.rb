# frozen_string_literal: true

require "spec_helper"
require "shared/shared_contexts"

module Decidim::Civicrm
  describe AutoVerificationJob do
    subject { described_class }

    include_context "with stubs example api"

    let(:data) { JSON.parse(file_fixture("find_user_valid_response.json").read) }
    let(:user) { create(:user, organization:) }
    let!(:identity) { create(:identity, user:, provider: Decidim::Civicrm::OMNIAUTH_PROVIDER_NAME) }
    let(:organization) { create(:organization) }
    let!(:group) { create(:civicrm_group, organization:) }
    let!(:membership_type) { create(:civicrm_membership_type, organization: user.organization, civicrm_membership_type_id: type_id) }
    let!(:contact) { create(:civicrm_contact, user:, organization:, civicrm_contact_id: contact_id, membership_types: types) }
    let(:types) { [type_id] }
    let(:type_id) { data["values"].first["api.Membership.get"]["values"].first["id"] }
    let!(:membership) { create(:civicrm_group_membership, group:, contact:, civicrm_contact_id: contact_id) }
    let(:contact_id) { data["id"] }

    it "verifies the user" do
      expect { subject.perform_now(contact.id) }.to change { Decidim::Authorization.where(user:).count }.from(0).to(3)
    end

    context "when no contact" do
      let(:another_user) { create(:user, organization:) }
      let(:contact) { create(:civicrm_contact, organization:, civicrm_contact_id: contact_id, membership_types: types) }

      it "does nothing" do
        expect { subject.perform_now(contact.id) }.not_to(change { Decidim::Authorization.where(user:).count })
      end
    end

    context "when already verified" do
      before do
        create(:authorization, user:, name: :civicrm)
        create(:authorization, user:, name: :civicrm_groups)
        create(:authorization, user:, name: :civicrm_membership_types)
      end

      it "destroys and rebuilds the authorizations" do
        expect { subject.perform_now(contact.id) }.to(change { Decidim::Authorization.pluck(:created_at) })
      end

      context "when no contact" do
        it "does nothing" do
          expect { subject.perform_now(0) }.not_to(change(Decidim::Authorization, :count))
        end
      end

      context "when contact user is another organization" do
        before do
          contact.update(user: create(:user))
        end

        it "does nothing" do
          expect { subject.perform_now(contact.id) }.not_to(change(Decidim::Authorization, :count))
        end
      end
    end
  end
end
