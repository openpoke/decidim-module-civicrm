# frozen_string_literal: true

module Decidim
  module Civicrm
    class MembershipType < ApplicationRecord
      include MarkableForDeletion

      belongs_to :organization, class_name: "Decidim::Organization", foreign_key: "decidim_organization_id"

      validates :civicrm_membership_type_id, uniqueness: { scope: :organization }

      def last_sync
        updated_at
      end

      def needs_sync?
        false # Membership types are static data, no sync needed after initial fetch
      end
    end
  end
end
