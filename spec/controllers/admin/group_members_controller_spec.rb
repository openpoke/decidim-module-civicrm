# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  module Admin
    describe GroupMembersController do
      routes { Decidim::Civicrm::AdminEngine.routes }

      let(:organization) { create(:organization) }
      let(:user) { create(:user, :admin, :confirmed, organization:) }
      let!(:group1) { create(:civicrm_group, organization:, civicrm_group_id: 1, auto_sync_members: true) }
      let!(:contact1) { create(:civicrm_contact, civicrm_contact_id: 10, organization:) }
      let!(:contact2) { create(:civicrm_contact, civicrm_contact_id: 11, organization:) }
      let!(:contact3) { create(:civicrm_contact, civicrm_contact_id: 12, organization:) }
      let!(:group_memberships) do
        [
          create(:civicrm_group_membership, contact: nil, group: group1, civicrm_contact_id: 888, extra: { display_name: "AAAA" }),
          create(:civicrm_group_membership, contact: contact1, group: group1, civicrm_contact_id: contact1.civicrm_contact_id, extra: { display_name: "ZZZZ" }),
          create(:civicrm_group_membership, contact: contact2, group: group1, civicrm_contact_id: contact2.civicrm_contact_id, extra: { display_name: "AAAA" }),
          create(:civicrm_group_membership, contact: contact3, group: group1, civicrm_contact_id: contact3.civicrm_contact_id, extra: { display_name: "AAAA" })
        ]
      end

      before do
        request.env["decidim.current_organization"] = organization
        sign_in user, scope: :user
      end

      context "when index" do
        it "renders the group members index template" do
          get :index, params: { group_id: group1.id }

          expect(response).to render_template("decidim/civicrm/admin/group_members/index")
        end

        it "members are ordered by query result" do
          get :index, params: { group_id: group1.id }

          members = controller.helpers.members
          # Default ordering should follow filterable query
          expect(members).to include(group_memberships.first)
          expect(members).to include(group_memberships.last)
        end

        context "when filtering by custom fields" do
          let!(:membership_with_fields) { create(:civicrm_group_membership, group: group1, contact: nil, civicrm_contact_id: 999, custom_fields: { "field" => "value" }) }

          it "filters memberships with custom fields" do
            get :index, params: { group_id: group1.id, q: { has_custom_fields: "with_custom_fields" } }

            members = controller.helpers.members
            expect(members).to include(membership_with_fields)
          end
        end

        context "when searching by id or name" do
          it "finds by contact id" do
            get :index, params: { group_id: group1.id, q: { id_or_name_cont: contact1.civicrm_contact_id.to_s } }

            members = controller.helpers.members
            expect(members.to_a).to include(group_memberships[1])
          end

          it "finds by display name" do
            get :index, params: { group_id: group1.id, q: { id_or_name_cont: "ZZZZ" } }

            members = controller.helpers.members
            expect(members.to_a).to include(group_memberships[1])
          end
        end
      end
    end
  end
end
