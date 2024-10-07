# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  module Admin
    describe InfoController do
      routes { Decidim::Civicrm::AdminEngine.routes }

      let(:organization) { create(:organization) }
      let(:user) { create(:user, :admin, :confirmed, organization:) }

      before do
        request.env["decidim.current_organization"] = organization
        sign_in user, scope: :user
      end

      context "when index" do
        it "renders the index template" do
          get :index

          expect(response).to render_template("decidim/civicrm/admin/info/index")
        end
      end
    end
  end
end
