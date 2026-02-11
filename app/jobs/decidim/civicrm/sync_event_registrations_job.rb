# frozen_string_literal: true

module Decidim
  module Civicrm
    class SyncEventRegistrationsJob < ApplicationJob
      queue_as :default

      def perform(event_meeting_id, page: 0)
        EventRegistration.prepare_cleanup(event_meeting_id:) if page.zero?

        event_meeting = Decidim::Civicrm::EventMeeting.find(event_meeting_id)

        Rails.logger.info "SyncEventRegistrationsJob: Process event_meeting #{event_meeting.id} (civicrm id: #{event_meeting.civicrm_event_id}) - Page #{page}"

        if page.zero?
          data = Decidim::Civicrm::Api::Find.new("event", event_meeting.civicrm_event_id).result

          update_event_meeting(event_meeting, data)
        end

        update_event_meeting_registrations(event_meeting, page:)
      end

      def update_event_meeting(event_meeting, data)
        Rails.logger.info "SyncEventRegistrationsJob: Creating / updating EventMeeting #{event_meeting.id} (civicrm id: #{event_meeting.civicrm_event_id}) with data #{data}"

        event_meeting.update!(
          extra: data,
          marked_for_deletion: false
        )
      end

      def update_event_meeting_registrations(event_meeting, page: 0)
        Rails.logger.info "SyncEventRegistrationsJob: Updating EventMeeting #{event_meeting.id} (civicrm id: #{event_meeting.civicrm_event_id}) - Page #{page}"

        api_list = Decidim::Civicrm::Api::List.new("event_participants", event_meeting.civicrm_event_id, fetch_all: false, page: page)
        api_registrations_in_event_meeting = api_list.result
        total_count = api_list.count

        event_meeting.update!(civicrm_registrations_count: total_count) if page.zero?

        api_registrations_in_event_meeting.each do |participant|
          update_event_meeting_registration(event_meeting, participant)
        end

        # Check if there are more pages
        next_page_offset = (page + 1) * Decidim::Civicrm.api_records_by_page
        if next_page_offset < total_count
          Rails.logger.info "SyncEventRegistrationsJob: Scheduling page #{page + 1} in #{Decidim::Civicrm.api_rate_limit_delay} seconds"
          SyncEventRegistrationsJob.set(wait: Decidim::Civicrm.api_rate_limit_delay).perform_later(event_meeting.id, page: page + 1)
        else
          Rails.logger.info "SyncEventRegistrationsJob: #{EventRegistration.where(event_meeting_id: event_meeting.id).to_delete.count} event_meeting registrations to delete"

          EventRegistration.clean_up_records(event_meeting_id: event_meeting.id)

          remove_non_participants_meeting_registrations(event_meeting)

          ActiveSupport::Notifications.publish("decidim.civicrm.event_meeting_registration.updated", event_meeting.id)
        end
      end

      def update_event_meeting_registration(event_meeting, data)
        return unless event_meeting && data && data[:participant]

        participant_id = data[:participant][:id]

        Rails.logger.info "SyncEventRegistrationsJob: Creating / updating registration for Contact #{participant_id} for civicrm_event_id: #{event_meeting.civicrm_event_id}"
        contact = Decidim::Civicrm::Contact.find_by(civicrm_contact_id: data.dig(:contact, :id), organization: event_meeting.organization)
        # return unless contact && contact&.user

        event_registration = EventRegistration.find_or_initialize_by(civicrm_event_registration_id: participant_id)
        event_registration.meeting_registration = Decidim::Meetings::Registration.find_or_initialize_by(user: contact&.user, meeting: event_meeting.meeting)
        event_registration.event_meeting = event_meeting
        event_registration.extra = data
        event_registration.marked_for_deletion = false

        event_registration.save!
      end

      # remove registrations and follows for users corresponding to contacts that are not participants in the CiViCRM event
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
