# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  module Admin
    describe MembershipTypesController do
      routes { Decidim::Civicrm::AdminEngine.routes }

      let(:organization) { create(:organization) }
      let(:user) { create(:user, :admin, :confirmed, organization:) }
      let!(:membership_type1) { create(:civicrm_membership_type, organization:) }
      let!(:membership_type2) { create(:civicrm_membership_type, organization:) }
      let!(:membership_type3) { create(:civicrm_membership_type) }

      before do
        request.env["decidim.current_organization"] = organization
        sign_in user, scope: :user
      end

      context "when index" do
        it "renders the index template" do
          get :index

          expect(response).to render_template("decidim/civicrm/admin/membership_types/index")
        end

        it "returns list of membership_types in json format" do
          get :index, format: :json

          expect(response).not_to render_template("decidim/civicrm/admin/membership_types/index")
          parsed = response.parsed_body
          expect(parsed).to include({ "id" => membership_type1.civicrm_membership_type_id, "text" => membership_type1.name })
          expect(parsed).to include({ "id" => membership_type2.civicrm_membership_type_id, "text" => membership_type2.name })
          expect(parsed).not_to include({ "id" => membership_type3.civicrm_membership_type_id, "text" => membership_type3.name })
        end
      end
    end
  end
end
