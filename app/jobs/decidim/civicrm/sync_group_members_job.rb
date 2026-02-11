# frozen_string_literal: true

module Decidim
  module Civicrm
    class SyncGroupMembersJob < ApplicationJob
      queue_as :default

      def perform(group_id, page: 0)
        GroupMembership.prepare_cleanup(group_id:) if page.zero?

        group = Decidim::Civicrm::Group.find(group_id)

        Rails.logger.info "SyncGroupMembersJob: Process group #{group.title} (civicrm_group_id: #{group.civicrm_group_id}) - Page #{page}"

        if page.zero?
          data = Decidim::Civicrm::Api::Find.new("group", group.civicrm_group_id).result

          if data.blank?
            Rails.logger.error "SyncGroupMembersJob: No API Data found for group! (civicrm_group_id: #{group.civicrm_group_id})"
            return
          end

          update_group(group, data[:group])
        end

        update_group_memberships(group, page:)
      end

      def update_group(group, data)
        Rails.logger.info "SyncGroupMembersJob: Creating / updating Group #{group.title} (civicrm_group_id: #{group.civicrm_group_id}) with data #{data}"

        group.update!(
          title: data[:title],
          description: data[:description],
          extra: data,
          marked_for_deletion: false
        )
      end

      def update_group_memberships(group, page: 0)
        Rails.logger.info "SyncGroupMembersJob: Updating group memberships for Group #{group.title} (civicrm_group_id: #{group.civicrm_group_id}) - Page #{page}"

        api_list = Decidim::Civicrm::Api::List.new("group_contacts", group.civicrm_group_id, fetch_all: false, page: page)
        api_group_contacts = api_list.result
        total_count = api_list.count

        Rails.logger.warning "SyncGroupMembersJob: No API memberships found for group! (civicrm_group_id: #{group.civicrm_group_id})" if api_group_contacts.blank?

        group.update!(civicrm_member_count: total_count) if page.zero?

        api_group_contacts.each do |member|
          update_group_membership(group, member)
        end

        # Check if there are more pages
        next_page_offset = (page + 1) * Decidim::Civicrm.api_records_by_page
        if next_page_offset < total_count
          Rails.logger.info "SyncGroupMembersJob: Scheduling page #{page + 1} in #{Decidim::Civicrm.api_rate_limit_delay} seconds"
          SyncGroupMembersJob.set(wait: Decidim::Civicrm.api_rate_limit_delay).perform_later(group.id, page: page + 1)
        else
          Rails.logger.info "SyncGroupMembersJob: #{GroupMembership.where(group_id: group.id).to_delete.count} group memberships to delete"

          GroupMembership.clean_up_records(group_id: group.id)

          ActiveSupport::Notifications.publish("decidim.civicrm.group_membership.updated", group.id)
        end
      end

      def update_group_membership(group, member)
        return unless group && member

        Rails.logger.info "SyncGroupMembersJob: Creating / updating membership for Contact #{member[:contact_id]} for Group with civicrm_group_id: #{group.civicrm_group_id}"

        membership = GroupMembership.find_or_create_by(civicrm_contact_id: member[:contact_id], group:)
        membership.contact = Decidim::Civicrm::Contact.find_by(civicrm_contact_id: member[:contact_id], organization: group.organization)
        membership.extra = member
        membership.marked_for_deletion = false

        # Fetch and store custom fields for this contact
        begin
          custom_fields_result = Decidim::Civicrm::Api::List.new("contact_custom_fields", member[:contact_id]).result
          membership.custom_fields = custom_fields_result.first || {}
        rescue StandardError => e
          Rails.logger.error "SyncGroupMembersJob: Failed to fetch custom fields for contact #{member[:contact_id]}: #{e.message}"
          membership.custom_fields = {}
        end

        membership.save!
      end
    end
  end
end
