# frozen_string_literal: true

require "spec_helper"

module Decidim::Civicrm
  module Admin
    describe MeetingRegistrationsController do
      routes { Decidim::Civicrm::AdminEngine.routes }

      let(:organization) { meeting.organization }
      let(:user) { create(:user, :admin, :confirmed, organization:) }

      let(:params) do
        {
          event_meeting: {
            decidim_meeting_id:,
            redirect_url: url,
            redirect_active: active
          }
        }.with_indifferent_access
      end

      let(:meeting) { create(:meeting) }
      let(:decidim_meeting_id) { meeting.id }
      let(:url) { ::Faker::Internet.url }
      let(:active) { true }

      before do
        request.env["decidim.current_organization"] = organization
        sign_in user, scope: :user
      end

      context "when creating a event meeting" do
        it "creates redirects back" do
          post(:create, params:)

          expect(response).to redirect_to("/admin/civicrm#{meeting_registrations_path}")
        end

        it "creates a new event meeting" do
          expect { post(:create, params:) }.to change(EventMeeting, :count).by(1)
        end

        context "and meeting does not exist" do
          let(:decidim_meeting_id) { nil }

          it "do not create a new event meeting" do
            expect { post(:create, params:) }.not_to change(EventMeeting, :count)
          end
        end
      end

      context "when destroying a event meeting" do
        let!(:event_meeting) { create(:civicrm_event_meeting, organization:, meeting:, civicrm_event_id:) }
        let(:civicrm_event_id) { nil }

        it "destroys the event" do
          expect { delete :destroy, params: { id: event_meeting.id } }.to change(EventMeeting, :count).by(-1)
        end

        context "when not removable" do
          let(:civicrm_event_id) { 123 }

          it "do not destroy the event" do
            expect { delete :destroy, params: { id: event_meeting.id } }.not_to change(EventMeeting, :count)

            expect(EventMeeting.count).to eq(1)
          end
        end
      end

      context "when toggle redirect_active to active" do
        let!(:event_meeting) { create(:civicrm_event_meeting, organization:, meeting:, redirect_active: active) }
        let(:active) { false }

        it "toggles" do
          put :toggle_active, params: { id: event_meeting.id }

          expect(event_meeting.reload.redirect_active).to be(true)

          put :toggle_active, params: { id: event_meeting.id }

          expect(event_meeting.reload.redirect_active).to be(false)
        end
      end
    end
  end
end
