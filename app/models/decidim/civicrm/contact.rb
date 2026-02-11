# frozen_string_literal: true

module Decidim
  module Civicrm
    class Contact < ApplicationRecord
      include MarkableForDeletion

      belongs_to :organization, class_name: "Decidim::Organization", foreign_key: "decidim_organization_id"
      belongs_to :user, class_name: "Decidim::User", foreign_key: "decidim_user_id"

      has_many :group_memberships, class_name: "Decidim::Civicrm::GroupMembership", dependent: :destroy
      has_many :groups, class_name: "Decidim::Civicrm::Group", through: :group_memberships

      validates :user, uniqueness: true
      validates :civicrm_contact_id, uniqueness: { scope: :organization }

      def possible_memberships
        GroupMembership.joins(:group).where({
                                              civicrm_contact_id:,
                                              decidim_civicrm_groups: { decidim_organization_id: }
                                            })
      end

      def memberships
        @memberships ||= MembershipType.where(civicrm_membership_type_id: membership_types)
      end

      # re-fetch info from the api
      def rebuild!
        result = Decidim::Civicrm::Api::Find.new("contact", civicrm_contact_id).result
        return if result.blank?

        self.membership_types = result[:memberships]
        self.extra = result[:contact]

        # Fetch custom fields
        begin
          custom_fields_result = Decidim::Civicrm::Api::List.new("contact_custom_fields", civicrm_contact_id).result
          self.custom_fields = custom_fields_result.first || {}
        rescue Decidim::Civicrm::Error => e
          Rails.logger.error("Failed to fetch custom fields for contact #{civicrm_contact_id}: #{e.message}")
          self.custom_fields = {}
        end

        save!
      end
    end
  end
end
