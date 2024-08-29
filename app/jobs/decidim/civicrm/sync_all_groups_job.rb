# frozen_string_literal: true

module Decidim
  module Civicrm
    class SyncAllGroupsJob < ApplicationJob
      queue_as :default

      def perform(organization_id)
        Group.prepare_cleanup(decidim_organization_id: organization_id)

        api_groups = Decidim::Civicrm::Api::ListGroups.new.result

        Rails.logger.info "SyncAllGroupsJob: #{api_groups.count} groups to process"

        api_groups.each { |data| update_group(organization_id, data) }

        Rails.logger.info "SyncAllGroupsJob: #{Group.to_delete.count} groups to delete"
        Rails.logger.info "SyncAllGroupsJob: #{GroupMembership.to_delete.count} group memberships to delete"

        Group.clean_up_records(decidim_organization_id: organization_id)
      end

      def update_group(organization_id, data)
        civicrm_group_id = data[:id]

        return if civicrm_group_id.blank?

        Rails.logger.info "SyncAllGroupsJob: Creating / updating Group #{data[:title]} (civicrm id: #{civicrm_group_id}) with data #{data}"

        group = Group.find_or_initialize_by(decidim_organization_id: organization_id, civicrm_group_id:)

        group.title = data[:title]
        group.description = data[:description]
        group.extra = data
        group.marked_for_deletion = false

        group.auto_sync_members = Decidim::Civicrm.default_sync_groups&.include?(civicrm_group_id.to_i) unless group.id

        group.save!

        if group.auto_sync_members
          Rails.logger.info "SyncAllGroupsJob: Auto sync enabled for group #{group.id}, updating members..."
          SyncGroupMembersJob.perform_later(group.id)
        else
          Rails.logger.info "SyncAllGroupsJob: Auto sync disabled for group #{group.id}, skipping member sync"
        end
      end
    end
  end
end
