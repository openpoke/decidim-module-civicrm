# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  module Admin
    describe GroupsController do
      routes { Decidim::Civicrm::AdminEngine.routes }

      let(:organization) { create(:organization) }
      let(:user) { create(:user, :admin, :confirmed, organization:) }
      let!(:group1) { create(:civicrm_group, organization:, civicrm_group_id: 1, auto_sync_members: true) }
      let!(:group2) { create(:civicrm_group, organization:, civicrm_group_id: 2, auto_sync_members: true) }
      let!(:group3) { create(:civicrm_group, organization:, civicrm_group_id: 3, auto_sync_members: false) }
      let!(:contact1) { create(:civicrm_contact, civicrm_contact_id: 10, organization:) }
      let!(:contact2) { create(:civicrm_contact, civicrm_contact_id: 11, organization:) }
      let!(:contact3) { create(:civicrm_contact, civicrm_contact_id: 12, organization:) }
      let!(:group_memberships) do
        [
          create(:civicrm_group_membership, contact: nil, group: group1, extra: { display_name: "AAAA" }),
          create(:civicrm_group_membership, contact: contact1, group: group1, extra: { display_name: "ZZZZ" }),
          create(:civicrm_group_membership, contact: contact2, group: group1, extra: { display_name: "AAAA" }),
          create(:civicrm_group_membership, contact: contact3, group: group1, extra: { display_name: "AAAA" })
        ]
      end

      before do
        request.env["decidim.current_organization"] = organization
        sign_in user, scope: :user
      end

      context "when index" do
        it "renders the index template" do
          get :index

          expect(response).to render_template("decidim/civicrm/admin/groups/index")
        end

        it "returns list of groups in json format" do
          get :index, format: :json

          expect(response).not_to render_template("decidim/civicrm/admin/groups/index")
          parsed = response.parsed_body
          expect(parsed).to include({ "id" => group1.civicrm_group_id, "text" => group1.title })
          expect(parsed).to include({ "id" => group2.civicrm_group_id, "text" => group2.title })
          expect(parsed).not_to include({ "id" => group3.civicrm_group_id, "text" => group3.title })
        end
      end

      context "when show" do
        it "renders the show template" do
          get :show, params: { id: group1.id }

          expect(response).to render_template("decidim/civicrm/admin/groups/show")
        end

        it "members are ordered by creation date and name" do
          get :show, params: { id: group1.id }

          members = controller.helpers.members
          expect(members.first).to eq(group_memberships.last)
          expect(members.last).to eq(group_memberships.first)
          expect(members.third).to eq(group_memberships.second)
        end
      end
    end
  end
end
