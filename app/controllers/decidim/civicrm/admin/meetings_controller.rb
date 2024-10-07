# frozen_string_literal: true

module Decidim
  module Civicrm
    module Admin
      class MeetingsController < Decidim::Admin::ApplicationController
        include Paginable
        include NeedsPermission
        include TranslatableAttributes

        layout "decidim/admin/civicrm"
        add_breadcrumb_item_from_menu :admin_civicrm_menu

        helper CivicrmHelpers
        helper Decidim::Messaging::ConversationHelper

        helper_method :event_meetings, :event_meeting, :meetings, :meetings_list, :meeting_title, :public_meeting_path

        def index
          # enforce_permission_to :index, :civicrm_meetings
          respond_to do |format|
            format.html
            format.json do
              render json: event_meetings
            end
          end
        end

        def show
          # enforce_permission_to :show, :civicrm_meetings
        end

        def new
          @form = form(Decidim::Civicrm::Admin::EventMeetingForm).instance
        end

        def sync
          # enforce_permission_to :update, :civicrm_meetings

          if event_meeting.present?
            SyncEventsJob.perform_later(event_meeting.id)
            flash[:notice] = t("success", scope: "decidim.civicrm.admin.meetings.sync")
            redirect_to decidim_civicrm_admin.meeting_path(event_meeting)
          else
            SyncAllEventsJob.perform_later(current_organization.id)
            flash[:notice] = t("success", scope: "decidim.civicrm.admin.meetings.sync")
            redirect_to decidim_civicrm_admin.meetings_path
          end

          # TODO: send email when complete?
        end

        def toggle_active
          # enforce_permission_to :update, :civicrm_meetings

          return if event_meeting.blank?

          event_meeting.redirect_active = !event_meeting.redirect_active
          event_meeting.save!
          redirect_to decidim_civicrm_admin.meetings_path
        end

        private

        def all_event_meetings
          Decidim::Civicrm::EventMeeting.where(organization: current_organization)
        end

        def event_meetings
          paginate(all_event_meetings)
        end

        def event_meeting
          return if params[:id].blank?

          @event_meeting ||= all_event_meetings.find(params[:id])
        end

        def per_page
          50
        end

        def public_meeting_path(meeting)
          Decidim::EngineRouter.main_proxy(meeting.component).meeting_path(meeting)
        end
      end
    end
  end
end
