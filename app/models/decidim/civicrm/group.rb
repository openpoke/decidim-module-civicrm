# frozen_string_literal: true

module Decidim
  module Civicrm
    class Group < ApplicationRecord
      include MarkableForDeletion
      include Decidim::TranslatableAttributes
      include Decidim::FilterableResource

      belongs_to :organization, class_name: "Decidim::Organization", foreign_key: "decidim_organization_id"

      has_many :group_memberships, class_name: "Decidim::Civicrm::GroupMembership", dependent: :destroy
      has_many :members, class_name: "Decidim::Civicrm::Contact", source: :contact, through: :group_memberships
      has_many :group_participatory_spaces, dependent: :destroy

      validates :civicrm_group_id, uniqueness: { scope: :organization }

      def last_sync
        @last_sync ||= group_memberships.select(:updated_at).order(updated_at: :desc).last&.updated_at
      end

      # returns a formatted list of all participatory spaces linked to this groups for automatic sync
      def participatory_spaces
        group_participatory_spaces.to_h do |item|
          i18n_name = I18n.t("decidim.admin.menu.#{item.participatory_space.manifest.name}")
          ["#{item.participatory_space_type}.#{item.participatory_space_id}", "#{i18n_name}: #{translated_attribute(item.participatory_space.title)}"]
        end
      end

      def self.ransackable_attributes(_auth_object = nil)
        %w(title description)
      end
    end
  end
end
