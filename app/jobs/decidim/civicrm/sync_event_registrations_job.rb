# frozen_string_literal: true

module Decidim
  module Civicrm
    class SyncEventRegistrationsJob < ApplicationJob
      queue_as :default

      def perform(event_meeting_id)
        EventRegistration.prepare_cleanup(event_meeting_id:)

        event_meeting = Decidim::Civicrm::EventMeeting.find(event_meeting_id)

        data = Decidim::Civicrm::Api::FindEvent.new(event_meeting.civicrm_event_id).result

        Rails.logger.info "SyncEventRegistrationsJob: Process event_meeting #{event_meeting.id} (civicrm id: #{event_meeting.civicrm_event_id})"

        update_event_meeting(event_meeting, data)

        Rails.logger.info "SyncEventRegistrationsJob: #{EventRegistration.where(event_meeting_id:).to_delete.count} event_meeting registrations to delete"

        EventRegistration.clean_up_records(event_meeting_id:)

        remove_non_participants_meeting_registrations(event_meeting)

        ActiveSupport::Notifications.publish("decidim.civicrm.event_meeting_registration.updated", event_meeting.id)
      end

      def update_event_meeting(event_meeting, data)
        Rails.logger.info "SyncEventRegistrationsJob: Creating / updating EventMeeting #{event_meeting.id} (civicrm id: #{event_meeting.civicrm_event_id}) with data #{data}"

        event_meeting.update!(
          extra: data,
          marked_for_deletion: false
        )

        update_event_meeting_registrations(event_meeting)
      end

      def update_event_meeting_registrations(event_meeting)
        Rails.logger.info "SyncEventRegistrationsJob: Updating event_meeting registrations for EventMeeting #{event_meeting.id} (civicrm id: #{event_meeting.civicrm_event_id})"

        api_registrations_in_event_meeting = Decidim::Civicrm::Api::ParticipantsInEvent.new(event_meeting.civicrm_event_id).result

        event_meeting.update!(civicrm_registrations_count: api_registrations_in_event_meeting.count)

        api_registrations_in_event_meeting.each do |participant|
          update_event_meeting_registration(event_meeting, participant)
        end
      end

      def update_event_meeting_registration(event_meeting, participant)
        return unless event_meeting && participant

        Rails.logger.info "SyncEventRegistrationsJob: Creating / updating registration for Contact #{participant[:id]} for civicrm_event_id: #{event_meeting.civicrm_event_id}"
        contact = Decidim::Civicrm::Contact.find_by(civicrm_contact_id: participant[:contact_id], organization: event_meeting.organization)
        # return unless contact && contact&.user

        event_registration = EventRegistration.find_or_initialize_by(civicrm_event_registration_id: participant[:id])
        event_registration.meeting_registration = Decidim::Meetings::Registration.find_or_initialize_by(user: contact&.user, meeting: event_meeting.meeting)
        event_registration.event_meeting = event_meeting
        event_registration.extra = participant
        event_registration.marked_for_deletion = false

        event_registration.save!
      end

      # remove registrations and follows for users corresponding to contacts that are not participants in the CiVICRM event
      def remove_non_participants_meeting_registrations(event_meeting)
        registrations = Decidim::Meetings::Registration.where(meeting: event_meeting.meeting)
        registrations.each do |registration|
          contact = registration.user.contact
          next unless contact

          next if EventRegistration.exists?(meeting_registration: registration)

          Rails.logger.info "SyncEventRegistrationsJob: Destroying registration for Meeting #{event_meeting.meeting.id} (Contact #{contact.id})"
          registration.destroy!

          follow = Decidim::Follow.find_by(followable: event_meeting.meeting, user: registration.user)
          next unless follow

          Rails.logger.info "SyncEventRegistrationsJob: Destroying follow for Meeting #{event_meeting.meeting.id} (Contact #{contact.id})"
          follow.destroy!
        end
      end
    end
  end
end
