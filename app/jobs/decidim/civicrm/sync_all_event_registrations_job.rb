# frozen_string_literal: true

module Decidim
  module Civicrm
    class SyncAllEventRegistrationsJob < ApplicationJob
      queue_as :default

      def perform(organization)
        EventMeeting.where(organization:).find_each do |event_meeting|
          SyncEventRegistrationsJob.perform_later(event_meeting.id)
        end
      end
    end
  end
end
