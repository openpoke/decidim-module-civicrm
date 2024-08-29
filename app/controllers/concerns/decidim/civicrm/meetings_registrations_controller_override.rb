# frozen_string_literal: true

module Decidim
  module Civicrm
    # A command with all the business logic to create a user from omniauth
    module MeetingsRegistrationsControllerOverride
      extend ActiveSupport::Concern

      included do
        private

        def registered_in_decidim?
          Decidim::Meetings::Registration.find_by(meeting:, user: current_user)
        end

        def civicrm_event_meeting
          Decidim::Civicrm::EventMeeting.find_by(meeting:, redirect_active: true)&.redirect_url
        end

        def after_answer_path
          url = civicrm_event_meeting
          return url if url && registered_in_decidim?

          Decidim::EngineRouter.main_proxy(meeting.component).meeting_path(meeting)
        end

        def redirect_after_path
          redirect_to after_answer_path
        end
      end
    end
  end
end
