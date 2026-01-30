# frozen_string_literal: true

module Decidim
  module Civicrm
    # This query filters authorized users for an organization based on
    # configured CiviCRM groups and membership types.
    class AuthorizedUsers < Decidim::Query
      def initialize(organization:, handler_options: {})
        @organization = organization
        @valid_types = organization.available_authorizations
        @handler_options = handler_options&.filter { |type, _handler| @valid_types.include?(type) }
        @civicrm_groups = @handler_options.dig("civicrm_groups", "options", "groups")&.split(",") || []
        @civicrm_membership_types = @handler_options.dig("civicrm_membership_types", "options", "membership_types")&.split(",") || []
        @users = Decidim::AuthorizedUsers.new(
          organization: organization,
          handlers: handler_options&.keys,
          strict: true
        ).query
      end

      attr_reader :organization, :users, :civicrm_groups, :civicrm_membership_types

      def query
        filter_groups
        filter_membership_types
      end

      private

      def filter_groups
        return users if civicrm_groups.blank?

        groups = Decidim::Civicrm::Group.where(civicrm_group_id: civicrm_groups, organization:)

        @users = users.joins(:contact).where(decidim_civicrm_contacts: { id: Decidim::Civicrm::GroupMembership.where(group_id: groups.select(:id)).select(:contact_id) })
      end

      def filter_membership_types
        return users if civicrm_membership_types.blank?

        @users = users.joins(:contact).where(
          "decidim_civicrm_contacts.membership_types @> ANY (ARRAY[?]::jsonb[])",
          civicrm_membership_types
        )
      end
    end
  end
end
