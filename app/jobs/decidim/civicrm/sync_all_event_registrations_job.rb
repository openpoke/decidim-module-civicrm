# frozen_string_literal: true

module Decidim
  module Civicrm
    class SyncAllEventRegistrationsJob < ApplicationJob
      queue_as :default

      def perform(organization)
        EventMeeting.where(organization:).find_each do |event_meeting|
          SyncEventRegistrationsJob.perform_now(event_meeting.id)
          sleep(Decidim::Civicrm.api_rate_limit_delay)
        end
      end
    end
  end
end
