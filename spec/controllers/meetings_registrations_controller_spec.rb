# frozen_string_literal: true

require "spec_helper"

module Decidim::Meetings
  describe RegistrationsController do
    routes { Decidim::Meetings::Engine.routes }

    let!(:meeting) { create(:meeting, :with_registrations_enabled) }
    let!(:event_meeting) { create(:civicrm_event_meeting, meeting:, organization:, redirect_active: active) }
    let!(:user) { create(:user, :confirmed, organization:) }
    let(:organization) { meeting.organization }
    let(:component) { meeting.component }
    let(:active) { true }

    let(:params) do
      {
        meeting_id: meeting.id,
        component_id: component.id
      }
    end

    before do
      request.env["decidim.current_organization"] = organization
      request.env["decidim.current_participatory_space"] = component.participatory_space
      request.env["decidim.current_component"] = component
      sign_in user, scope: :user
    end

    context "when event meeting exists" do
      it "redirects to external url" do
        post(:create, params:)

        expect(response).to redirect_to(event_meeting.redirect_url)
      end
    end

    context "when event meeting does not exists" do
      let(:event_meeting) { create(:civicrm_event_meeting, organization:, meeting: another_meeting) }
      let(:another_meeting) { create(:meeting, component:) }

      it "redirects redirects to meeting" do
        post(:create, params:)

        expect(response).to redirect_to(space_path.meeting_path(meeting))
      end
    end

    context "when event meeting is inactive" do
      let(:active) { false }

      it "redirects redirects to meeting" do
        post(:create, params:)

        expect(response).to redirect_to(space_path.meeting_path(meeting))
      end
    end

    def space_path
      Decidim::EngineRouter.main_proxy(component)
    end
  end
end
