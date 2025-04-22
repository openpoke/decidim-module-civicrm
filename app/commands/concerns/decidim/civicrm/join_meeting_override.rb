# frozen_string_literal: true

module Decidim
  module Civicrm
    # A command with all the business logic to create a user from omniauth
    module JoinMeetingOverride
      extend ActiveSupport::Concern

      included do
        def send_email_confirmation
          return unless Decidim::Civicrm.send_meeting_registration_notifications

          Decidim::Meetings::RegistrationMailer.confirmation(current_user, meeting, registration).deliver_later
        end
      end
    end
  end
end
