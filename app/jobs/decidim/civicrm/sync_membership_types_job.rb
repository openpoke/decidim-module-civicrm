# frozen_string_literal: true

module Decidim
  module Civicrm
    class SyncMembershipTypesJob < ApplicationJob
      queue_as :default

      def perform(organization_id)
        MembershipType.prepare_cleanup(decidim_organization_id: organization_id)

        api_membership_types = Decidim::Civicrm::Api::ListMembershipTypes.new.result

        Rails.logger.info "SyncMembershipTypesJob: #{api_membership_types.count} membership_types to process"

        api_membership_types.each { |data| update_membership_types(organization_id, data) }

        Rails.logger.info "SyncMembershipTypesJob: #{MembershipType.to_delete.count} membership_types to delete"

        MembershipType.clean_up_records(decidim_organization_id: organization_id)
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
