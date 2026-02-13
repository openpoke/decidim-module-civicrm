# frozen_string_literal: true

module Decidim
  module Civicrm
    class SyncGroupMembersJob < ApplicationJob
      queue_as :default

      def perform(group_id, page: 0, sync_id: nil, skip_duplicate_sync: false)
        sync_id ||= Time.current # Generate a sync ID if not provided
        @skip_duplicate_sync = skip_duplicate_sync

        group = Decidim::Civicrm::Group.find(group_id)

        Rails.logger.info "SyncGroupMembersJob: Process group #{group.title} (civicrm_group_id: #{group.civicrm_group_id}) - Page #{page}"

        if page.zero?
          data = Decidim::Civicrm::Api::Find.new("group", group.civicrm_group_id).result

          if data.blank?
            Rails.logger.error "SyncGroupMembersJob: No API Data found for group! (civicrm_group_id: #{group.civicrm_group_id})"
            return
          end

          update_group(group, data[:group])
          GroupMembership.prepare_cleanup({ group_id: group_id }, sync_id: sync_id) if page.zero?
        end

        update_group_memberships(group, page:, sync_id:)
      end

      def update_group(group, data)
        Rails.logger.info "SyncGroupMembersJob: Creating / updating Group #{group.title} (civicrm_group_id: #{group.civicrm_group_id}) with data #{data}"

        group.update!(
          title: data[:title],
          description: data[:description],
          extra: data,
          marked_for_deletion: nil
        )
      end

      def update_group_memberships(group, page: 0, sync_id: nil)
        Rails.logger.info "SyncGroupMembersJob: Updating group memberships for Group #{group.title} (civicrm_group_id: #{group.civicrm_group_id}) - Page #{page}"

        api_list = Decidim::Civicrm::Api::List.new("group_contacts", group.civicrm_group_id, fetch_all: false, page: page)
        api_group_contacts = api_list.result
        total_count = api_list.count

        Rails.logger.warning "SyncGroupMembersJob: No API memberships found for group! (civicrm_group_id: #{group.civicrm_group_id})" if api_group_contacts.blank?

        group.update!(civicrm_member_count: total_count) if page.zero?

        api_group_contacts.each do |member|
          # We prefer to sync now instead of scheduling separate jobs to ensure we hit the API rate limits as efficiently as possible
          # and to avoid creating a large number of jobs when syncing groups with many members
          SyncGroupMembershipJob.perform_now(member[:contact_id], group_id: group.id, member_data: member)
          sleep(Decidim::Civicrm.api_rate_limit_delay)
        end

        # Check if there are more pages
        page_size = Decidim::Civicrm.api_records_by_page
        next_page_offset = (page + 1) * page_size
        has_more_pages = if total_count.nil?
                           api_group_contacts.length == page_size # If we got a full page, there might be more
                         else
                           next_page_offset < total_count
                         end

        if has_more_pages
          Rails.logger.info "SyncGroupMembersJob: Scheduling page #{page + 1} in #{Decidim::Civicrm.api_rate_limit_delay} seconds"
          SyncGroupMembersJob.set(wait: Decidim::Civicrm.api_rate_limit_delay).perform_later(group.id, page: page + 1, sync_id: sync_id, skip_duplicate_sync: @skip_duplicate_sync)
        else
          Rails.logger.info "SyncGroupMembersJob: #{GroupMembership.where(group_id: group.id, marked_for_deletion: sync_id).count} group memberships to delete"

          GroupMembership.clean_up_records({ group_id: group.id }, sync_id: sync_id)

          ActiveSupport::Notifications.publish("decidim.civicrm.group_membership.updated", group.id)

          # Sync duplicate memberships only if not called from SyncAllGroupsJob
          unless @skip_duplicate_sync
            Rails.logger.info "SyncGroupMembersJob: Scheduling duplicate memberships sync"
            SyncDuplicateGroupMembershipsJob.perform_later
          end
        end
      end
    end
  end
end
