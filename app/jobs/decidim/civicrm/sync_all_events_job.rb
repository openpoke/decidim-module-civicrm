# frozen_string_literal: true

module Decidim
  module Civicrm
    class SyncAllEventsJob < ApplicationJob
      queue_as :default

      def perform(organization_id, page: 0, sync_id: nil)
        sync_id ||= Time.current # Generate a sync ID if not provided

        EventMeeting.prepare_cleanup({ decidim_organization_id: organization_id }, sync_id: sync_id) if page.zero?

        api_list = Decidim::Civicrm::Api::List.new("events", fetch_all: false, page: page)
        api_events = api_list.result
        total_count = api_list.count

        Rails.logger.info "SyncAllEventsJob: Page #{page}: #{api_events.count} events to process (#{total_count} total)"

        api_events.each { |data| update_event(organization_id, data[:event]) }

        # Check if there are more pages
        page_size = Decidim::Civicrm.api_records_by_page
        next_page_offset = (page + 1) * page_size
        has_more_pages = if total_count.nil?
                           api_events.length == page_size # If we got a full page, there might be more
                         else
                           next_page_offset < total_count
                         end

        if has_more_pages
          Rails.logger.info "SyncAllEventsJob: Scheduling page #{page + 1} in #{Decidim::Civicrm.api_rate_limit_delay} seconds"
          SyncAllEventsJob.set(wait: Decidim::Civicrm.api_rate_limit_delay).perform_later(organization_id, page: page + 1, sync_id:)
        else
          Rails.logger.info "SyncAllEventsJob: #{EventMeeting.where(marked_for_deletion: sync_id).count} events to delete"

          EventMeeting.clean_up_records({ decidim_organization_id: organization_id }, sync_id: sync_id)
        end
      end

      def update_event(organization_id, data)
        civicrm_event_id = data[:id]

        return if civicrm_event_id.blank?

        Rails.logger.info "SyncAllEventsJob: Creating / updating EventMeeting #{data[:title]} (civicrm id: #{civicrm_event_id}) with data #{data}"

        event = EventMeeting.find_or_initialize_by(decidim_organization_id: organization_id, civicrm_event_id:)

        event.extra = data
        event.marked_for_deletion = nil
        event.save!

        Rails.logger.info "SyncAllEventsJob: Created EventMeeting ID #{event.id}"
      end
    end
  end
end
