# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  describe JoinContactToParticipatorySpacesJob do
    subject { described_class }

    let(:user) { create(:user, organization:) }
    let!(:identity) { create(:identity, user:, provider: Decidim::Civicrm::OMNIAUTH_PROVIDER_NAME) }
    let(:organization) { create(:organization) }
    let(:participatory_space) { create(:participatory_process, organization:) }
    let!(:civicrm_group_participatory_space) { create(:civicrm_group_participatory_space, group:, participatory_space:) }
    let!(:group) { create(:civicrm_group, organization:) }
    let!(:contact) { create(:civicrm_contact, user:, organization:) }
    let!(:civicrm_group_membership) { create(:civicrm_group_membership, contact:, group:) }

    it "creates a private user for the participatory space" do
      expect { subject.perform_now(contact.id) }.to change(Decidim::ParticipatorySpacePrivateUser, :count).from(0).to(1)
    end

    context "when no contact" do
      let(:another_user) { create(:user, organization:) }
      let(:contact) { create(:civicrm_contact, organization:) }

      it "does nothing" do
        expect { subject.perform_now(contact.id) }.not_to(change(Decidim::ParticipatorySpacePrivateUser, :count))
      end
    end

    context "when no groups" do
      let(:civicrm_group_membership) { nil }

      it "does nothing" do
        expect { subject.perform_now(contact.id) }.not_to(change(Decidim::ParticipatorySpacePrivateUser, :count))
      end
    end

    context "when group has no participatory spaces" do
      let(:civicrm_group_participatory_space) { nil }

      it "does nothing" do
        expect { subject.perform_now(contact.id) }.not_to(change(Decidim::ParticipatorySpacePrivateUser, :count))
      end
    end

    context "when participatory space has no private users" do
      let(:participatory_space) { double(id: 1) }
      let(:civicrm_group_participatory_space) { nil }

      it "does nothing" do
        expect { subject.perform_now(contact.id) }.not_to(change(Decidim::ParticipatorySpacePrivateUser, :count))
      end
    end
  end
end
