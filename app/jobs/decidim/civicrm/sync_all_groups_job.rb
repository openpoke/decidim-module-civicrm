# frozen_string_literal: true

module Decidim
  module Civicrm
    class SyncAllGroupsJob < ApplicationJob
      queue_as :default

      def perform(organization_id, page: 0, sync_id: nil)
        sync_id ||= Time.current # Generate a sync ID if not provided

        Group.prepare_cleanup({ decidim_organization_id: organization_id }, sync_id: sync_id) if page.zero?

        api_list = Decidim::Civicrm::Api::List.new("groups", fetch_all: false, page: page)
        api_groups = api_list.result
        total_count = api_list.count

        Rails.logger.info "SyncAllGroupsJob: Page #{page}: #{api_groups.count} groups to process (#{total_count} total)"

        api_groups.each { |data| update_group(organization_id, data[:group], sync_id) }

        # Check if there are more pages
        page_size = Decidim::Civicrm.api_records_by_page
        next_page_offset = (page + 1) * page_size
        has_more_pages = if total_count.nil?
                           api_groups.length == page_size # If we got a full page, there might be more
                         else
                           next_page_offset < total_count
                         end

        if has_more_pages
          Rails.logger.info "SyncAllGroupsJob: Scheduling page #{page + 1} in #{Decidim::Civicrm.api_rate_limit_delay} seconds"
          SyncAllGroupsJob.set(wait: Decidim::Civicrm.api_rate_limit_delay).perform_later(organization_id, page: page + 1, sync_id:)
        else
          Rails.logger.info "SyncAllGroupsJob: #{Group.where(marked_for_deletion: sync_id).count} groups to delete"
          Rails.logger.info "SyncAllGroupsJob: #{GroupMembership.to_delete.count} group memberships to delete"

          Group.clean_up_records({ decidim_organization_id: organization_id }, sync_id: sync_id)
        end
      end

      def update_group(organization_id, data, _sync_id)
        civicrm_group_id = data[:id]

        return if civicrm_group_id.blank?

        Rails.logger.info "SyncAllGroupsJob: Creating / updating Group #{data[:title]} (civicrm id: #{civicrm_group_id}) with data #{data}"

        group = Group.find_or_initialize_by(decidim_organization_id: organization_id, civicrm_group_id:)

        group.title = data[:title]
        group.description = data[:description]
        group.extra = data
        group.marked_for_deletion = nil

        group.auto_sync_members = group.id ? false : Decidim::Civicrm.default_sync_groups&.include?(civicrm_group_id.to_i).present?

        group.save!

        if group.auto_sync_members
          Rails.logger.info "SyncAllGroupsJob: Auto sync enabled for group #{group.id}, updating members..."
          # Sleep before starting member sync to avoid hitting API rate limits
          sleep(Decidim::Civicrm.api_rate_limit_delay)
          SyncGroupMembersJob.perform_now(group.id)
        else
          Rails.logger.info "SyncAllGroupsJob: Auto sync disabled for group #{group.id}, skipping member sync"
        end
      end
    end
  end
end
