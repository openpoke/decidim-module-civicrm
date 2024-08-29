# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  describe ParticipatorySpaceGroupMembershipJob do
    subject { described_class }

    let(:organization) { create(:organization) }
    let(:user) { create(:user, organization:) }
    let(:process) { create(:participatory_process, organization:) }
    let(:assembly) { create(:assembly, organization:) }
    let!(:process_group_space) { create(:civicrm_group_participatory_space, group:, participatory_space: process) }
    let!(:assembly_group_space) { create(:civicrm_group_participatory_space, group:, participatory_space: assembly) }
    let(:group) { create(:civicrm_group, organization:) }
    let(:contact) { create(:civicrm_contact, organization:, user:) }
    let!(:group_membership) { create(:civicrm_group_membership, group:, contact:) }

    it "creates a private user for the participatory space" do
      perform_enqueued_jobs do
        expect { subject.perform_now(group.id) }.to change(Decidim::ParticipatorySpacePrivateUser, :count).by(2)
        expect(Decidim::ParticipatorySpacePrivateUser.pluck(:decidim_user_id)).to eq([user.id, user.id])
      end
    end

    context "when private users already exist" do
      let(:other_user) { create(:user, organization:) }
      let!(:private_user) { create(:participatory_space_private_user, privatable_to: process, user: other_user) }

      it "remove existing users and create news" do
        perform_enqueued_jobs do
          expect(Decidim::ParticipatorySpacePrivateUser.pluck(:decidim_user_id)).to eq([other_user.id])
          expect { subject.perform_now(group.id) }.to change(Decidim::ParticipatorySpacePrivateUser, :count).by(1)
          expect(Decidim::ParticipatorySpacePrivateUser.pluck(:decidim_user_id)).to eq([user.id, user.id])
        end
      end
    end
  end
end
