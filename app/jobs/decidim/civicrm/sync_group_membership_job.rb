# frozen_string_literal: true

module Decidim
  module Civicrm
    # Job to sync a single group membership record from CiviCRM
    class SyncGroupMembershipJob < ApplicationJob
      queue_as :default

      def perform(contact_id, group_id: nil, member_data: nil)
        group = group_id ? Group.find(group_id) : nil

        Rails.logger.info "SyncGroupMembershipJob: Syncing contact #{contact_id}#{group ? " in group #{group.civicrm_group_id}" : ""}"

        # Find or create the membership
        membership = if group
                       GroupMembership.find_or_create_by(civicrm_contact_id: contact_id, group: group)
                     else
                       GroupMembership.find_by(civicrm_contact_id: contact_id)
                     end

        unless membership
          Rails.logger.warn "SyncGroupMembershipJob: Membership not found for contact #{contact_id}"
          return
        end

        # Update membership with latest data if provided
        membership.extra = member_data if member_data.present?

        # Sync contact reference
        membership.contact = Contact.find_by(civicrm_contact_id: contact_id, organization: membership.group.organization)
        membership.marked_for_deletion = nil

        # Fetch and store custom fields for this contact
        begin
          custom_fields_result = Decidim::Civicrm::Api::List.new("contact_custom_fields", contact_id).result
          membership.custom_fields = custom_fields_result.first || {}
        rescue Decidim::Civicrm::Error => e
          Rails.logger.error "SyncGroupMembershipJob: Failed to fetch custom fields for contact #{contact_id}: #{e.message}"
        end

        membership.save!

        Rails.logger.info "SyncGroupMembershipJob: Successfully synced membership #{membership.id} for contact #{contact_id}#{group ? " in group #{group.civicrm_group_id}" : ""}"
      end
    end
  end
end
