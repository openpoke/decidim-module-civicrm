# frozen_string_literal: true

module Decidim
  module Civicrm
    # Job to sync a single event registration record from CiviCRM
    class SyncEventRegistrationJob < ApplicationJob
      queue_as :default

      def perform(participant_id, event_meeting_id: nil, participant_data: nil)
        event_meeting = event_meeting_id ? EventMeeting.find_by(id: event_meeting_id) : nil

        unless event_meeting
          Rails.logger.warn "SyncEventRegistrationJob: EventMeeting not found with id #{event_meeting_id}"
          return
        end

        Rails.logger.info "SyncEventRegistrationJob: Syncing participant #{participant_id} for event #{event_meeting.civicrm_event_id}"

        update_event_meeting_registration(event_meeting, participant_data) if participant_data.present?
      end

      private

      def update_event_meeting_registration(event_meeting, data)
        return unless event_meeting && data && data[:participant]

        participant_id = data[:participant][:id]

        Rails.logger.info "SyncEventRegistrationJob: Creating / updating registration for Contact #{participant_id} for civicrm_event_id: #{event_meeting.civicrm_event_id}"
        contact = Decidim::Civicrm::Contact.find_by(civicrm_contact_id: data.dig(:contact, :id), organization: event_meeting.organization)

        event_registration = EventRegistration.find_or_initialize_by(civicrm_event_registration_id: participant_id)
        event_registration.meeting_registration = Decidim::Meetings::Registration.find_or_initialize_by(user: contact&.user, meeting: event_meeting.meeting)
        event_registration.event_meeting = event_meeting
        event_registration.extra = data
        event_registration.marked_for_deletion = nil

        event_registration.save!

        Rails.logger.info "SyncEventRegistrationJob: Successfully synced registration #{event_registration.id} for participant #{participant_id}"
      end
    end
  end
end
