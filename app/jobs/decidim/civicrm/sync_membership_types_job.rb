# frozen_string_literal: true

module Decidim
  module Civicrm
    class SyncMembershipTypesJob < ApplicationJob
      queue_as :default

      def perform(organization_id, page: 0, sync_id: nil)
        sync_id ||= Time.current # Generate a sync ID if not provided

        MembershipType.prepare_cleanup({ decidim_organization_id: organization_id }, sync_id: sync_id) if page.zero?

        api_list = Decidim::Civicrm::Api::List.new("membership_types", fetch_all: false, page: page)
        api_membership_types = api_list.result
        total_count = api_list.count

        Rails.logger.info "SyncMembershipTypesJob: Page #{page}: #{api_membership_types.count} membership_types to process (#{total_count} total)"

        api_membership_types.each { |data| update_membership_types(organization_id, data) }

        # Check if there are more pages
        page_size = Decidim::Civicrm.api_records_by_page
        next_page_offset = (page + 1) * page_size
        has_more_pages = if total_count.nil?
                           api_membership_types.length == page_size # If we got a full page, there might be more
                         else
                           next_page_offset < total_count
                         end

        if has_more_pages
          Rails.logger.info "SyncMembershipTypesJob: Scheduling page #{page + 1} in #{Decidim::Civicrm.api_rate_limit_delay} seconds"
          SyncMembershipTypesJob.set(wait: Decidim::Civicrm.api_rate_limit_delay).perform_later(organization_id, page: page + 1, sync_id:)
        else
          Rails.logger.info "SyncMembershipTypesJob: #{MembershipType.where(marked_for_deletion: sync_id).count} membership_types to delete"

          MembershipType.clean_up_records({ decidim_organization_id: organization_id }, sync_id: sync_id)
        end
      end

      def update_membership_types(organization_id, data)
        civicrm_membership_type_id = data[:id]
        return if civicrm_membership_type_id.blank?

        Rails.logger.info "SyncMembershipTypesJob: Creating / updating MembershipType #{data[:name]} \
        (civicrm id: #{civicrm_membership_type_id}) with data #{data}"

        membership_type = MembershipType.find_or_initialize_by(decidim_organization_id: organization_id, civicrm_membership_type_id:)

        membership_type.name = data[:name]
        membership_type.marked_for_deletion = nil

        membership_type.save!
      end
    end
  end
end
