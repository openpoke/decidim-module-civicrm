# frozen_string_literal: true

module Decidim
  module Civicrm
    class GroupMembership < ApplicationRecord
      include MarkableForDeletion
      include Decidim::FilterableResource

      belongs_to :contact, class_name: "Decidim::Civicrm::Contact", optional: true
      belongs_to :group, class_name: "Decidim::Civicrm::Group"

      validates :contact, uniqueness: { scope: [:group] }, if: -> { contact.present? }
      validates :civicrm_contact_id, uniqueness: { scope: [:group] }
      validate :same_group_contact_organization

      scope :with_custom_fields, lambda {
        where("custom_fields IS NOT NULL AND custom_fields <> '{}' " \
              "AND (SELECT COUNT(*) FILTER (WHERE value <> '') FROM jsonb_each_text(custom_fields)) > 0")
      }
      scope :without_custom_fields, lambda {
        where("custom_fields IS NULL OR custom_fields = '{}' " \
              "OR (SELECT COUNT(*) FILTER (WHERE value <> '') FROM jsonb_each_text(custom_fields)) = 0")
      }
      scope :with_decidim_user, lambda {
        where.not(contact_id: nil)
      }
      scope :without_decidim_user, lambda {
        where(contact_id: nil)
      }
      scope_search_multi :has_custom_fields, [:with_custom_fields, :without_custom_fields]
      scope_search_multi :has_decidim_user, [:with_decidim_user, :without_decidim_user]

      scope :id_or_name_cont, lambda { |term|
        if term.to_s =~ /^\d+$/
          where(civicrm_contact_id: term.to_i)
        else
          where("extra ->> 'display_name' ILIKE ?", "%#{sanitize_sql_like(term)}%")
        end
      }

      delegate :organization, to: :group
      delegate :user, to: :contact

      def synchronized?
        contact.present?
      end

      def custom_fields?
        custom_fields.present? && compact_custom_fields.any?
      end

      def compact_custom_fields
        return {} unless custom_fields.is_a?(Hash)

        @compact_custom_fields ||= custom_fields.compact_blank
      end

      def name
        contact&.user&.name || extra["display_name"] || civicrm_contact_id
      end

      def email
        contact&.user&.email || extra["email"]
      end

      ransacker :name do
        Arel.sql("extra ->> 'display_name'")
      end

      ransacker :nickname do
        Arel.sql(<<~SQL.squish)
          (
            SELECT decidim_users.nickname
            FROM decidim_civicrm_contacts
            INNER JOIN decidim_users ON decidim_users.id = decidim_civicrm_contacts.decidim_user_id
            WHERE decidim_civicrm_contacts.id = decidim_civicrm_group_memberships.contact_id
          )
        SQL
      end

      ransacker :with_custom_fields do
        Arel.sql(<<~SQL.squish)
          CASE
            WHEN custom_fields IS NOT NULL
              AND custom_fields <> '{}'
              AND (SELECT COUNT(*) FILTER (WHERE value <> '') FROM jsonb_each_text(custom_fields)) > 0
              THEN 1
            ELSE 0
          END
        SQL
      end

      def self.ransackable_scopes(_auth_object = nil)
        [:id_or_name_cont, :has_custom_fields, :has_decidim_user]
      end

      def self.ransackable_attributes(_auth_object = nil)
        %w(civicrm_contact_id custom_fields name nickname with_custom_fields created_at)
      end

      def self.ransackable_associations(_auth_object = nil)
        []
      end

      private

      def same_group_contact_organization
        return if contact.blank?

        errors.add(:contact, :invalid) unless contact.organization == group.organization
      end
    end
  end
end
