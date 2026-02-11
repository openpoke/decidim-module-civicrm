# frozen_string_literal: true

module Decidim
  module Civicrm
    class SyncMembershipTypesJob < ApplicationJob
      queue_as :default

      def perform(organization_id, page: 0)
        MembershipType.prepare_cleanup(decidim_organization_id: organization_id) if page.zero?

        api_list = Decidim::Civicrm::Api::List.new("membership_types", fetch_all: false, page: page)
        api_membership_types = api_list.result
        total_count = api_list.count

        Rails.logger.info "SyncMembershipTypesJob: Page #{page}: #{api_membership_types.count} membership_types to process (#{total_count} total)"

        api_membership_types.each { |data| update_membership_types(organization_id, data) }

        # Check if there are more pages
        next_page_offset = (page + 1) * Decidim::Civicrm.api_records_by_page
        if next_page_offset < total_count
          Rails.logger.info "SyncMembershipTypesJob: Scheduling page #{page + 1} in #{Decidim::Civicrm.api_rate_limit_delay} seconds"
          SyncMembershipTypesJob.set(wait: Decidim::Civicrm.api_rate_limit_delay).perform_later(organization_id, page: page + 1)
        else
          Rails.logger.info "SyncMembershipTypesJob: #{MembershipType.to_delete.count} membership_types to delete"

          MembershipType.clean_up_records(decidim_organization_id: organization_id)
        end
      end

      def update_membership_types(organization_id, data)
        civicrm_membership_type_id = data[:id]
        return if civicrm_membership_type_id.blank?

        Rails.logger.info "SyncMembershipTypesJob: Creating / updating MembershipType #{data[:name]} \
        (civicrm id: #{civicrm_membership_type_id}) with data #{data}"

        membership_type = MembershipType.find_or_initialize_by(decidim_organization_id: organization_id, civicrm_membership_type_id:)

        membership_type.name = data[:name]
        membership_type.marked_for_deletion = false

        membership_type.save!
      end
    end
  end
end
