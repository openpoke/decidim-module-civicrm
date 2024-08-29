# frozen_string_literal: true

module Decidim
  module Civicrm
    module Admin
      class MeetingRegistrationsController < Decidim::Admin::ApplicationController
        include Paginable
        include NeedsPermission
        include TranslatableAttributes

        layout "decidim/admin/civicrm"
        add_breadcrumb_item_from_menu :admin_civicrm_menu

        helper CivicrmHelpers
        helper Decidim::Messaging::ConversationHelper

        helper_method :event_meetings, :event_meeting, :meetings, :meetings_list, :meeting_title, :registrations, :public_meeting_path

        def index
          # enforce_permission_to :index, :civicrm_meetings
        end

        def show
          # enforce_permission_to :show, :civicrm_meetings
        end

        def new
          @form = form(Decidim::Civicrm::Admin::EventMeetingForm).instance
        end

        def edit
          @form = form(Decidim::Civicrm::Admin::EventMeetingForm).from_model(event_meeting)
        end

        def create
          @form = form(Decidim::Civicrm::Admin::EventMeetingForm).from_params(params)
          CreateEventMeeting.call(@form) do
            on(:ok) do
              flash[:notice] = t(".success")

              redirect_to decidim_civicrm_admin.meeting_registrations_path
            end

            on(:invalid) do
              flash[:alert] = t(".error")
              render action: "new"
            end
          end
        end

        def update
          @form = form(Decidim::Civicrm::Admin::EventMeetingForm).from_params(params)
          CreateEventMeeting.call(@form, event_meeting) do
            on(:ok) do
              flash[:notice] = t(".success")

              redirect_to decidim_civicrm_admin.meeting_registrations_path
            end

            on(:invalid) do
              flash[:alert] = t(".error")
              render action: "edit"
            end
          end
        end

        def destroy
          if event_meeting.civicrm_event_id.present?
            flash[:alert] = t(".error")
          else
            event_meeting.destroy!
          end
          redirect_to decidim_civicrm_admin.meeting_registrations_path
        end

        def sync
          # enforce_permission_to :update, :civicrm_meetings

          if event_meeting.present?
            SyncEventRegistrationsJob.perform_later(event_meeting.id)
            flash[:notice] = t("success", scope: "decidim.civicrm.admin.meetings.sync")
            redirect_to decidim_civicrm_admin.meeting_registration_path(event_meeting)
          else
            SyncAllEventRegistrationsJob.perform_later(current_organization.id)
            flash[:notice] = t("success", scope: "decidim.civicrm.admin.meetings.sync")
            redirect_to decidim_civicrm_admin.meeting_registrations_path
          end

          # TODO: send email when complete?
        end

        def toggle_active
          # enforce_permission_to :update, :civicrm_meetings

          return if event_meeting.blank?

          event_meeting.redirect_active = !event_meeting.redirect_active
          event_meeting.save!
          redirect_to decidim_civicrm_admin.meeting_registrations_path
        end

        private

        def all_event_meetings
          Decidim::Civicrm::EventMeeting.where(organization: current_organization).where.not(decidim_meeting_id: nil)
        end

        def event_meetings
          paginate(all_event_meetings)
        end

        def event_meeting
          return if params[:id].blank?

          @event_meeting ||= all_event_meetings.find(params[:id])
        end

        def meetings
          return @meetings if @meetings

          classes = Decidim.participatory_space_manifests.pluck :model_class_name
          components = []
          classes.each do |klass|
            spaces = klass.safe_constantize.where(organization: current_organization)
            spaces.each do |space|
              components.concat Decidim::Component.where(participatory_space: space).pluck(:id)
            end
          end
          @meetings = Decidim::Meetings::Meeting.where(decidim_component_id: components)
        end

        def meeting_title(meeting)
          "#{meeting.id}: #{translated_attribute(meeting.participatory_space.title)} / #{translated_attribute(meeting.component.name)} / #{translated_attribute(meeting.title)}"
        end

        def meetings_list
          @meetings_list ||= meetings.map do |meeting|
            [meeting_title(meeting), meeting.id]
          end
        end

        def registrations
          paginate(event_meeting.event_registrations.order("extra ->>'display_name' ASC", "extra ->>'register_date' ASC"))
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
