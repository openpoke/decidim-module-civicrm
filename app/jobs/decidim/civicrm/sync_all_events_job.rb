# frozen_string_literal: true

module Decidim
  module Civicrm
    class SyncAllEventsJob < ApplicationJob
      queue_as :default

      def perform(organization_id)
        EventMeeting.prepare_cleanup(decidim_organization_id: organization_id)

        api_events = Decidim::Civicrm::Api::ListEvents.new.result

        Rails.logger.info "SyncAllEventsJob: #{api_events.count} events to process"

        api_events.each { |data| update_event(organization_id, data) }

        Rails.logger.info "SyncAllEventsJob: #{EventMeeting.to_delete.count} events to delete"

        EventMeeting.clean_up_records(decidim_organization_id: organization_id)
      end

      def update_event(organization_id, data)
        civicrm_event_id = data[:id]

        return if civicrm_event_id.blank?

        Rails.logger.info "SyncAllEventsJob: Creating / updating EventMeeting #{data[:title]} (civicrm id: #{civicrm_event_id}) with data #{data}"

        event = EventMeeting.find_or_initialize_by(decidim_organization_id: organization_id, civicrm_event_id:)

        event.extra = data
        event.marked_for_deletion = false
        event.save!

        Rails.logger.info "SyncAllEventsJob: Created EventMeeting ID #{event.id}"
      end
    end
  end
end
