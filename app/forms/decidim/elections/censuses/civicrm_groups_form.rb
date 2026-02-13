# frozen_string_literal: true

require "digest"

module Decidim
  module Elections
    module Censuses
      # Voter form for CiViCRM Groups Census verification.
      class CivicrmGroupsForm < Decidim::Form
        include CivicrmGroupsFormMethods

        mimic :census_data

        attribute :verification_data, Hash, default: -> { {} }

        validate :verification_data_present
        validate :contact_in_census

        def verification_data
          super&.with_indifferent_access || {}
        end

        def voter_uid
          return nil unless @civicrm_contact

          Digest::SHA512.hexdigest(
            "civicrm-#{@civicrm_contact[:id]}-#{election.id}-#{Rails.application.secret_key_base}"
          )
        end

        private

        def contact_in_census
          return if errors.any?

          fields = build_search_fields
          if fields.blank?
            errors.add(:base, I18n.t("decidim.civicrm.censuses.civicrm_groups.no_data"))
            return
          end

          # Try local DB search first (no API call needed)
          membership = find_member_locally(fields)
          if membership
            @civicrm_contact = { id: membership.civicrm_contact_id, display_name: membership.name }
            return
          end

          # Fallback to CiviCRM API when local data is missing or not yet synced
          contact = find_contact_by_fields(fields)
          unless contact
            errors.add(:base, I18n.t("decidim.civicrm.censuses.civicrm_groups.invalid"))
            return
          end

          unless contact_in_group?(contact[:id])
            errors.add(:base, I18n.t("decidim.civicrm.censuses.civicrm_groups.not_in_group"))
            return
          end

          @civicrm_contact = contact
        end

        def find_member_locally(fields)
          group = find_census_group
          return nil unless group

          results = Decidim::Civicrm::FindGroupMemberByCustomFields
                    .new(group: group, fields: fields)
                    .query

          # Return match only when exactly one result found;
          # multiple matches mean we can't reliably identify the contact
          results.size == 1 ? results.first : nil
        end

        def find_contact_by_fields(fields)
          Decidim::Civicrm::Api::V4::FindContactByFields.new(fields).result
        rescue StandardError => e
          Rails.logger.error("CiviCRM census search error: #{e.message}")
          nil
        end

        def find_census_group
          return nil unless civicrm_group_id

          @find_census_group ||= Decidim::Civicrm::Group.find_by(
            civicrm_group_id: civicrm_group_id,
            organization: election&.organization
          )
        end

        def contact_in_group?(contact_id)
          group = find_census_group
          return false unless group

          group.group_memberships.exists?(civicrm_contact_id: contact_id)
        end

        def build_search_fields
          fields = {}

          verification_fields.each do |field_name|
            value = verification_data&.dig(field_name)
            fields[field_name] = value if value.present?
          end

          fields
        end

        def verification_data_present
          verification_fields.each do |field_name|
            value = verification_data&.dig(field_name)
            next if value.present?

            errors.add(:base, I18n.t("decidim.civicrm.censuses.civicrm_groups.field_required",
                                     field: humanize_field_name(field_name)))
          end
        end
      end
    end
  end
end
