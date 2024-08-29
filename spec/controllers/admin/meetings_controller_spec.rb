# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  module Admin
    describe MeetingsController do
      routes { Decidim::Civicrm::AdminEngine.routes }

      let(:organization) { create(:organization) }
      let(:user) { create(:user, :admin, :confirmed, organization:) }
      let!(:event1) { create(:civicrm_event_meeting, :minimal, organization:) }
      let!(:event2) { create(:civicrm_event_meeting, :minimal, organization:) }
      let!(:event3) { create(:civicrm_event_meeting, :minimal) }

      before do
        request.env["decidim.current_organization"] = organization
        sign_in user, scope: :user
      end

      describe "GET index" do
        it "renders the index template" do
          get :index

          expect(response).to render_template("decidim/civicrm/admin/meetings/index")
        end

        it "returns list of meetings in json format" do
          get :index, format: :json

          expect(response).not_to render_template("decidim/civicrm/admin/meetings/index")
          parsed = response.parsed_body
          expect(parsed.pluck("civicrm_event_id")).to include event1.civicrm_event_id
          expect(parsed.pluck("civicrm_event_id")).to include event2.civicrm_event_id
          expect(parsed.pluck("civicrm_event_id")).not_to include event3.civicrm_event_id
        end
      end
    end
  end
end
