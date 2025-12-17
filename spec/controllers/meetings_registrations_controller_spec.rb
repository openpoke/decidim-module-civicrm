# frozen_string_literal: true

require "spec_helper"

module Decidim::Meetings
  describe RegistrationsController do
    let(:organization) { create(:organization) }
    let(:user) { create(:user, :confirmed, organization:) }
    let(:participatory_process) { create(:participatory_process, organization:) }
    let(:component) { create(:meeting_component, participatory_space: participatory_process) }
    let(:meeting) { create(:meeting, :published, component:, registrations_enabled: true) }
    let!(:event_meeting) { create(:civicrm_event_meeting, meeting:, organization:, redirect_active: active) }
    let(:active) { true }
    let(:meeting_path) { Decidim::EngineRouter.main_proxy(component).meeting_path(meeting) }

    before do
      allow(controller).to receive(:meeting_path).and_return(meeting_path)
      request.env["decidim.current_organization"] = organization
      request.env["decidim.current_participatory_space"] = participatory_process
      request.env["decidim.current_component"] = component
      sign_in user
    end

    context "when event meeting exists" do
      it "redirects to external url" do
        post :create, params: { meeting_id: meeting.id }

        expect(response).to redirect_to(event_meeting.redirect_url)
      end
    end

    context "when event meeting does not exist" do
      let(:another_meeting) { create(:meeting, :published, component:) }
      let(:event_meeting) { create(:civicrm_event_meeting, organization:, meeting: another_meeting) }

      it "redirects to meeting" do
        post :create, params: { meeting_id: meeting.id }

        expect(response).to redirect_to(meeting_path)
      end
    end

    context "when event meeting is inactive" do
      let(:active) { false }

      it "redirects to meeting" do
        post :create, params: { meeting_id: meeting.id }

        expect(response).to redirect_to(meeting_path)
      end
    end
  end
end
