# frozen_string_literal: true

module Decidim
  module Civicrm
    # Job to synchronize data between group memberships that share the same civicrm_contact_id
    # Keeps data from the most recently updated record
    class SyncDuplicateGroupMembershipsJob < ApplicationJob
      queue_as :default

      def perform
        Rails.logger.info "SyncDuplicateGroupMembershipsJob: Starting synchronization"

        # Find all civicrm_contact_ids that have multiple group memberships within the same organization
        duplicate_contacts = GroupMembership
                             .joins(:group)
                             .group(:civicrm_contact_id, "decidim_civicrm_groups.decidim_organization_id")
                             .having("COUNT(*) > 1")
                             .pluck(:civicrm_contact_id, "decidim_civicrm_groups.decidim_organization_id")

        Rails.logger.info "SyncDuplicateGroupMembershipsJob: Found #{duplicate_contacts.count} contacts with duplicate memberships"

        duplicate_contacts.each do |civicrm_contact_id, organization_id|
          sync_contact_memberships(civicrm_contact_id, organization_id)
        end

        Rails.logger.info "SyncDuplicateGroupMembershipsJob: Synchronization completed"
      end

      private

      def sync_contact_memberships(civicrm_contact_id, organization_id)
        memberships = GroupMembership
                      .joins(:group)
                      .where(civicrm_contact_id: civicrm_contact_id, decidim_civicrm_groups: { decidim_organization_id: organization_id })
                      .order(updated_at: :desc, id: :desc)

        return if memberships.count <= 1

        # The most recently updated membership is the source of truth
        source_membership = memberships.first

        Rails.logger.info "SyncDuplicateGroupMembershipsJob: Syncing #{memberships.count} memberships for contact #{civicrm_contact_id}"

        # Update all other memberships to match the source
        memberships.offset(1).each do |membership|
          sync_membership_data(membership, source_membership)
        end
      end

      def sync_membership_data(target, source)
        # Update fields from the source membership
        target.extra = source.extra if source.extra.present?
        target.custom_fields = source.custom_fields if source.custom_fields.present?

        if target.changed?
          target.save!
          Rails.logger.info "SyncDuplicateGroupMembershipsJob: Updated membership #{target.id} (group: #{target.group_id}) from membership #{source.id}"
        else
          Rails.logger.debug { "SyncDuplicateGroupMembershipsJob: No changes needed for membership #{target.id}" }
        end
      end
    end
  end
end
